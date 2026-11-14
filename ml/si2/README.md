# Experimentos de Seminario de Investigación II

Código que produce los resultados del artículo. Los datos (EngineFaultDB, carOBD y OBD-II de Barreto) se descargan de sus fuentes públicas a `data/` y no se versionan.

| Script | Qué hace |
|---|---|
| `clasificacion.py` | Cota de exactitud de EngineFaultDB y comparación de once clasificadores con pruebas de Cochran y McNemar |
| `agrupada.py` | Validación agrupada por punto de operación |
| `impacto.py`, `costo_explic.py` | Impacto de las fallas, decisión sensible al costo, SHAP y LIME |
| `detectores.py`, `evaluar.py` | Entrenamiento y evaluación de los detectores de anomalías sobre carOBD |
| `barreto.py` | Validez de los DTC como etiqueta en la flota de Barreto |
| `tflite_sim.py` | Conversión a TensorFlow Lite y verificación con el emulador del ELM327 |
| `detector_en_linea.py`, `elm327.py` | Detector en línea y emulador del adaptador |
| `figuras.py`, `fig_alerta.py` | Figuras del artículo |

`results/` contiene las tablas y resúmenes generados y `models/` el detector convertido que usa la aplicación.
