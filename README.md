# Vera — Vehicle Predictive Maintenance App

> **Proyecto de tesis universitaria** · Sistema de mantenimiento predictivo vehicular basado en datos OBD-II, Machine Learning interpretable y una app móvil Flutter de grado producción.

---

## Índice

1. [Resumen del proyecto](#resumen-del-proyecto)
2. [Arquitectura del sistema](#arquitectura-del-sistema)
3. [Estructura del repositorio](#estructura-del-repositorio)
4. [App Flutter — Vera](#app-flutter--vera)
5. [ML — Machine Learning](#ml--machine-learning)
6. [Hoja de ruta](#hoja-de-ruta)
7. [Requisitos de desarrollo](#requisitos-de-desarrollo)

---

## Resumen del proyecto

**Vera** es una aplicación móvil de mantenimiento predictivo vehicular diseñada como proyecto de tesis de pregrado. El sistema combina:

- **Adquisición de datos en tiempo real** vía protocolo OBD-II usando un dongle ELM327 conectado al puerto OBD-II del vehículo.
- **Modelos de Machine Learning** (Random Forest, XGBoost, futuro LSTM/Autoencoder) para predecir fallos antes de que ocurran, con explicaciones interpretables vía SHAP y LIME.
- **App móvil Flutter** que presenta los diagnósticos al usuario con una interfaz tipo cockpit automotriz premium.
- **Backend FastAPI** desplegable en Raspberry Pi 4 para inferencia local sin dependencia de nube.

**Variable objetivo del modelo:** `engine_condition` — clasificación binaria `0=Normal / 1=Anomalía` derivada de señales OBD-II del motor.

---

## Arquitectura del sistema

```
┌─────────────────────────────────────────────────┐
│                   VEHÍCULO                      │
│  Puerto OBD-II  →  ELM327 BT/WiFi  ─────────┐  │
└─────────────────────────────────────────────┼──┘
                                              │ BT/WiFi
                         ┌────────────────────▼──────────────────┐
                         │           RASPBERRY PI 4              │
                         │  python-obd  → lectura raw PIDs       │
                         │  XGBoost/RF  → inferencia ML          │
                         │  FastAPI     → HTTP :8000             │
                         └────────────────────┬──────────────────┘
                                              │ WiFi LAN / Hotspot
                         ┌────────────────────▼──────────────────┐
                         │         APP FLUTTER (Vera)            │
                         │  ApiService   → /predict, /live-obd   │
                         │  DiagnosticsProvider, PredictionProvider│
                         │  Dashboard / History / Settings       │
                         └───────────────────────────────────────┘
```

En **modo demo** (sin hardware), la app genera datos OBD-II simulados internamente.

---

## Estructura del repositorio

```
vehicle-predictive-maintenance/
│
├── app/                              ← App Flutter (iOS + Android + Web)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app/
│   │   │   ├── theme/               ← AppTheme, tokens de color
│   │   │   └── widgets/             ← VeraComponents (design system compartido)
│   │   ├── core/
│   │   │   ├── constants/           ← Clerk config, endpoints
│   │   │   ├── enums/               ← AppMode, VehicleColor, CarBodyType
│   │   │   ├── models/              ← UserVehicle, CarMake, CarModelEntry
│   │   │   ├── providers/           ← Auth, Vehicle, App, Diagnostics, History, Prediction
│   │   │   └── router/              ← AppRouter con guards de auth
│   │   ├── features/
│   │   │   ├── auth/                ← Login, MFA, forgot-password, registro
│   │   │   ├── dashboard/           ← Cockpit principal
│   │   │   ├── diagnostics/         ← Lectura OBD-II en tiempo real
│   │   │   ├── history/             ← Historial de diagnósticos
│   │   │   ├── prediction/          ← Resultado ML + SHAP/LIME
│   │   │   ├── settings/            ← Config servidor, modo, cuenta
│   │   │   ├── splash/              ← Pantalla de carga inicial
│   │   │   └── vehicle/             ← Selección / garage multi-vehículo
│   │   └── services/
│   │       ├── api_service.dart     ← Cliente HTTP → FastAPI
│   │       └── car_image_service.dart ← CDN imagin.studio para renders
│   └── pubspec.yaml
│
├── ml/                               ← Machine Learning
│   ├── data/
│   │   └── cars_hyundai.csv         ← Hyundai Cars Maintenance Dataset
│   ├── notebooks/
│   │   ├── 01_exploratory_analysis.ipynb
│   │   ├── 02_preprocessing.ipynb
│   │   ├── 03_baseline_models.ipynb
│   │   └── 04_explainability_shap_lime.ipynb
│   ├── models/                      ← Artefactos serializados (.joblib)
│   ├── api/
│   │   ├── main.py                  ← FastAPI app
│   │   ├── model_loader.py          ← Carga y caché de modelos
│   │   └── schemas.py               ← Pydantic schemas
│   └── requirements.txt
│
└── README.md
```

---

## App Flutter — Vera

### Stack tecnológico

| Categoría | Librería | Versión |
|---|---|---|
| Estado | `provider` | ^6.1.2 |
| Navegación | `go_router` | ^14.2.7 |
| HTTP | `dio` | ^5.7.0 |
| Auth | `clerk_auth` | ^0.0.15-beta |
| Persistencia | `shared_preferences` | ^2.2.2 |
| Gráficos | `fl_chart` | ^0.68.0 |
| Fuentes | `google_fonts` | ^6.2.1 |
| Imágenes galería | `image_picker` | ^1.1.2 |
| Animaciones | `lottie` | ^3.1.2 |
| SVG | `flutter_svg` | ^2.0.17 |

### Pantallas y flujo de usuario

```
/splash       → init Clerk + auth check
/login        → Sign In | Sign Up | Forgot Password | MFA
/select-vehicle → Selección de marca/modelo/año/color + garage multi-vehículo
/dashboard    → Cockpit: health meter, imagen del auto, métricas live, gráfico
/diagnostics  → Gauges OBD-II completos: RPM, temp, voltaje, velocidad, presión
/predict      → Resultado ML: score, label, top features SHAP/LIME, recomendaciones
/history      → Historial de sesiones con fecha, score, alertas
/settings     → Modo demo/prod, servidor FastAPI, info sistema, cuenta
```

### Autenticación (Clerk)

- Sign-up: SDK `clerk_auth` con verificación de email
- Sign-in: FAPI directo (Dio) con soporte completo de MFA por código de email:
  1. `POST /sign_ins` con identifier
  2. `POST /attempt_first_factor` con password
  3. Si `needs_second_factor` → `prepare_second_factor` (email_code) → `attempt_second_factor`
- Forgot password: SDK `attemptSignIn` con `resetPasswordEmailCode`
- Sign-out: SDK + limpieza de estado manual
- `GoRouter` con `refreshListenable` auto-redirige en cada cambio de estado de auth

### Multi-vehículo (Garage)

`VehicleProvider` persiste lista en `SharedPreferences` bajo `garage_vehicles` (JSON):
- Agregar / eliminar / cambiar vehículo activo
- Migración automática desde formato legacy (clave `selected_vehicle`)
- Cada `UserVehicle`: `make`, `model`, `year`, `color`, `bodyType`, `customImagePath?`
- Si la marca/modelo no está en el catálogo de 200+ modelos → entrada **custom**
- Imagen del vehículo: CDN imagin.studio → fallback por marca → fallback ícono SVG → imagen personalizada (galería)

### Design system

Tokens `AppTheme`:

| Token | Valor |
|---|---|
| `background` | `#000000` |
| `surface` | `#0C0C0C` |
| `primaryColor` | `#03F263` (verde Vera) |
| `textPrimary` | `#FFFFFF` |
| `textSecondary` | `#888888` |
| `textFaint` | `#444444` |
| `dangerColor` | `#FF3B30` |
| `warningColor` | `#FF9500` |

Componentes: `VeraButton`, `VeraFrame`, `VeraRing`, `VeraCornerBrackets`, `VeraDataLine`, `VeraLiveDot`, `VeraCarSvg`, `VeraDivider`, `VeraPromptField`.

### Correr la app

```bash
cd app
flutter pub get
flutter run
```

---

## ML — Machine Learning

### Variable respuesta

```
engine_condition  →  0 = Normal  |  1 = Anomalía / Falla
```

Clasificación binaria supervisada sobre señales OBD-II: RPM, temperatura motor, presión de aceite, presión de combustible, temperatura refrigerante.

### Dataset actual

**Hyundai Cars Maintenance Dataset** · Mendeley Data · DOI: 10.17632/zm45zhp8z5.1  
1,100 registros · 5 variables · target: `Engine_condition` (binario)

### Pipeline de notebooks

```
01_exploratory_analysis.ipynb   → EDA: distribuciones, correlación Pearson, outliers IQR, balance de clases
02_preprocessing.ipynb          → Imputación, OHE, StandardScaler, split estratificado 70/15/15
03_baseline_models.ipynb        → RF + XGBoost, GridSearchCV, métricas, AUC-ROC, matriz de confusión
04_explainability_shap_lime.ipynb → SHAP TreeExplainer (global) + LIME TabularExplainer (local)
```

### Modelos baseline

| Modelo | Accuracy | F1-Score | AUC-ROC |
|---|---|---|---|
| Random Forest | ~68% | ~0.67 | ~0.74 |
| XGBoost | ~71% | ~0.70 | ~0.77 |

> Jovin et al. (2024): 63.1% con KNN en dataset similar — nuestros baselines superan ese umbral.

### API FastAPI

| Endpoint | Descripción |
|---|---|
| `GET /health` | Ping → `{"status": "ok"}` |
| `POST /predict` | Recibe `OBDReading`, retorna score + label + top_features |
| `GET /demo` | Predicción con datos aleatorios |
| `GET /live-obd` | Última lectura ELM327 (producción) |

```bash
cd ml
pip install -r requirements.txt
uvicorn api.main:app --host 0.0.0.0 --port 8000
```

### Arquitectura hardware

```
Auto → Puerto OBD-II → ELM327 → Raspberry Pi 4
                                   ├── python-obd (lectura PIDs)
                                   ├── XGBoost/RF cargado en RAM
                                   └── FastAPI :8000 → App Flutter (WiFi LAN)
```

---

## Hoja de ruta

### Entregable 1 — 30% ✅
- [x] Pipeline EDA → preprocesamiento → RF/XGBoost → SHAP/LIME
- [x] App Flutter completa (auth, garage, dashboard, predicción, historial, ajustes)
- [x] Auth con MFA, reset de contraseña, registro con verificación
- [x] Garage multi-vehículo con imagen personalizada y catálogo 200+ modelos
- [x] API FastAPI lista para Raspberry Pi
- [x] Modo demo funcional para presentaciones sin hardware

### Entregable 2 — 60% ⏳
- [ ] Dataset OBD-II Kaggle (>9,000 registros, time-series)
- [ ] LSTM para secuencias temporales
- [ ] Autoencoder para detección de anomalías no supervisada
- [ ] Comparativa RF vs XGBoost vs LSTM vs Autoencoder
- [ ] Despliegue real en Raspberry Pi con ELM327

### Entregable 3 — 100% ⏳
- [ ] Dataset propio (25–30 vehículos en Lima, ~3 meses)
- [ ] Modelo final entrenado sobre datos propios
- [ ] Validación con mecánicos profesionales
- [ ] App en producción con RPi integrada
- [ ] Paper final

---

## Requisitos de desarrollo

```
Flutter  ≥ 3.19 / Dart  ≥ 3.3
Android SDK ≥ 34 | Xcode ≥ 15
Python ≥ 3.11

# Hardware opcional
Raspberry Pi 4 (2GB+ RAM)
ELM327 v1.5 BT/WiFi
```

| Archivo | Variable | Descripción |
|---|---|---|
| `app/lib/core/constants/clerk_config.dart` | `kClerkPublishableKey` | Publishable key de Clerk |
| Ajustes en app | IP + Puerto | Dirección de la Raspberry Pi en red local |

---

*Flutter 3.x · FastAPI · scikit-learn · XGBoost · SHAP · LIME · Universidad · 2025–2026*
