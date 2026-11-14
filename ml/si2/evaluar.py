"""Evalua los detectores de anomalias: metricas por ventana y por serie, persistencia y atribucion."""
from evaluar_lib import *

filas, detalle, guard = [], {}, {}
for nombre, etiqueta in DET:
    s, r, ebar = puntajes(nombre)
    thr = np.percentile(s['val'], 99)
    res = dict(detector=etiqueta, clave=nombre)
    for part, sano, falla, meta, sid, dur in (('val', 'val', 'fval', M['meta_va'], M['sid_va'], M['dur_va']),
                                              ('test', 'test', 'ftest', M['meta_te'], M['sid_te'], M['dur_te'])):
        pos = meta[:, 3] >= C.W // 2
        y = np.r_[np.zeros(len(s[sano])), np.ones(pos.sum())]
        sc = np.r_[s[sano], s[falla][pos]]
        pr, rc, f1, _ = precision_recall_fscore_support(y, sc > thr, average='binary', zero_division=0)
        res.update({part + '_auc_roc': roc_auc_score(y, sc), part + '_auc_pr': average_precision_score(y, sc),
                    part + '_prevalencia': y.mean(), part + '_precision': pr, part + '_recall': rc, part + '_f1': f1,
                    part + '_fpr': float((s[sano] > thr).mean())})
        for m in PERS:
            S = series(s[sano], sid, s[falla], meta, thr, m)
            res['%s_det_m%d' % (part, m)] = S['det'].mean()
            res['%s_azar_m%d' % (part, m)] = S['azar'].mean()
            res['%s_fa_m%d' % (part, m)] = falsas_por_hora(s[sano], sid, dur, thr, m)
            res['%s_lat_m%d' % (part, m)] = S['latencia'].median()
            detalle[(nombre, part, m)] = S
    ok = [m for m in PERS if res['val_fa_m%d' % m] <= MAX_FA]
    res['m_elegido'] = ok[0] if ok else PERS[-1]
    res['umbral'] = thr
    info = json.load(open(os.path.join(C.RES, 'info_%s.json' % nombre)))
    res['parametros'] = info.get('parametros', np.nan)
    res['epocas'] = info.get('epocas', np.nan)
    res['seg_entrenamiento'] = info.get('segundos', np.nan)
    filas.append(res)
    guard[nombre] = (s, r, ebar, thr)
T = pd.DataFrame(filas)
T.to_csv(os.path.join(C.RES, 'e5_detectores.csv'), index=False)
pd.set_option('display.width', 250)
print(T[['detector', 'val_auc_roc', 'val_auc_pr', 'test_auc_roc', 'test_auc_pr', 'test_precision', 'test_recall', 'test_f1',
         'test_fpr', 'm_elegido', 'parametros']].round(3).to_string())
print(T[['detector'] + ['test_det_m%d' % m for m in PERS] + ['test_azar_m%d' % m for m in PERS] +
        ['test_fa_m%d' % m for m in PERS]].round(3).to_string())
print(T[['detector'] + ['val_det_m%d' % m for m in PERS] + ['val_fa_m%d' % m for m in PERS]].round(3).to_string())

# ---------------------------------------------------------------- modelo elegido en validacion (AUC-PR)
mejor = T.sort_values('val_auc_pr', ascending=False).iloc[0]
nombre, m = mejor['clave'], int(mejor['m_elegido'])
print('ELEGIDO', nombre, 'm =', m)
s, r, ebar, thr = guard[nombre]
resumen = dict(elegido=nombre, m=m, umbral=float(thr), ebar=None if ebar is None else ebar.tolist(),
               n_train=int(M['n_tr']), n_val=int(len(M['sid_va'])), n_test=int(len(M['sid_te'])),
               horas_test=float(sum(M['dur_te']) / 3600), horas_val=float(sum(M['dur_va']) / 3600),
               horas_train=float(sum(M['dur_tr']) / 3600),
               series_test=int(len(np.unique(M['meta_te'][:, 0]))), series_val=int(len(np.unique(M['meta_va'][:, 0]))),
               ventanas_pos_test=int((M['meta_te'][:, 3] >= 30).sum()), ventanas_pos_val=int((M['meta_va'][:, 3] >= 30).sum()))

# persistencia del modelo elegido
pers = [dict(m=k, segundos=(k - 1) * C.STEP, **{c: float(mejor['%s_%s_m%d' % (p, c0, k)])
                                                for p in ('val', 'test') for c0, c in
                                                (('det', p + '_det'), ('azar', p + '_azar'), ('fa', p + '_fa'), ('lat', p + '_lat'))})
        for k in PERS]
