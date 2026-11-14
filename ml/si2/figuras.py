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

# ---- Figura: clasificadores
T = pd.read_csv(os.path.join(C.RES, 'e2_clasificadores.csv')).sort_values('exactitud')
R = json.load(open(os.path.join(C.RES, 'e1_e2_resumen.json')))
fig, ax = plt.subplots(figsize=(6.6, 3.3))
y = np.arange(len(T))
ax.hlines(y, T.ic_inf, T.ic_sup, color=NAVY, lw=2)
ax.plot(T.exactitud, y, 'o', color=NAVY, ms=6, mec='white', mew=1)
ax.axvline(R['cota_si_f2_f3_indistinguibles'], color=NAR, lw=1.2, ls='--')
ax.text(R['cota_si_f2_f3_indistinguibles'] - 0.006, 0.2, 'cota 0.750', color='#333', ha='right', fontsize=9)
ax.set_yticks(y); ax.set_yticklabels(T.modelo)
for yy, v in zip(y, T.exactitud):
    ax.text(0.772, yy, '%.3f' % v, va='center', fontsize=9, color='#333')
ax.set_xlim(0.36, 0.80); ax.set_xlabel('Exactitud en prueba (IC 95 % por bootstrap)')
ax.grid(axis='x', color='#E3E6EA', lw=0.6); ax.set_axisbelow(True)
fig.savefig(os.path.join(C.FIG, 'fig_clasificadores.png'), dpi=220, bbox_inches='tight'); plt.close(fig)

# ---- Figura: curvas ROC de los detectores
M = np.load(os.path.join(C.RES, 'meta.npz'), allow_pickle=True)
pos = M['meta_te'][:, 3] >= C.W // 2
D = pd.read_csv(os.path.join(C.RES, 'e5_detectores.csv'))
fig, ax = plt.subplots(figsize=(4.6, 4.0))
orden = D.sort_values('test_auc_roc')
for _, r in orden.iterrows():
    s = EV.puntajes(r['clave'])[0]
    yv = np.r_[np.zeros(len(s['test'])), np.ones(pos.sum())]
    fpr, tpr, _ = roc_curve(yv, np.r_[s['test'], s['ftest'][pos]])
    col, lw, z = (NAVY, 2.2, 5) if r['clave'] == 'ae_conv' else ((NAR, 1.6, 4) if r['clave'] == 'ocsvm' else (GRIS, 1.1, 2))
    ax.plot(fpr, tpr, color=col, lw=lw, zorder=z, label='%s (%.3f)' % (r['detector'].replace(' (95 % de varianza)', ''), r['test_auc_roc']),
            ls='-' if r['clave'] in ('ae_conv', 'ocsvm') else {'pca': '--', 'iforest': ':', 'ae_denso': '-.', 'ae_lstm32': '-', 'ae_lstm64': (0, (5, 1))}[r['clave']])
ax.plot([0, 1], [0, 1], color='#CCC', lw=0.8)
ax.set_xlabel('Tasa de falsos positivos'); ax.set_ylabel('Tasa de verdaderos positivos')
h, l = ax.get_legend_handles_labels()
ax.legend(h[::-1], l[::-1], frameon=False, fontsize=8.3, loc='lower right', title='Detector (AUC-ROC)', title_fontsize=8.5)
fig.savefig(os.path.join(C.FIG, 'fig_roc.png'), dpi=220, bbox_inches='tight'); plt.close(fig)

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
