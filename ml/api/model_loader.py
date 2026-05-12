# ml/api/model_loader.py

import joblib
import os
import lime.lime_tabular
import numpy as np

class ModelLoader:
    """
    Clase singleton para cargar y mantener los artefactos del modelo en memoria.
    """
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            print("Cargando artefactos del modelo por primera vez...")
            cls._instance = super(ModelLoader, cls).__new__(cls)
            cls._instance.load_artifacts()
        return cls._instance

    def load_artifacts(self):
        """
        Carga el modelo, el escalador, los nombres de las características y el explicador LIME.
        """
        base_path = os.path.join(os.path.dirname(__file__), '..', 'models')
        processed_data_path = os.path.join(os.path.dirname(__file__), '..', 'data', 'processed')
        
        try:
            self.model = joblib.load(os.path.join(base_path, 'xgboost_model.pkl'))
            self.scaler = joblib.load(os.path.join(base_path, 'scaler.pkl'))
            self.feature_names = joblib.load(os.path.join(base_path, 'feature_names.pkl'))
            
            # Cargar datos de entrenamiento para el explicador LIME
            X_train = np.load(os.path.join(processed_data_path, 'X_train.npy'))
            
            # Crear el explicador LIME
            self.lime_explainer = lime.lime_tabular.LimeTabularExplainer(
                training_data=X_train,
                feature_names=self.feature_names,
                class_names=['Normal', 'Anomalía'],
                mode='classification',
                random_state=42
            )
            print("Todos los artefactos del modelo han sido cargados exitosamente.")
        except FileNotFoundError as e:
            print(f"Error crítico: No se pudo cargar un artefacto del modelo: {e}")
            print("Asegúrate de que los notebooks de entrenamiento se hayan ejecutado correctamente.")
            self.model = None
            self.scaler = None
            self.feature_names = None
            self.lime_explainer = None

# Instancia global para ser importada por la API
model_artifacts = ModelLoader()
