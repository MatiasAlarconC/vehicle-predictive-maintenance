# Proyecto de Mantenimiento Predictivo Vehicular - Componente de Machine Learning

Este directorio (`ml/`) contiene todos los artefactos relacionados con el entrenamiento, evaluación y despliegue de los modelos de Machine Learning para el proyecto de tesis.

## Estructura de Carpetas

```
ml/
├── data/
│   └── hyundai_maintenance.csv     # Dataset (debe ser descargado)
├── notebooks/
│   ├── 01_exploratory_analysis.ipynb
│   ├── 02_preprocessing.ipynb
│   ├── 03_baseline_models.ipynb
│   └── 04_explainability_shap_lime.ipynb
├── models/
│   └── (Aquí se guardan los modelos entrenados)
├── api/
│   ├── main.py                     # API FastAPI para inferencia
│   ├── model_loader.py
│   └── schemas.py
├── requirements.txt                # Dependencias de Python
└── README.md                       # Este archivo
```

## Métricas de los Modelos Base

Las métricas obtenidas en `03_baseline_models.ipynb` para los modelos base son las siguientes:

| Modelo | Accuracy | Precision | Recall | F1-score |
| --- | ---: | ---: | ---: | ---: |
| Random Forest | 0.5515 | 0.5435 | 0.6098 | 0.5747 |
| XGBoost | 0.5636 | 0.5568 | 0.5976 | 0.5765 |

## Guía de Inicio Rápido

### 1. Instalar Dependencias

Asegúrate de tener Python 3.8+ instalado. Luego, instala todas las librerías necesarias usando pip:

```bash
pip install -r requirements.txt
```

### 2. Descargar el Dataset

El modelo se entrena con el "Hyundai Cars Maintenance Dataset".

1.  **Descarga el archivo CSV** desde Mendeley Data:
    [https://data.mendeley.com/datasets/zm45zhp8z5/1](https://data.mendeley.com/datasets/zm45zhp8z5/1)
2.  **Mueve y renombra** el archivo descargado a la siguiente ruta:
    `ml/data/hyundai_maintenance.csv`

**Nota:** El directorio `ml/data` está incluido en el `.gitignore`, por lo que el dataset no será subido al repositorio.

### 3. Ejecutar los Notebooks de Jupyter

Para entrenar los modelos y generar los artefactos necesarios, ejecuta los notebooks en el siguiente orden:

1.  `01_exploratory_analysis.ipynb`: Para entender la distribución y características de los datos.
2.  `02_preprocessing.ipynb`: Para limpiar, transformar y dividir los datos.
3.  `03_baseline_models.ipynb`: Para entrenar y evaluar los modelos de Random Forest y XGBoost.
4.  `04_explainability_shap_lime.ipynb`: Para analizar la explicabilidad de los modelos.

Puedes iniciar el servidor de Jupyter con el comando:
```bash
jupyter notebook
```

### 4. Correr la API de Inferencia

Una vez que los modelos han sido entrenados y guardados (paso 3), puedes levantar la API de FastAPI para servir las predicciones.

Desde la raíz del proyecto (`vehicle-predictive-maintenance/`), ejecuta:

```bash
uvicorn ml.api.main:app --reload --port 8000
```

La API estará disponible en `http://127.0.0.1:8000`. Puedes ver la documentación interactiva en `http://127.0.0.1:8000/docs`.

### Uso en Producción (Raspberry Pi)

Para desplegar la API en un dispositivo como una Raspberry Pi, el proceso es el mismo:

1.  Clona el repositorio.
2.  Instala las dependencias con `pip install -r ml/requirements.txt`.
3.  Asegúrate de que los modelos entrenados (`.pkl`) estén en la carpeta `ml/models/`.
4.  Ejecuta el mismo comando `uvicorn` para iniciar el servidor.
```bash
uvicorn ml.api.main:app --host 0.0.0.0 --port 8000
```
Usar `--host 0.0.0.0` permite que la API sea accesible desde otros dispositivos en la misma red.
