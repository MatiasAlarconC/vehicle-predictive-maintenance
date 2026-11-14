"""Datos de flota real (Barreto, 2018): disponibilidad de PIDs, heterogeneidad y DTC con validacion por vehiculo."""
import os
import warnings

import numpy as np
import pandas as pd
from scipy import stats
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.metrics import average_precision_score, precision_score, recall_score, roc_auc_score
from sklearn.model_selection import StratifiedKFold, cross_val_predict

import comun as C

warnings.filterwarnings('ignore')
b = pd.read_csv(os.path.join(C.DATA, 'OBDdatasets', 'masterDegreeResearch', 'dailyRoutes.csv'), sep=';', low_memory=False)
R = dict(filas=int(len(b)))
b = b[b.VEHICLE_ID.notna()]
R['con_vehiculo'] = int(len(b))
n = b.VEHICLE_ID.value_counts()
b = b[b.VEHICLE_ID.isin(n[n >= 100].index)].copy()
R['filas_usadas'], R['vehiculos'] = int(len(b)), int(b.VEHICLE_ID.nunique())
COLS = ['ENGINE_RPM', 'SPEED', 'THROTTLE_POS', 'ENGINE_LOAD', 'ENGINE_COOLANT_TEMP', 'INTAKE_MANIFOLD_PRESSURE',
        'AIR_INTAKE_TEMP', 'TIMING_ADVANCE', 'SHORT TERM FUEL TRIM BANK 1', 'MAF', 'FUEL_LEVEL', 'BAROMETRIC_PRESSURE(KPA)']
for c in COLS:
    b[c] = pd.to_numeric(b[c].astype(str).str.replace('%', '').str.replace(',', '.'), errors='coerce')
b['dtc'] = b.TROUBLE_CODES.notna().astype(int)
R['registros_dtc'] = int(b.dtc.sum())
R['dtc_por_vehiculo'] = b[b.dtc == 1].groupby('VEHICLE_ID').size().to_dict()
R['codigos'] = b[b.dtc == 1].groupby('VEHICLE_ID').TROUBLE_CODES.agg(lambda s: s.value_counts().index[0]).to_dict()
disp = b.groupby('VEHICLE_ID')[COLS].agg(lambda s: s.notna().mean() > 0.5)
R['disponibilidad_pid'] = disp.mean().round(3).to_dict()
R['vehiculos_con_todos'] = int(disp.all(1).sum())
# heterogeneidad entre vehiculos (Kruskal-Wallis y eta cuadrado por rangos)
het = {}
for c in ['ENGINE_RPM', 'ENGINE_LOAD', 'ENGINE_COOLANT_TEMP', 'INTAKE_MANIFOLD_PRESSURE', 'SPEED']:
    gs = [g[c].dropna().values for _, g in b.groupby('VEHICLE_ID') if g[c].notna().sum() > 30]
    H, p = stats.kruskal(*gs)
    N = sum(len(g) for g in gs)
    het[c] = dict(H=float(H), p=float(p), eta2=float((H - len(gs) + 1) / (N - len(gs))), vehiculos=len(gs))
R['heterogeneidad'] = het
# asociacion DTC-vehiculo (V de Cramer)
ct = pd.crosstab(b.VEHICLE_ID, b.dtc)
chi2 = stats.chi2_contingency(ct)[0]
R['cramer_v'] = float(np.sqrt(chi2 / (len(b) * (min(ct.shape) - 1))))
# prediccion de DTC: particion aleatoria frente a dejar un vehiculo fuera
F = ['ENGINE_RPM', 'SPEED', 'THROTTLE_POS', 'ENGINE_LOAD', 'ENGINE_COOLANT_TEMP', 'INTAKE_MANIFOLD_PRESSURE',
     'AIR_INTAKE_TEMP', 'TIMING_ADVANCE']
X, y, g = b[F].values, b.dtc.values, b.VEHICLE_ID.values
m = HistGradientBoostingClassifier(random_state=C.SEED)
pa = cross_val_predict(m, X, y, cv=StratifiedKFold(5, shuffle=True, random_state=C.SEED), method='predict_proba')[:, 1]
R['aleatoria'] = dict(recall=float(recall_score(y, pa > 0.5)), precision=float(precision_score(y, pa > 0.5)),
                      auc=float(roc_auc_score(y, pa)), auc_pr=float(average_precision_score(y, pa)))
pl = np.zeros(len(y))
filas = []
for v in np.unique(g):
    te = g == v
    pl[te] = HistGradientBoostingClassifier(random_state=C.SEED).fit(X[~te], y[~te]).predict_proba(X[te])[:, 1]
    filas.append(dict(vehiculo=v, registros=int(te.sum()), dtc=int(y[te].sum()),
                      recall=float(recall_score(y[te], pl[te] > 0.5)) if y[te].sum() else np.nan,
                      falsas_alarmas=float(((pl[te] > 0.5) & (y[te] == 0)).sum() / max(1, (y[te] == 0).sum()))))
pd.DataFrame(filas).to_csv(os.path.join(C.RES, 'e7_por_vehiculo.csv'), index=False)
R['por_vehiculo'] = dict(recall=float(recall_score(y, pl > 0.5)), precision=float(precision_score(y, pl > 0.5, zero_division=0)),
                         auc=float(roc_auc_score(y, pl)), auc_pr=float(average_precision_score(y, pl)))
R['prevalencia_dtc'] = float(y.mean())
C.guardar_json(R, 'e7_resumen.json')
import json
print(json.dumps(R, indent=1, default=float))
print(pd.DataFrame(filas).round(3).to_string())
