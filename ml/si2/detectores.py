"""Entrena un detector de anomalias con sesiones sanas de carOBD y guarda sus puntajes.

Uso: python detectores.py <pca|iforest|ocsvm|ae_denso|ae_conv|ae_lstm32|ae_lstm64> [hilos]
"""
import os
import sys
import time

import numpy as np

import comun as C

NOMBRE = sys.argv[1] if len(sys.argv) > 1 else ''
HILOS = int(sys.argv[2]) if len(sys.argv) > 2 else 2
os.environ['OMP_NUM_THREADS'] = str(HILOS)
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
MAX_EPOCAS = int(os.environ.get('VERA_EPOCAS', 40))


def preparar():
    """Particion por sesion, escalado y ventanas (sanas y con falla)."""
    from sklearn.preprocessing import StandardScaler
    ses, modo = C.load_carobd()
    tr, va, te = C.split_sesiones(modo)
    sc = StandardScaler().fit(np.concatenate([ses[n] for n in tr]))
    esc = lambda x: ((x - sc.mean_) / sc.scale_).astype(np.float32)
    d = dict(ses=ses, modo=modo, tr=tr, va=va, te=te, media=sc.mean_, escala=sc.scale_)
    for k, nombres in (('tr', tr), ('va', va), ('te', te)):
        wins, sid = [], []
        for i, n in enumerate(nombres):
            w, _ = C.ventanas(esc(ses[n]))
            wins.append(w)
            sid.append(np.full(len(w), i))
        d['X_' + k] = np.concatenate(wins)
        d['sid_' + k] = np.concatenate(sid)
    # series con falla: solo se guardan las ventanas que tocan el intervalo de la falla
    for k, nombres, semilla in (('va', va, 7), ('te', te, 11)):
        series = C.series_con_falla(ses, nombres, semilla)
        wins, meta = [], []
        for j, s in enumerate(series):
            T = len(s['x'])
            ends = np.arange(C.W, T + 1, C.STEP)
            solape = np.minimum(ends, s['fin']) - np.maximum(ends - C.W, s['ini'])
            idx = np.where(solape > 0)[0]
            xs = esc(s['x'])
            wins.append(np.stack([xs[e - C.W:e] for e in ends[idx]]))
            for i in idx:
                meta.append((j, nombres.index(s['sesion']), i, solape[i], list(C.ESCENARIOS).index(s['esc']),
                             C.SEVERIDADES.index(s['sev'])))
        d['F_' + k] = np.concatenate(wins)
        d['meta_' + k] = np.array(meta)  # serie, sesion, indice de ventana, solape, escenario, severidad
    return d


def resumen(X):
    return np.concatenate([X.mean(1), X.std(1), X.min(1), X.max(1)], axis=1)


def construir(nombre):
    import tensorflow as tf
    from tensorflow.keras import layers as L, Sequential
    tf.config.threading.set_intra_op_parallelism_threads(HILOS)
    tf.config.threading.set_inter_op_parallelism_threads(1)
    tf.keras.utils.set_random_seed(C.SEED)
    F = len(C.PIDS)
    if nombre == 'ae_denso':
        m = Sequential([L.Input((F,)), L.Dense(16, activation='relu'), L.Dense(8, activation='relu'),
                        L.Dense(4, activation='relu'), L.Dense(8, activation='relu'), L.Dense(16, activation='relu'),
                        L.Dense(F)])
    elif nombre == 'ae_conv':
        m = Sequential([L.Input((C.W, F)),
                        L.Conv1D(32, 5, padding='same', activation='relu'), L.MaxPooling1D(2),
                        L.Conv1D(16, 5, padding='same', activation='relu'), L.MaxPooling1D(2),
                        L.Conv1D(8, 5, padding='same', activation='relu'),
                        L.UpSampling1D(2), L.Conv1D(16, 5, padding='same', activation='relu'),
                        L.UpSampling1D(2), L.Conv1D(32, 5, padding='same', activation='relu'),
                        L.Conv1D(F, 5, padding='same')])
    else:
        u = int(nombre.replace('ae_lstm', ''))
        m = Sequential([L.Input((C.W, F)), L.LSTM(u), L.RepeatVector(C.W), L.LSTM(u, return_sequences=True),
                        L.Dense(F)])
    m.compile(optimizer=tf.keras.optimizers.Adam(1e-3), loss='mse')
    return m


