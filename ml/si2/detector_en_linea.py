"""Detector en linea: solo necesita el modelo .tflite y el archivo de configuracion (mismo calculo que la app)."""
import json
from collections import deque

import numpy as np


class DetectorEnLinea:
    def __init__(self, ruta_tflite, ruta_config, hilos=1):
        try:
            from ai_edge_litert.interpreter import Interpreter
        except ImportError:
            import tensorflow as tf
            Interpreter = tf.lite.Interpreter
        self.cfg = json.load(open(ruta_config))
        self.media = np.array(self.cfg['media'], np.float32)
        self.escala = np.array(self.cfg['escala'], np.float32)
        self.ebar = np.array(self.cfg['error_referencia'], np.float32)
        self.umbral, self.m = self.cfg['umbral'], self.cfg['persistencia']
        self.W, self.paso = self.cfg['ventana'], self.cfg['paso']
        self.it = Interpreter(model_path=ruta_tflite, num_threads=hilos)
        self.it.allocate_tensors()
        self.i_in = self.it.get_input_details()[0]['index']
        self.i_out = self.it.get_output_details()[0]['index']
        self.reiniciar()

    def reiniciar(self):
        self.buf = deque(maxlen=self.W)
        self.n, self.racha = 0, 0

    def puntuar(self, ventana):
        """ventana (W, F) ya estandarizada -> (puntaje, cociente por senal)."""
        x = ventana[None].astype(np.float32)
        self.it.set_tensor(self.i_in, x)
        self.it.invoke()
        r = self.it.get_tensor(self.i_out)
        coc = ((x - r) ** 2).mean(1)[0] / self.ebar
        return float(coc.max()), coc

    def agregar(self, lectura):
        """Recibe una lectura (12 valores en unidades fisicas, 1 Hz). Devuelve None o un dict cada `paso` lecturas."""
        self.buf.append((np.asarray(lectura, np.float32) - self.media) / self.escala)
        self.n += 1
        if len(self.buf) < self.W or (self.n - self.W) % self.paso:
            return None
        s, coc = self.puntuar(np.stack(self.buf))
        self.racha = self.racha + 1 if s > self.umbral else 0
        orden = np.argsort(-coc)[:3]
        return dict(t=self.n, puntaje=s, alerta=self.racha >= self.m,
                    senales=[self.cfg['senales'][i] for i in orden], cocientes=[float(coc[i]) for i in orden])
