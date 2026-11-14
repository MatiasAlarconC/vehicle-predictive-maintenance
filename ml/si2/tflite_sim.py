"""Conversion del autoencoder Conv1D a TensorFlow Lite, verificacion de equivalencia y latencia,
simulacion en linea y prueba de la cadena de lectura OBD-II con el emulador ELM327."""
import json
import os
import time

import numpy as np
import pandas as pd
import tensorflow as tf
from sklearn.metrics import roc_auc_score

import comun as C
from detector_en_linea import DetectorEnLinea
from elm327 import ClienteElm327, Emulador

M = np.load(os.path.join(C.RES, 'meta.npz'), allow_pickle=True)
RS = json.load(open(os.path.join(C.RES, 'e5_resumen.json')))
assert RS['elegido'] == 'ae_conv'
modelo = tf.keras.models.load_model(os.path.join(C.MOD, 'ae_conv.keras'))
cfg = dict(senales=C.PIDS, etiquetas=C.PID_ES, media=M['media'].tolist(), escala=M['escala'].tolist(),
           error_referencia=RS['ebar'], umbral=RS['umbral'], persistencia=RS['m'], ventana=C.W, paso=C.STEP)
RUTA_CFG = os.path.join(C.MOD, 'vera_config.json')
json.dump(cfg, open(RUTA_CFG, 'w'), indent=1)

# ------------------------------------------------------------------ conversion
def convertir(variante):
    conv = tf.lite.TFLiteConverter.from_keras_model(modelo)
    if variante == 'float16':
        conv.optimizations = [tf.lite.Optimize.DEFAULT]
        conv.target_spec.supported_types = [tf.float16]
    elif variante == 'rango dinámico':
        conv.optimizations = [tf.lite.Optimize.DEFAULT]
    return conv.convert()

rutas = {}
for v, arch in (('float32', 'vera_ae_conv.tflite'), ('float16', 'vera_ae_conv_f16.tflite'), ('rango dinámico', 'vera_ae_conv_dr.tflite')):
    rutas[v] = os.path.join(C.MOD, arch)
    open(rutas[v], 'wb').write(convertir(v))

# ventanas de prueba (sanas y con falla), reconstruidas igual que en el entrenamiento
import detectores as DT
d = DT.preparar()
pos = d['meta_te'][:, 3] >= C.W // 2
Xs, Xf = d['X_te'], d['F_te'][pos]
y = np.r_[np.zeros(len(Xs)), np.ones(len(Xf))]
X = np.concatenate([Xs, Xf])
ebar, thr = np.array(RS['ebar']), RS['umbral']
ref = ((X - modelo.predict(X, batch_size=1024, verbose=0)) ** 2).mean(1) / ebar
s_ref = ref.max(1)
filas = [dict(variante='Keras (referencia)', kB=os.path.getsize(os.path.join(C.MOD, 'ae_conv.keras')) / 1024,
              auc_roc=roc_auc_score(y, s_ref), concordancia=1.0, dif_max=0.0)]
rng = np.random.default_rng(C.SEED)
for v, ruta in rutas.items():
    det = DetectorEnLinea(ruta, RUTA_CFG)
    s = np.array([det.puntuar(x)[0] for x in X])
    lat = []
    for i in rng.integers(0, len(X), 1100):
        t0 = time.perf_counter()
        det.puntuar(X[i])
        lat.append((time.perf_counter() - t0) * 1000)
    lat = np.array(lat[100:])
    filas.append(dict(variante='TFLite ' + v, kB=os.path.getsize(ruta) / 1024, auc_roc=roc_auc_score(y, s),
                      concordancia=float(((s > thr) == (s_ref > thr)).mean()), dif_max=float(np.abs(s - s_ref).max()),
                      lat_mediana_ms=float(np.median(lat)), lat_p95_ms=float(np.percentile(lat, 95))))
T = pd.DataFrame(filas)
T.to_csv(os.path.join(C.RES, 'e8_tflite.csv'), index=False)
print(T.round(5).to_string(), flush=True)

# ------------------------------------------------------------------ simulacion en linea y emulador ELM327
det = DetectorEnLinea(rutas['float32'], RUTA_CFG)
ses = d['ses']
series = C.series_con_falla(ses, d['te'], 11)

def transmitir(x, fuente=None):
    det.reiniciar()
    out = []
    for t in range(len(x)):
        lec = x[t] if fuente is None else fuente.leer()
        r = det.agregar(lec)
        if r is not None:
            out.append((r['puntaje'], r['alerta'], r['senales'][0]))
    return out

# (a) el detector en linea reproduce el calculo por lotes
seqs = {i: s_ref[:len(Xs)][d['sid_te'] == i] for i in range(len(d['te']))}
dif, n_al = 0.0, 0
for i, n in enumerate(d['te']):
    o = transmitir(ses[n])
    dif = max(dif, float(np.abs(np.array([a[0] for a in o]) - seqs[i]).max()))
    n_al += sum(a[1] for a in o)
R = dict(dif_max_en_linea=dif, ventanas_en_linea=int(sum(len(v) for v in seqs.values())), alertas_sanas=int(n_al))

# (b) cadena completa a traves del protocolo ELM327 (sesiones de prueba sanas y con falla)
rng = np.random.default_rng(C.SEED)
casos = [(n, ses[n], None) for n in d['te']] + [(s['sesion'], s['x'], s) for s in [series[i] for i in rng.choice(len(series), 60, replace=False)]]
igual, total, err, n_lect, t_lect, det_dir, det_obd, top_ok, top_n = 0, 0, [], 0, 0.0, 0, 0, 0, 0
soportados = None
for nombre, x, s in casos:
    directo = transmitir(x)
    emu = Emulador(x)
    emu.start()
    cli = ClienteElm327('127.0.0.1', emu.puerto)
    soportados = sorted(cli.soportados)
    det.reiniciar()
    obd, lecturas = [], []
    t0 = time.perf_counter()
    for t in range(len(x)):
        lec = cli.leer()
        lecturas.append(lec)
        r = det.agregar(lec)
        if r is not None:
            obd.append((r['puntaje'], r['alerta'], r['senales'][0]))
    t_lect += time.perf_counter() - t0
    n_lect += len(x)
    cli.cerrar()
    err.append(np.abs(np.array(lecturas) - x).max(0))
    a, b = np.array([o[1] for o in directo]), np.array([o[1] for o in obd])
    igual += int((a == b).sum())
    total += len(a)
    if s is not None:
        ends = np.arange(C.W, len(x) + 1, C.STEP)
        zona = (np.minimum(ends, s['fin']) - np.maximum(ends - C.W, s['ini'])) >= C.W // 2
        det_dir += int((a & zona).any())
        det_obd += int((b & zona).any())
R.update(casos_obd=len(casos), series_falla_obd=60, lecturas_obd=int(n_lect), ms_por_lectura_12pid=1000 * t_lect / n_lect,
         concordancia_alertas_obd=igual / total, ventanas_obd=int(total), detectadas_directo=det_dir, detectadas_obd=det_obd,
         error_max_cuantizacion=dict(zip(C.PIDS, np.max(err, 0).round(4).tolist())), pids_soportados=soportados)
C.guardar_json(R, 'e8_resumen.json')
print(json.dumps(R, indent=1, default=float))
