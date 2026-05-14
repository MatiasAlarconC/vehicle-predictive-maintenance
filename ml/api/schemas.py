# ml/api/schemas.py

from pydantic import BaseModel
from typing import List, Dict, Any

class PredictionRequest(BaseModel):
    """
    Esquema para los datos de entrada de una solicitud de predicción.
    """
    engine_temp: float
    brake_pad_thickness: float
    tire_pressure: float
    maintenance_type: str # 'Routine Maintenance', 'Component Replacement', 'Repair'

class ExplanationItem(BaseModel):
    """
    Esquema para un único item en la explicación LIME.
    """
    variable: str
    contribution: float
    direction: str

class PredictionResponse(BaseModel):
    """
    Esquema para la respuesta de una predicción.
    """
    anomaly: bool
    probability: float
    explanation: List[ExplanationItem]

class HealthResponse(BaseModel):
    """
    Esquema para la respuesta del endpoint de salud.
    """
    status: str
    model: str
    dataset: str


class ObdLiveResponse(BaseModel):
    """
    Esquema para una lectura OBD-II en vivo o simulada desde la API.
    """
    timestamp: str
    rpm: float
    engine_temp: float
    speed: float
    engine_load: float
    voltage: float
    maf: float
    brake_pad_thickness: float
    tire_pressure: float
    maintenance_type: str


class HistoryItem(BaseModel):
    """
    Registro resumido de una predicción realizada por la API.
    """
    timestamp: str
    anomaly: bool
    probability: float


class HistoryResponse(BaseModel):
    """
    Respuesta del historial de predicciones recientes.
    """
    items: List[HistoryItem]
