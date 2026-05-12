# Vehicle Predictive Maintenance

Proyecto de tesis universitaria: aplicación de mantenimiento predictivo vehicular usando Machine Learning sobre datos OBD-II simulados.

## Estructura del Repositorio

```
vehicle-predictive-maintenance/
├── app/          ← App Flutter (iOS + Android)
├── ml/           ← Notebooks ML + modelos entrenados + API FastAPI
└── README.md
```

---

## app/ — Aplicación Flutter

App móvil premium estilo dashboard automotriz (dark theme, BMW/Audi aesthetic).

### Stack
- **Flutter** + Provider para state management
- **GoRouter** para navegación con guards de autenticación
- **Clerk** (`clerk_auth`) para autenticación email/password
- **fl_chart** para gráficos en tiempo real
- **CustomPainter** para gauges, health meter y siluetas de autos

### Pantallas
| Pantalla | Ruta | Descripción |
|---|---|---|
| Splash | `/` | Animación inicial, espera inicialización de Clerk |
| Login | `/login` | Sign in / Sign up con verificación de email |
| Selección de vehículo | `/select-vehicle` | Marca, modelo, año, color |
| Dashboard | `/dashboard` | Health meter, stats OBD-II en tiempo real |
| Diagnóstico/Predicción | `/predict` | Resultado ML + explicación LIME |

### Autenticación (Clerk)
La app usa [Clerk](https://clerk.com) para autenticación. Configuración en:
`app/lib/core/constants/clerk_config.dart`

```dart
const kClerkPublishableKey = 'pk_test_...'; // Tu clave del dashboard de Clerk
```

Para obtener tu clave: [dashboard.clerk.com](https://dashboard.clerk.com) → API Keys

### Modos de operación
- **MODO DEMO** (default): datos OBD-II simulados con `MockObdService`, predicciones ML fake
- **MODO PRODUCCIÓN**: se conecta por HTTP al Raspberry Pi con FastAPI (configurable en Settings)

### Correr la app

```bash
cd app
flutter pub get
flutter run
```

---

## ml/ — Machine Learning

Notebooks de entrenamiento + API FastAPI lista para Raspberry Pi.

### Dataset
**Hyundai Cars Maintenance Dataset** (Mendeley Data)
- URL: https://data.mendeley.com/datasets/zm45zhp8z5/1
- Colocar en: `ml/data/hyundai_maintenance.csv`
- 1,100 filas, 5 columnas: Engine Temperature, Brake Pad Thickness, Tire Pressure, Maintenance Type, Anomaly Indication

### Modelos entrenados (ya incluidos en `ml/models/`)
| Modelo | Accuracy | F1-Score |
|---|---|---|
| Random Forest | 0.5515 | 0.5747 |
| XGBoost | 0.5636 | 0.5765 |

### Notebooks (ejecutar en orden)
```
01_exploratory_analysis.ipynb   → EDA, distribuciones, correlaciones
02_preprocessing.ipynb          → Encoding, scaling, split 70/15/15
03_baseline_models.ipynb        → RF + XGBoost, métricas, ROC
04_explainability_shap_lime.ipynb → SHAP global + LIME local
```

### API FastAPI

```bash
cd ml
pip install -r requirements.txt
uvicorn ml.api.main:app --reload --port 8000
```

**Endpoints:**
- `POST /predict` — predicción con explicación LIME
- `GET /demo` — predicción con datos aleatorios (usado por la app en modo demo)
- `GET /health` — estado de la API

**Para Raspberry Pi:**
```bash
uvicorn ml.api.main:app --host 0.0.0.0 --port 8000
```

---

## Requisitos

- Flutter 3.x + Dart 3.x
- Python 3.8+
- Android Studio / Xcode para emuladores
- Cuenta en [clerk.com](https://clerk.com) (plan gratuito)
