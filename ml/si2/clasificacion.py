"""Diagnostico supervisado en EngineFaultDB: cota de exactitud, comparacion de clasificadores,
pruebas de significancia y validacion agrupada por punto de operacion."""
import os
import sys
import time
import warnings

import numpy as np
import pandas as pd
from scipy import stats
from sklearn.base import clone
from sklearn.discriminant_analysis import LinearDiscriminantAnalysis
from sklearn.ensemble import ExtraTreesClassifier, RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, confusion_matrix, f1_score
from sklearn.model_selection import (RandomizedSearchCV, StratifiedGroupKFold, StratifiedKFold, cross_val_score,
                                     train_test_split)
from sklearn.naive_bayes import GaussianNB
from sklearn.neighbors import KNeighborsClassifier
from sklearn.neural_network import MLPClassifier
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.svm import SVC
from sklearn.tree import DecisionTreeClassifier
from statsmodels.stats.contingency_tables import cochrans_q, mcnemar
from statsmodels.stats.multitest import multipletests

import comun as C

warnings.filterwarnings('ignore')
NJ = int(sys.argv[1]) if len(sys.argv) > 1 else 2
df = C.load_enginefaultdb()
X, y, g = df[C.EF_FEATS].values, df['Fault'].values, df['bloque'].values
R = {}

# ------------------------------------------------------------------ E1: cota de exactitud
clave = pd.util.hash_pandas_object(df[C.EF_FEATS], index=False)
tab = pd.crosstab(clave, df['Fault'])
R['cota_exactitud'] = float(tab.max(1).sum() / len(df))
R['vectores_unicos'] = int(len(tab))
amb = tab[(tab > 0).sum(1) > 1]
R['registros_ambiguos'] = int(amb.values.sum())
R['ambiguos_por_clase'] = {int(k): int(v) for k, v in amb.sum(0).items()}
R['pares_ambiguos'] = {str(k): int(v) for k, v in
                       amb.apply(lambda r: '-'.join(str(c) for c in r.index[r > 0]), axis=1).value_counts().items()}
f2 = df[df.Fault == 2].reset_index(drop=True)
f3 = df[df.Fault == 3].reset_index(drop=True)
n23 = min(len(f3), len(f2) - 1000)
R['f3_igual_f2_desplazado'] = float((f3[C.EF_FEATS].values[:n23] == f2[C.EF_FEATS].values[1000:1000 + n23]).all(1).mean())
R['bloques'] = int(df['bloque'].nunique())
# Falla 2 frente a Falla 3: pruebas de Kolmogorov-Smirnov por variable y prueba de dos muestras con clasificador
ks = {v: stats.ks_2samp(f2[v], f3[v]) for v in C.EF_FEATS}
R['ks_f2_f3'] = {v: dict(D=float(k.statistic), p=float(k.pvalue)) for v, k in ks.items()}
ks01 = {v: stats.ks_2samp(df[df.Fault == 0][v], df[df.Fault == 1][v]) for v in C.EF_FEATS}
R['ks_f0_f1'] = {v: dict(D=float(k.statistic), p=float(k.pvalue)) for v, k in ks01.items()}
from lightgbm import LGBMClassifier as _L
from sklearn.model_selection import cross_val_predict as _cvp
from sklearn.metrics import roc_auc_score as _auc
d23 = df[df.Fault >= 2]
pr = _cvp(_L(n_estimators=200, verbose=-1, random_state=C.SEED, n_jobs=NJ), d23[C.EF_FEATS].values, (d23.Fault == 3).values,
          cv=StratifiedKFold(5, shuffle=True, random_state=C.SEED), method='predict_proba')[:, 1]
R['auc_f2_vs_f3'] = float(_auc((d23.Fault == 3).values, pr))
R['exactitud_f2_vs_f3'] = float(((pr > 0.5) == (d23.Fault == 3).values).mean())
n = df['Fault'].value_counts()
R['cota_si_f2_f3_indistinguibles'] = float((n[0] + n[1] + max(n[2], n[3])) / len(df))
print('E1', R, flush=True)

# ------------------------------------------------------------------ E2: clasificadores
Xtr, Xte, ytr, yte, gtr, gte = train_test_split(X, y, g, test_size=0.2, random_state=C.SEED, stratify=y)
esc = lambda m: make_pipeline(StandardScaler(), m)
from catboost import CatBoostClassifier
from lightgbm import LGBMClassifier
from xgboost import XGBClassifier

