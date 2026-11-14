"""Exporta un caso de prueba para la aplicacion: lecturas, reconstrucciones del .tflite y resultados esperados."""
import json, os, sys
import numpy as np
import comun as C
import detectores as DT
from detector_en_linea import DetectorEnLinea

d = DT.preparar()
series = C.series_con_falla(d['ses'], d['te'], 11)
s = [x for x in series if x['esc'] == 'sobrecalentamiento' and x['sev'] == 'severa'][0]
a = s['ini'] - 80
x = s['x'][a:a + 220]
det = DetectorEnLinea(os.path.join(C.MOD, 'vera_ae_conv.tflite'), os.path.join(C.MOD, 'vera_config.json'))
esperado = []
for t in range(len(x)):
    r = det.agregar(x[t])
    if r:
        w = np.stack(det.buf)[None].astype(np.float32)
        det.it.set_tensor(det.i_in, w); det.it.invoke()
        rec = det.it.get_tensor(det.i_out)[0]
        esperado.append(dict(muestra=r['t'], puntaje=r['puntaje'], alerta=bool(r['alerta']), senal=r['senales'][0],
                             reconstruccion=[round(float(v), 6) for v in rec.reshape(-1)]))
ses0 = d['ses'][d['te'][0]]
out = dict(lecturas=[[round(float(v), 4) for v in row] for row in x], esperado=esperado,
           sesion_emulador=d['te'][0], primeras_lecturas=[[round(float(v), 4) for v in row] for row in ses0[:5]])
json.dump(out, open(sys.argv[1], 'w'))
print(len(esperado), 'evaluaciones;', sum(e['alerta'] for e in esperado), 'con alerta; sesion emulador', d['te'][0])