pd.DataFrame(pers).to_csv(os.path.join(C.RES, 'e5_persistencia.csv'), index=False)

# deteccion por escenario y severidad (prueba)
S = detalle[(nombre, 'test', m)]
meta = M['meta_te']
pos = meta[:, 3] >= C.W // 2
filas = []
for e, clave in enumerate(ESC):
    f = dict(escenario=C.ESCENARIOS[clave]['nombre'], peso=C.ESCENARIOS[clave]['peso'])
    for k, sev in enumerate(C.SEVERIDADES):
        f[sev] = S[(S.esc == e) & (S.sev == k)]['det'].mean()
    f['total'] = S[S.esc == e]['det'].mean()
    f['latencia_mediana_s'] = S[S.esc == e]['latencia'].median()
    f['recall_ventana'] = float((s['ftest'][pos & (meta[:, 4] == e)] > thr).mean())
    if r is not None:
        sel = pos & (meta[:, 4] == e) & (s['ftest'] > thr)
        orden = np.argsort(-r['ftest'][sel], axis=1)
        f['top1'] = float(np.isin(orden[:, 0], SEN[e]).mean()) if sel.any() else np.nan
        f['top3'] = float(np.array([np.isin(o[:3], SEN[e]).any() for o in orden]).mean()) if sel.any() else np.nan
    filas.append(f)
E = pd.DataFrame(filas)
E.to_csv(os.path.join(C.RES, 'e5_escenarios.csv'), index=False)
print(E.round(3).to_string())
resumen['det_total'] = float(S['det'].mean())
resumen['azar_total'] = float(S['azar'].mean())
resumen['det_por_severidad'] = {sev: float(S[S.sev == k]['det'].mean()) for k, sev in enumerate(C.SEVERIDADES)}
w = PESOS[S['esc'].values]
resumen['det_ponderada'] = float((S['det'] * w).sum() / w.sum())
resumen['latencia_mediana_s'] = float(S['latencia'].median())
if r is not None:
    sel = pos & (s['ftest'] > thr)
    orden = np.argsort(-r['ftest'][sel], axis=1)
    es = meta[sel, 4]
    resumen['top1'] = float(np.mean([orden[i, 0] in SEN[es[i]] for i in range(len(es))]))
    resumen['top3'] = float(np.mean([np.isin(orden[i, :3], SEN[es[i]]).any() for i in range(len(es))]))
    resumen['ventanas_atribucion'] = int(sel.sum())

# bootstrap pareado por sesion de prueba: diferencia de AUC-ROC del elegido frente a cada detector
rng = np.random.default_rng(C.SEED)
sid, ses_f = M['sid_te'], meta[pos, 1]
n_ses = len(np.unique(sid))
idx_s = [np.where(sid == i)[0] for i in range(n_ses)]
idx_f = [np.where(ses_f == i)[0] for i in range(n_ses)]
B = 500
aucs = {d: [] for d, _ in DET}
for b in range(B):
    mu = rng.integers(0, n_ses, n_ses)
    a = np.concatenate([idx_s[i] for i in mu])
    c = np.concatenate([idx_f[i] for i in mu])
    y = np.r_[np.zeros(len(a)), np.ones(len(c))]
    for d, _ in DET:
        sd = guard[d][0]
        aucs[d].append(roc_auc_score(y, np.r_[sd['test'][a], sd['ftest'][pos][c]]))
boot = []
for d, et in DET:
    a = np.array(aucs[d])
    dif = np.array(aucs[nombre]) - a
    boot.append(dict(detector=et, auc_ic_inf=np.percentile(a, 2.5), auc_ic_sup=np.percentile(a, 97.5),
                     dif_media=dif.mean(), dif_ic_inf=np.percentile(dif, 2.5), dif_ic_sup=np.percentile(dif, 97.5),
                     p_boot=float(min(1.0, 2 * min((dif <= 0).mean(), (dif >= 0).mean()))) if d != nombre else np.nan))
pd.DataFrame(boot).to_csv(os.path.join(C.RES, 'e5_bootstrap.csv'), index=False)
print(pd.DataFrame(boot).round(4).to_string())
C.guardar_json(resumen, 'e5_resumen.json')
print(json.dumps({k: v for k, v in resumen.items() if k != 'ebar'}, indent=1, default=float))
