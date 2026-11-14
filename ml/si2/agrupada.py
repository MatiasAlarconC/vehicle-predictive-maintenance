"""Validacion agrupada por punto de operacion frente a particion aleatoria (EngineFaultDB)."""
import os, sys, warnings
import numpy as np, pandas as pd
from sklearn.base import clone
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score
from sklearn.model_selection import StratifiedGroupKFold, StratifiedKFold
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
from lightgbm import LGBMClassifier
import comun as C
warnings.filterwarnings('ignore')
NJ = int(sys.argv[1]) if len(sys.argv) > 1 else 1
df = C.load_enginefaultdb()
X, y, g = df[C.EF_FEATS].values, df['Fault'].values, df['bloque'].values
esc = lambda m: make_pipeline(StandardScaler(), m)
# ------------------------------------------------------------------ validacion agrupada
filas = []
y3 = np.where(y == 3, 2, y)  # Falla 2 y Falla 3 fusionadas
base = {'Regresión logística': esc(LogisticRegression(max_iter=300)),
        'Random Forest': RandomForestClassifier(n_estimators=100, random_state=C.SEED, n_jobs=NJ),
        'LightGBM': LGBMClassifier(n_estimators=150, random_state=C.SEED, n_jobs=NJ, verbose=-1)}
for etiqueta, yy in (('4 clases', y), ('3 clases', y3)):
    for nombre, m in base.items():
        al, ag = [], []
        for rep in range(2):
            for tr, te in StratifiedKFold(5, shuffle=True, random_state=rep).split(X, yy):
                al.append(accuracy_score(yy[te], clone(m).fit(X[tr], yy[tr]).predict(X[te])))
            for tr, te in StratifiedGroupKFold(5, shuffle=True, random_state=rep).split(X, yy, g):
                ag.append(accuracy_score(yy[te], clone(m).fit(X[tr], yy[tr]).predict(X[te])))
        filas.append(dict(problema=etiqueta, modelo=nombre, aleatoria=np.mean(al), aleatoria_de=np.std(al),
                          agrupada=np.mean(ag), agrupada_de=np.std(ag)))
        print(filas[-1], flush=True)
pd.DataFrame(filas).to_csv(os.path.join(C.RES, 'e2_agrupada.csv'), index=False)
print('FIN')
