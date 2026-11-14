"""Evalua los detectores de anomalias: metricas por ventana y por serie, persistencia y atribucion."""
import json
import os

import numpy as np
import pandas as pd
from sklearn.metrics import average_precision_score, precision_recall_fscore_support, roc_auc_score

import comun as C

M = np.load(os.path.join(C.RES, 'meta.npz'), allow_pickle=True)
DET = [('pca', 'PCA (95 % de varianza)'), ('iforest', 'Isolation Forest'), ('ocsvm', 'One-Class SVM'),
       ('ae_denso', 'Autoencoder denso'), ('ae_conv', 'Autoencoder Conv1D'), ('ae_lstm32', 'Autoencoder LSTM (32)'),
       ('ae_lstm64', 'Autoencoder LSTM (64)')]
DET = [d for d in DET if os.path.exists(os.path.join(C.RES, 'punt_%s.npz' % d[0]))]
ESC = list(C.ESCENARIOS)
PESOS = np.array([C.ESCENARIOS[e]['peso'] for e in ESC])
SEN = [[C.IX[s] for s in C.ESCENARIOS[e]['senales']] for e in ESC]
PERS = [1, 3, 6, 12]
MAX_FA = 0.5  # episodios de falsa alarma por hora admitidos al elegir la persistencia (en validacion)


def puntajes(nombre):
    P = np.load(os.path.join(C.RES, 'punt_%s.npz' % nombre))
    if 'E_val' in P:
        ebar = np.percentile(P['E_val'], 99, axis=0)
        r = {k: P['E_' + k] / ebar for k in ('val', 'test', 'fval', 'ftest')}
        s = {k: v.max(1) for k, v in r.items()}
        return s, r, ebar
    return {k: P['S_' + k] for k in ('val', 'test', 'fval', 'ftest')}, None, None


def alerta(sobre, m):
    """Alerta en la ventana i si las ultimas m ventanas superan el umbral."""
    if m == 1:
        return sobre.copy()
    c = np.convolve(sobre.astype(int), np.ones(m, dtype=int), mode='full')[:len(sobre)]
    return c >= m


def episodios(al):
    return int(np.sum(al[1:] & ~al[:-1]) + al[0]) if len(al) else 0


def series(s_sano, sid, s_falla, meta, thr, m):
    """Devuelve por serie: detectada, detectada por azar (misma zona en la sesion sana), latencia (s)."""
    out = []
    seqs = {i: s_sano[sid == i] for i in np.unique(sid)}
    for j in np.unique(meta[:, 0]):
        f = meta[:, 0] == j
        mt = meta[f]
        base = seqs[mt[0, 1]]
        seq = base.copy()
        seq[mt[:, 2]] = s_falla[f]
        pos = np.zeros(len(seq), bool)
        pos[mt[mt[:, 3] >= C.W // 2, 2]] = True
        al, al0 = alerta(seq > thr, m), alerta(base > thr, m)
        det = bool((al & pos).any())
        ini_v = mt[0, 2]  # primera ventana que toca la falla
        lat = (np.argmax(al & pos) - ini_v + 1) * C.STEP if det else np.nan
        out.append((j, mt[0, 4], mt[0, 5], det, bool((al0 & pos).any()), lat))
    return pd.DataFrame(out, columns=['serie', 'esc', 'sev', 'det', 'azar', 'latencia'])


def falsas_por_hora(s_sano, sid, dur, thr, m):
    n = sum(episodios(alerta(s_sano[sid == i] > thr, m)) for i in np.unique(sid))
    return n / (sum(dur) / 3600.0)


