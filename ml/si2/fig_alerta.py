"""Figuras de resultados del articulo."""
import json, os
import numpy as np, pandas as pd
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
from sklearn.metrics import roc_curve
import comun as C
import evaluar_lib as EV

plt.rcParams.update({'font.family': 'Inter', 'font.size': 10, 'axes.spines.top': False, 'axes.spines.right': False,
                     'axes.edgecolor': '#666', 'axes.linewidth': 0.8, 'xtick.color': '#444', 'ytick.color': '#444'})
NAVY, GRIS, NAR = '#1F4E79', '#9AA3AD', '#C8641E'

# ---- Figura: ejemplo de alerta en linea (sobrecalentamiento moderado)
from detector_en_linea import DetectorEnLinea
import detectores as DT
d = DT.preparar()
series = C.series_con_falla(d['ses'], d['te'], 11)
det = DetectorEnLinea(os.path.join(C.MOD, 'vera_ae_conv.tflite'), os.path.join(C.MOD, 'vera_config.json'))
cand = [s for s in series if s['esc'] == 'sobrecalentamiento' and s['sev'] == 'moderada' and len(s['x']) > 1500]
s = cand[0]
t_s, sc, al = [], [], []
for t in range(len(s['x'])):
    r = det.agregar(s['x'][t])
    if r:
        t_s.append(t); sc.append(r['puntaje']); al.append(r['alerta'])
t_s, sc, al = np.array(t_s), np.array(sc), np.array(al)
a, b = max(0, s['ini'] - 400), min(len(s['x']), s['fin'] + 250)
fig, axs = plt.subplots(2, 1, figsize=(6.6, 3.9), sharex=True, gridspec_kw={'hspace': 0.12})
tt = np.arange(a, b)
axs[0].plot(tt, d['ses'][s['sesion']][a:b, C.IX['COOLANT_TEMPERATURE']], color=GRIS, lw=1.4, label='Sesión original')
axs[0].plot(tt, s['x'][a:b, C.IX['COOLANT_TEMPERATURE']], color=NAVY, lw=1.8, label='Con falla inyectada')
axs[0].set_ylabel('Temp. refrigerante (°C)'); axs[0].legend(frameon=False, fontsize=8.5, loc='upper left')
f = (t_s >= a) & (t_s < b)
axs[1].plot(t_s[f], sc[f], color=NAVY, lw=1.6)
axs[1].axhline(det.umbral, color=NAR, ls='--', lw=1.1); axs[1].text(a + 5, det.umbral * 1.15, 'umbral τ', fontsize=8.5, color='#333')
alz = al & (t_s >= s['ini'])
if alz.any():
    t_al = t_s[np.argmax(alz)]
    axs[1].axvline(t_al, color='#333', lw=1); axs[1].text(t_al + 8, 0.17, 'alerta a los %d s\ndel inicio de la falla' % (t_al - s['ini']), fontsize=8.5, color='#333', ha='left')
axs[1].set_xlim(a, b)
axs[1].set_yscale('log'); axs[1].set_ylabel('Puntaje s'); axs[1].set_xlabel('Tiempo de la sesión (s)')
for ax in axs:
    ax.axvspan(s['ini'], s['fin'], color='#F1E3D6', alpha=0.7, lw=0, zorder=0)
axs[0].text(s['fin'] + 8, 104, 'intervalo\nde falla', ha='left', fontsize=8.5, color='#7A4A1E')
fig.savefig(os.path.join(C.FIG, 'fig_alerta.png'), dpi=220, bbox_inches='tight'); plt.close(fig)
print('ok', s['sesion'], s['ini'], s['fin'])