def main():
    d = preparar()
    conj = dict(val=d['X_va'], test=d['X_te'], fval=d['F_va'], ftest=d['F_te'])
    out, info = {}, dict(nombre=NOMBRE)
    t0 = time.time()
    if NOMBRE == 'pca':
        from sklearn.decomposition import PCA
        p = PCA(n_components=0.95, random_state=C.SEED).fit(d['X_tr'].reshape(len(d['X_tr']), -1))
        info['componentes'] = int(p.n_components_)
        info['parametros'] = int(p.components_.size + p.mean_.size)
        for k, X in conj.items():
            Xf = X.reshape(len(X), -1)
            R = p.inverse_transform(p.transform(Xf)).reshape(X.shape)
            out['E_' + k] = ((X - R) ** 2).mean(1)
    elif NOMBRE in ('iforest', 'ocsvm'):
        from sklearn.preprocessing import StandardScaler
        S = resumen(d['X_tr'])
        sc = StandardScaler().fit(S)
        if NOMBRE == 'iforest':
            from sklearn.ensemble import IsolationForest
            m = IsolationForest(n_estimators=200, random_state=C.SEED, n_jobs=HILOS).fit(sc.transform(S))
        else:
            from sklearn.svm import OneClassSVM
            rng = np.random.default_rng(C.SEED)
            sub = rng.choice(len(S), 20000, replace=False)
            m = OneClassSVM(kernel='rbf', gamma='scale', nu=0.01).fit(sc.transform(S[sub]))
            info['vectores_soporte'] = int(len(m.support_))
        for k, X in conj.items():
            out['S_' + k] = -m.decision_function(sc.transform(resumen(X)))
    else:
        import tensorflow as tf
        m = construir(NOMBRE)
        info['parametros'] = int(m.count_params())
        if NOMBRE == 'ae_denso':
            Xtr, Xva, bs = d['X_tr'].reshape(-1, len(C.PIDS)), d['X_va'].reshape(-1, len(C.PIDS)), 512
            # registros unicos (las ventanas se solapan): se toma el ultimo registro de cada paso
            Xtr, Xva = d['X_tr'][:, -C.STEP:].reshape(-1, len(C.PIDS)), d['X_va'][:, -C.STEP:].reshape(-1, len(C.PIDS))
        else:
            Xtr, Xva, bs = d['X_tr'], d['X_va'], 128
        cb = [tf.keras.callbacks.EarlyStopping(patience=6, restore_best_weights=True),
              tf.keras.callbacks.ReduceLROnPlateau(factor=0.5, patience=3)]
        h = m.fit(Xtr, Xtr, validation_data=(Xva, Xva), epochs=MAX_EPOCAS, batch_size=bs, callbacks=cb, verbose=2)
        info['epocas'] = len(h.history['loss'])
        info['val_loss'] = float(min(h.history['val_loss']))
        info['historia'] = dict(loss=h.history['loss'], val_loss=h.history['val_loss'])
        m.save(os.path.join(C.MOD, NOMBRE + '.keras'))
        for k, X in conj.items():
            if NOMBRE == 'ae_denso':
                Xr = X.reshape(-1, len(C.PIDS))
                R = m.predict(Xr, batch_size=8192, verbose=0).reshape(X.shape)
            else:
                R = m.predict(X, batch_size=1024, verbose=0)
            out['E_' + k] = ((X - R) ** 2).mean(1)
    info['segundos'] = time.time() - t0
    np.savez_compressed(os.path.join(C.RES, 'punt_' + NOMBRE + '.npz'), **out)
    C.guardar_json(info, 'info_' + NOMBRE + '.json')
    if not os.path.exists(os.path.join(C.RES, 'meta.npz')):
        np.savez_compressed(os.path.join(C.RES, 'meta.npz'), sid_va=d['sid_va'], sid_te=d['sid_te'],
                            meta_va=d['meta_va'], meta_te=d['meta_te'], media=d['media'], escala=d['escala'],
                            tr=d['tr'], va=d['va'], te=d['te'],
                            dur_va=[len(d['ses'][n]) for n in d['va']], dur_te=[len(d['ses'][n]) for n in d['te']],
                            dur_tr=[len(d['ses'][n]) for n in d['tr']], n_tr=len(d['X_tr']))
    print(NOMBRE, {k: v for k, v in info.items() if k != 'historia'})


if __name__ == '__main__':
    main()