MODELOS = {
    'Regresión logística': esc(LogisticRegression(max_iter=300)),
    'Naive Bayes gaussiano': GaussianNB(),
    'k vecinos (kNN)': esc(KNeighborsClassifier(n_neighbors=21)),
    'Árbol de decisión': DecisionTreeClassifier(max_depth=12, min_samples_leaf=5, random_state=C.SEED),
    'Random Forest': RandomForestClassifier(n_estimators=200, min_samples_leaf=3, random_state=C.SEED, n_jobs=NJ),
    'Extra Trees': ExtraTreesClassifier(n_estimators=200, min_samples_leaf=3, random_state=C.SEED, n_jobs=NJ),
    'SVM (RBF)': esc(SVC(kernel='rbf', C=10, gamma='scale')),
    'Perceptrón multicapa': esc(MLPClassifier(hidden_layer_sizes=(64, 32), max_iter=150, early_stopping=True, random_state=C.SEED)),
    'XGBoost': XGBClassifier(n_estimators=300, max_depth=6, learning_rate=0.1, tree_method='hist', random_state=C.SEED, n_jobs=NJ, verbosity=0),
    'LightGBM': LGBMClassifier(n_estimators=300, num_leaves=31, learning_rate=0.1, random_state=C.SEED, n_jobs=NJ, verbose=-1),
    'CatBoost': CatBoostClassifier(iterations=300, depth=6, learning_rate=0.1, random_seed=C.SEED, thread_count=NJ, verbose=0),
}
rng = np.random.default_rng(C.SEED)
sub_svm = rng.choice(len(Xtr), 15000, replace=False)
filas, pred, mejores = [], {}, {}
cv5 = StratifiedKFold(5, shuffle=True, random_state=C.SEED)
for nombre, m in MODELOS.items():
    t0 = time.time()
    Xa, ya = (Xtr[sub_svm], ytr[sub_svm]) if nombre.startswith('SVM') else (Xtr, ytr)
    cv = cross_val_score(clone(m), Xa, ya, cv=cv5, scoring='accuracy', n_jobs=1)
    best = clone(m).fit(Xa, ya)
    p = np.asarray(best.predict(Xte)).ravel()
    pred[nombre], mejores[nombre] = p, best
    acc = accuracy_score(yte, p)
    ok = (p == yte)
    boot = [ok[rng.integers(0, len(ok), len(ok))].mean() for _ in range(1000)]
    filas.append(dict(modelo=nombre, cv_media=cv.mean(), cv_de=cv.std(), exactitud=acc,
                      ic_inf=np.percentile(boot, 2.5), ic_sup=np.percentile(boot, 97.5),
                      f1_macro=f1_score(yte, p, average='macro'), segundos=time.time() - t0,
                      ))
    print(filas[-1], flush=True)
T = pd.DataFrame(filas)
T.to_csv(os.path.join(C.RES, 'e2_clasificadores.csv'), index=False)

aciertos = np.column_stack([pred[n] == yte for n in MODELOS])
q = cochrans_q(aciertos)
R['cochran_todos'] = dict(Q=float(q.statistic), p=float(q.pvalue), gl=aciertos.shape[1] - 1)
no_lin = [i for i, n in enumerate(MODELOS) if n not in ('Regresión logística', 'Naive Bayes gaussiano')]
q2 = cochrans_q(aciertos[:, no_lin])
R['cochran_no_lineales'] = dict(Q=float(q2.statistic), p=float(q2.pvalue), gl=len(no_lin) - 1)
mejor = T.sort_values('exactitud', ascending=False).iloc[0]['modelo']
R['mejor'] = mejor
pv, nombres = [], []
for n in MODELOS:
    if n == mejor:
        continue
    a, b = pred[mejor] == yte, pred[n] == yte
    tabm = [[np.sum(a & b), np.sum(a & ~b)], [np.sum(~a & b), np.sum(~a & ~b)]]
    pv.append(mcnemar(tabm, exact=False, correction=True).pvalue)
    nombres.append(n)
holm = multipletests(pv, method='holm')[1]
pd.DataFrame(dict(modelo=nombres, p_mcnemar=pv, p_holm=holm)).to_csv(os.path.join(C.RES, 'e2_mcnemar.csv'), index=False)
cm = confusion_matrix(yte, pred[mejor])
np.savetxt(os.path.join(C.RES, 'e2_confusion_mejor.csv'), cm, fmt='%d', delimiter=',')
R['recall_por_clase_mejor'] = (cm.diagonal() / cm.sum(1)).tolist()
print('E2', R, flush=True)
C.guardar_json(R, 'e1_e2_resumen.json')

# probabilidades del mejor modelo de boosting para la decision sensible al costo y la explicabilidad
lgbm = mejores['LightGBM']
np.savez_compressed(os.path.join(C.RES, 'e2_lgbm_test.npz'), proba=lgbm.predict_proba(Xte), yte=yte, Xte=Xte,
                    Xtr=Xtr, ytr=ytr)
import joblib
joblib.dump(lgbm, os.path.join(C.MOD, 'lgbm_enginefaultdb.joblib'))

print('FIN')
