"""Impacto de cada falla sobre consumo y emisiones (EngineFaultDB): MCO con errores robustos por bloque."""
import os
import numpy as np
import pandas as pd
import statsmodels.formula.api as smf
import comun as CM

df = CM.load_enginefaultdb().rename(columns={'Consumption L/100KM': 'cons100', 'Consumption L/H': 'consh'})
filas = []
for y, nombre, unidad in (('consh', 'Consumo', 'L/h'), ('cons100', 'Consumo por distancia', 'L/100 km'), ('CO', 'CO', '% vol.'), ('HC', 'HC', 'ppm'),
                          ('Lambda', 'Lambda', '-')):
    m = smf.ols(y + ' ~ C(Fault) + RPM + TPS', df).fit(cov_type='cluster', cov_kwds={'groups': df['bloque'].astype('category').cat.codes})
    m0 = smf.ols(y + ' ~ C(Fault) + RPM + TPS', df).fit()
    base = df[df.Fault == 0][y].mean()
    for k in (1, 2, 3):
        t = 'C(Fault)[T.%d]' % k
        ci = m.conf_int().loc[t]
        filas.append(dict(variable=nombre, unidad=unidad, falla=k, media_normal=base, coef=m.params[t], ic_inf=ci[0], ic_sup=ci[1],
                          p_robusto=m.pvalues[t], p_clasico=m0.pvalues[t], relativo=m.params[t] / base, r2=m.rsquared))
T = pd.DataFrame(filas)
T.to_csv(os.path.join(CM.RES, 'e3_impacto.csv'), index=False)
pd.set_option('display.width', 250)
print(T.round(4).to_string())
print(df.groupby('Fault')[['consh', 'cons100', 'CO', 'HC', 'CO2', 'O2', 'Lambda', 'RPM', 'TPS', 'Speed']].mean().round(3))
