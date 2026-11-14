"""Decision sensible al costo y concordancia SHAP-LIME sobre el clasificador LightGBM (EngineFaultDB)."""
import os
import warnings
import joblib
import numpy as np
import pandas as pd
from scipy import stats
import comun as C

warnings.filterwarnings('ignore')
D = np.load(os.path.join(C.RES, 'e2_lgbm_test.npz'))
P, yte, Xte, Xtr, ytr = D['proba'], D['yte'], D['Xte'], D['Xtr'], D['ytr']
m = joblib.load(os.path.join(C.MOD, 'lgbm_enginefaultdb.joblib'))
imp = pd.read_csv(os.path.join(C.RES, 'e3_impacto.csv'))
rel = imp[imp.variable == 'Consumo'].set_index('falla')
# peso de omitir cada falla: 1 + sobreconsumo relativo, solo si es significativo con errores robustos
w = {k: 1 + (rel.loc[k, 'relativo'] if rel.loc[k, 'p_robusto'] < 0.05 and rel.loc[k, 'relativo'] > 0 else 0) for k in (1, 2, 3)}
filas = []
for r in (1, 5, 10, 50):
    Cm = np.ones((4, 4)) - np.eye(4)          # fila: clase real; columna: decision
    for k in (1, 2, 3):
        Cm[k, 0] = r * w[k]                     # omitir una falla
    dec = (P @ Cm).argmin(1)
    for nombre, d in (('argmax', P.argmax(1)), ('costo mínimo', dec)):
        falla, dfalla = yte > 0, d > 0
        filas.append(dict(r=r, regla=nombre, costo_medio=Cm[yte, d].mean(), exactitud=(d == yte).mean(),
                          recall_falla=(dfalla & falla).sum() / falla.sum(),
                          falsas_alarmas=(dfalla & ~falla).sum() / (~falla).sum(),
                          omitidas=int((~dfalla & falla).sum())))
T = pd.DataFrame(filas)
T.to_csv(os.path.join(C.RES, 'e3_costo.csv'), index=False)
print(w)
print(T.round(4).to_string())
# calibracion (error de calibracion esperado, 10 intervalos) de la probabilidad de la clase predicha
conf, ok = P.max(1), P.argmax(1) == yte
bins = np.clip((conf * 10).astype(int), 0, 9)
ece = sum(abs(ok[bins == b].mean() - conf[bins == b].mean()) * (bins == b).mean() for b in range(10) if (bins == b).any())
print('ECE', ece)

# ---------------------------------------------------------------- SHAP y LIME
import shap
from lime.lime_tabular import LimeTabularExplainer
rng = np.random.default_rng(C.SEED)
idx = rng.choice(len(Xte), 2000, replace=False)
sv = shap.TreeExplainer(m).shap_values(Xte[idx])
sv = np.stack(sv, -1) if isinstance(sv, list) else sv      # (n, variables, clases)
pred = P[idx].argmax(1)
S = np.stack([sv[i, :, pred[i]] for i in range(len(idx))])
glob = pd.DataFrame(dict(variable=C.EF_FEATS, shap_medio_abs=np.abs(sv).mean((0, 2)))).sort_values('shap_medio_abs', ascending=False)
glob.to_csv(os.path.join(C.RES, 'e4_shap_global.csv'), index=False)
print(glob.round(4).to_string())
lime = LimeTabularExplainer(Xtr, feature_names=C.EF_FEATS, discretize_continuous=False, random_state=C.SEED)
n = 200
sol, rho, signo = [], [], []
for i in range(n):
    c = int(pred[i])
    e = lime.explain_instance(Xte[idx[i]], m.predict_proba, labels=[c], num_features=len(C.EF_FEATS), num_samples=2000)
    l = np.zeros(len(C.EF_FEATS))
    for j, v in e.as_map()[c]:
        l[j] = v
    # LIME ajusta el modelo local sobre variables estandarizadas: la contribucion es coeficiente x valor estandarizado
    l = l * (Xte[idx[i]] - lime.scaler.mean_) / lime.scaler.scale_
    s = S[i]
    ts, tl = set(np.argsort(-np.abs(s))[:3]), set(np.argsort(-np.abs(l))[:3])
    sol.append(len(ts & tl) / 3)
    rho.append(stats.spearmanr(np.abs(s), np.abs(l)).statistic)
    comunes = list(ts & tl)
    signo.append(np.mean(np.sign(s[comunes]) == np.sign(l[comunes])) if comunes else np.nan)
res = dict(n_shap=len(idx), n_lime=n, solape_top3=float(np.mean(sol)), spearman=float(np.nanmean(rho)),
           signo=float(np.nanmean(signo)), ece=float(ece), pesos=w)
C.guardar_json(res, 'e4_resumen.json')
print(res)
