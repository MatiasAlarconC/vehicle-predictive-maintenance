"""Utilidades comunes de los experimentos SI2 (rutas, carga de datos, ventanas e inyección de fallas)."""
import glob
import json
import os

import numpy as np
import pandas as pd

SEED = 42
BASE = os.path.dirname(os.path.abspath(__file__))
DATA = os.environ.get('VERA_DATA', os.path.join(BASE, 'data'))
RES = os.path.join(BASE, 'results')
FIG = os.path.join(BASE, 'figures')
MOD = os.path.join(BASE, 'models')
for d in (RES, FIG, MOD):
    os.makedirs(d, exist_ok=True)

# ---------------------------------------------------------------- EngineFaultDB
EF_FEATS = ['MAP', 'TPS', 'Force', 'Power', 'RPM', 'Consumption L/H', 'Consumption L/100KM',
            'Speed', 'CO', 'HC', 'CO2', 'O2', 'Lambda', 'AFR']


def load_enginefaultdb():
    df = pd.read_csv(os.path.join(DATA, 'EngineFaultDB', 'EngineFaultDB_Final.csv'))
    # Los registros estan ordenados por clase y, dentro de cada clase, en bloques de ~1,000
    # registros consecutivos tomados en un mismo punto de operacion.
    pos = df.groupby('Fault').cumcount()
    n_cls = df.groupby('Fault')['Fault'].transform('size')
    blk = np.minimum(pos // 1000, np.round(n_cls / 1000).astype(int) - 1)
    df['bloque'] = df['Fault'].astype(str) + '_' + blk.astype(str)
    df['pos'] = pos
    return df


# ---------------------------------------------------------------- carOBD
PIDS = ['ENGINE_RPM', 'VEHICLE_SPEED', 'THROTTLE', 'ENGINE_LOAD', 'COOLANT_TEMPERATURE',
        'LONG_TERM_FUEL_TRIM_BANK_1', 'SHORT_TERM_FUEL_TRIM_BANK_1', 'INTAKE_MANIFOLD_PRESSURE',
        'INTAKE_AIR_TEMP', 'TIMING_ADVANCE', 'CATALYST_TEMPERATURE_BANK1_SENSOR1', 'CONTROL_MODULE_VOLTAGE']
PID_ES = ['RPM', 'Velocidad', 'Acelerador', 'Carga del motor', 'Temp. refrigerante', 'LTFT', 'STFT', 'MAP',
          'Temp. aire admisión', 'Avance de encendido', 'Temp. catalizador', 'Voltaje']
IX = {p: i for i, p in enumerate(PIDS)}
W, STEP = 60, 5


def load_carobd():
    """Devuelve dict sesion -> matriz (T, 12) y dict sesion -> modo."""
    ses, modo = {}, {}
    for f in sorted(glob.glob(os.path.join(DATA, 'carOBD', 'obdiidata', '*.csv'))):
        d = pd.read_csv(f, skipinitialspace=True, index_col=False)
        d.columns = [c.replace(' ()', '').strip() for c in d.columns]
        x = d[PIDS].apply(pd.to_numeric, errors='coerce').ffill().bfill()
        name = os.path.basename(f)[:-4]
        ses[name] = x.values.astype(np.float32)
        modo[name] = ''.join(c for c in name if not c.isdigit())
    return ses, modo


def split_sesiones(modo):
    from sklearn.model_selection import train_test_split
    names = sorted(modo)
    m = [modo[n] for n in names]
    rest, test = train_test_split(names, test_size=20, random_state=SEED, stratify=m)
    train, val = train_test_split(rest, test_size=20, random_state=SEED, stratify=[modo[n] for n in rest])
    return sorted(train), sorted(val), sorted(test)


def ventanas(x):
    """x (T, F) -> (n, W, F) y el indice final (exclusivo) de cada ventana."""
    ends = np.arange(W, len(x) + 1, STEP)
    return np.stack([x[e - W:e] for e in ends]), ends


# ---------------------------------------------------------------- inyeccion de fallas
ESCENARIOS = {
    'sobrecalentamiento': dict(nombre='Sobrecalentamiento', senales=['COOLANT_TEMPERATURE'], peso=3),
    'falla_carga': dict(nombre='Falla de carga (alternador)', senales=['CONTROL_MODULE_VOLTAGE'], peso=3),
    'mezcla_pobre': dict(nombre='Mezcla pobre (fuga de vacío)',
                         senales=['LONG_TERM_FUEL_TRIM_BANK_1', 'SHORT_TERM_FUEL_TRIM_BANK_1', 'INTAKE_MANIFOLD_PRESSURE'], peso=2),
    'ralenti_inestable': dict(nombre='Ralentí inestable (fallo de encendido)',
                              senales=['ENGINE_RPM', 'SHORT_TERM_FUEL_TRIM_BANK_1'], peso=2),
    'sesgo_map': dict(nombre='Sesgo del sensor MAP', senales=['INTAKE_MANIFOLD_PRESSURE'], peso=1),
    'termostato_abierto': dict(nombre='Termostato abierto', senales=['COOLANT_TEMPERATURE'], peso=1),
    'ruido_temp': dict(nombre='Ruido en el sensor de temperatura', senales=['COOLANT_TEMPERATURE'], peso=1),
}
SEVERIDADES = ['leve', 'moderada', 'severa']
DUR_MAX = 300


def intervalo_falla(T, rng):
    ini = int(rng.uniform(0.20, 0.50) * T)
    fin = min(ini + DUR_MAX, T)
    return ini, fin


def inyectar(x, esc, sev, ini, fin, rng):
    """Devuelve una copia de la sesion x con la falla `esc` de severidad `sev` en [ini, fin)."""
    y = x.copy()
    k = SEVERIDADES.index(sev)
    t = np.arange(fin - ini, dtype=np.float32)
    s = slice(ini, fin)
    if esc == 'sobrecalentamiento':
        rate, cap = [(0.08, 104), (0.15, 110), (0.25, 118)][k]
        c = IX['COOLANT_TEMPERATURE']
        y[s, c] = np.maximum(y[s, c], np.minimum(y[s, c] + rate * t, cap))
    elif esc == 'falla_carga':
        dv = [1.1, 1.5, 1.9][k]
        y[s, IX['CONTROL_MODULE_VOLTAGE']] -= dv * (1 - np.exp(-t / 60.0))
    elif esc == 'mezcla_pobre':
        lt, mp = [(6, 3), (10, 5), (16, 8)][k]
        y[s, IX['LONG_TERM_FUEL_TRIM_BANK_1']] += lt
        y[s, IX['SHORT_TERM_FUEL_TRIM_BANK_1']] += lt / 2
        y[s, IX['INTAKE_MANIFOLD_PRESSURE']] += mp
    elif esc == 'ralenti_inestable':
        amp, sg = [(60, 2), (120, 4), (200, 6)][k]
        y[s, IX['ENGINE_RPM']] += amp * np.sin(2 * np.pi * 0.3 * t)
        y[s, IX['SHORT_TERM_FUEL_TRIM_BANK_1']] += rng.normal(0, sg, len(t))
    elif esc == 'sesgo_map':
        y[s, IX['INTAKE_MANIFOLD_PRESSURE']] *= [1.15, 1.25, 1.40][k]
    elif esc == 'termostato_abierto':
        dt = [10, 16, 23][k]
        y[s, IX['COOLANT_TEMPERATURE']] -= dt * (1 - np.exp(-t / 90.0))
    elif esc == 'ruido_temp':
        y[s, IX['COOLANT_TEMPERATURE']] += rng.normal(0, [2, 4, 8][k], len(t))
    else:
        raise ValueError(esc)
    return y


def series_con_falla(ses, nombres, semilla):
    """Genera las series con falla (una por sesion, escenario y severidad)."""
    rng = np.random.default_rng(semilla)
    out = []
    for n in nombres:
        x = ses[n]
        for esc in ESCENARIOS:
            for sev in SEVERIDADES:
                ini, fin = intervalo_falla(len(x), rng)
                out.append(dict(sesion=n, esc=esc, sev=sev, ini=ini, fin=fin, x=inyectar(x, esc, sev, ini, fin, rng)))
    return out


def guardar_json(obj, nombre):
    with open(os.path.join(RES, nombre), 'w') as f:
        json.dump(obj, f, indent=1, ensure_ascii=False, default=float)
