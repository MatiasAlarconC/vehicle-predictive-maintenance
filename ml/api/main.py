# ml/api/main.py

from fastapi import FastAPI, HTTPException
from .schemas import PredictionRequest, PredictionResponse, HealthResponse, ExplanationItem
from .model_loader import model_artifacts
import pandas as pd
import numpy as np
import random


def _extract_feature_name(feature: str, feature_names: list[str]) -> str:
    """
    Extrae el nombre legible de una característica LIME.
    """
    for feature_name in sorted(feature_names, key=len, reverse=True):
        if feature_name in feature:
            return feature_name

    separators = [" <= ", " >= ", " < ", " > ", " = "]
    for separator in separators:
        if separator in feature:
            parts = feature.split(separator, 1)
            if len(parts) > 1 and parts[1].strip() in feature_names:
                return parts[1].strip()
            return parts[0].strip()
    return feature.strip()

# Crear la aplicación FastAPI
app = FastAPI(
    title="API de Mantenimiento Predictivo Vehicular",
    description="Una API para predecir anomalías en vehículos usando un modelo XGBoost.",
    version="1.0.0"
)

@app.on_event("startup")
async def startup_event():
    """
    Evento que se ejecuta al iniciar la API para asegurar que los modelos estén cargados.
    """
    if model_artifacts.model is None:
        raise RuntimeError("El modelo y sus artefactos no pudieron ser cargados. La API no puede iniciar.")

@app.get("/health", response_model=HealthResponse, tags=["Monitoring"])
async def health_check():
    """
    Endpoint de salud para verificar el estado de la API y el modelo cargado.
    """
    return {
        "status": "ok",
        "model": "XGBoost",
        "dataset": "Hyundai Maintenance"
    }

def _explain_prediction(input_scaled):
    """
    Función interna para obtener la explicación LIME.
    """
    explanation = model_artifacts.lime_explainer.explain_instance(
        input_scaled[0],
        model_artifacts.model.predict_proba,
        num_features=3
    )
    
    output = []
    for feature, weight in explanation.as_list(label=1): # Explicaciones para la clase 'Anomalía'
        # Simplificar el nombre de la característica para la UI
        # Ej: 'engine_temp <= 95.00' -> 'engine_temp'
        clean_feature_name = _extract_feature_name(feature, model_artifacts.feature_names)
        
        direction = "aumenta riesgo" if weight > 0 else "reduce riesgo"
        
        output.append(ExplanationItem(
            variable=clean_feature_name,
            contribution=abs(weight),
            direction=direction
        ))
    return output

def _preprocess_input(request: PredictionRequest) -> np.ndarray:
    """
    Preprocesa los datos de entrada para que coincidan con el formato de entrenamiento.
    """
    # Convertir el request a un diccionario y luego a un DataFrame
    input_data = request.dict()
    input_df = pd.DataFrame([input_data])

    # One-Hot Encoding manual
    input_df['maintenance_type_Repair'] = 1 if input_data['maintenance_type'] == 'Repair' else 0
    input_df['maintenance_type_Routine Maintenance'] = 1 if input_data['maintenance_type'] == 'Routine Maintenance' else 0
    
    # Eliminar la columna original de tipo de mantenimiento
    input_df = input_df.drop('maintenance_type', axis=1)
    
    # Reordenar las columnas para que coincidan con el orden de `feature_names`
    input_df = input_df.reindex(columns=model_artifacts.feature_names, fill_value=0)
    
    # Escalar los datos
    scaled_input = model_artifacts.scaler.transform(input_df)
    
    return scaled_input

@app.post("/predict", response_model=PredictionResponse, tags=["Prediction"])
async def predict(request: PredictionRequest):
    """
    Recibe los datos de un vehículo, realiza una predicción de anomalía y devuelve
    la probabilidad, la decisión y una explicación del resultado.
    """
    try:
        # Preprocesar la entrada
        scaled_input = _preprocess_input(request)
        
        # Realizar la predicción
        probability = model_artifacts.model.predict_proba(scaled_input)[0, 1]
        prediction = bool(probability > 0.5) # Umbral de decisión
        
        # Obtener la explicación
        explanation = _explain_prediction(scaled_input)
        
        return PredictionResponse(
            anomaly=prediction,
            probability=probability,
            explanation=explanation
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error durante la predicción: {str(e)}")

@app.get("/demo", response_model=PredictionResponse, tags=["Prediction"])
async def demo_prediction():
    """
    Genera una observación aleatoria y realista para una demostración rápida.
    Útil para que la app Flutter pueda probar la conexión en modo demo.
    """
    # Generar datos aleatorios realistas
    demo_data = PredictionRequest(
        engine_temp=random.uniform(70.0, 115.0),
        brake_pad_thickness=random.uniform(1.0, 15.0),
        tire_pressure=random.uniform(28.0, 40.0),
        maintenance_type=random.choice(['Routine Maintenance', 'Component Replacement', 'Repair'])
    )
    
    try:
        # Reutilizar la lógica de predicción
        return await predict(demo_data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error durante la predicción de demostración: {str(e)}")
