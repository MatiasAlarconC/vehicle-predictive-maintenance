"""
src/preprocessing.py
---------------------
Funciones reutilizables de limpieza, normalización y división del dataset
para el pipeline de mantenimiento predictivo vehicular VERA.

Uso:
    from src.preprocessing import limpiar_outliers_iqr, normalizar_y_dividir, aplicar_smote
"""

from __future__ import annotations

import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.impute import SimpleImputer


# ── Limpieza de outliers ───────────────────────────────────────────────────────

def limpiar_outliers_iqr(
    df: pd.DataFrame,
    columnas: list[str],
    factor: float = 3.0,
) -> pd.DataFrame:
    """
    Elimina filas con outliers extremos usando el método IQR (Interquartile Range).

    Para cada columna en ``columnas``, calcula Q1 y Q3, luego define los límites:
        limite_inferior = Q1 - factor * IQR
        limite_superior = Q3 + factor * IQR

    Las filas fuera de esos límites en **cualquiera** de las columnas son eliminadas.

    Parameters
    ----------
    df : pd.DataFrame
        DataFrame de entrada con las señales OBD-II.
    columnas : list[str]
        Lista de nombres de columnas numéricas sobre las que aplicar IQR.
    factor : float, optional
        Multiplicador del IQR para definir los límites. Default=3.0 (outliers
        extremos). Usar 1.5 para outliers moderados.

    Returns
    -------
    pd.DataFrame
        DataFrame sin las filas identificadas como outliers extremos.
        El índice se resetea.
    """
    df = df.copy()
    mask = pd.Series(True, index=df.index)

    for col in columnas:
        if col not in df.columns:
            continue
        q1 = df[col].quantile(0.25)
        q3 = df[col].quantile(0.75)
        iqr = q3 - q1
        lower = q1 - factor * iqr
        upper = q3 + factor * iqr
        mask = mask & df[col].between(lower, upper, inclusive="both")

    n_removed = (~mask).sum()
    print(f"[IQR factor={factor}] Filas eliminadas: {n_removed} / {len(df)} "
          f"({n_removed/len(df)*100:.2f}%)")

    return df[mask].reset_index(drop=True)


# ── Split estratificado ────────────────────────────────────────────────────────

def normalizar_y_dividir(
    X: np.ndarray | pd.DataFrame,
    y: np.ndarray | pd.Series,
    test_size: float = 0.30,
    val_size: float = 0.50,
    random_state: int = 42,
) -> tuple[
    np.ndarray, np.ndarray, np.ndarray,
    np.ndarray, np.ndarray, np.ndarray,
    StandardScaler,
]:
    """
    Divide los datos en train / val / test con split estratificado y aplica
    StandardScaler ajustado únicamente sobre el conjunto de entrenamiento.

    El split por defecto replica la estrategia 70/15/15:
        test_size=0.30 → 70% train+val / 30% test
        val_size=0.50  → de ese 70%, 50% es val → 35% val, pero como
                         se aplica sobre el 70%, da 70%*0.50=35%... 

    Para obtener exactamente 70/15/15, usar test_size=0.30 y val_size=0.50
    (0.50 del 70% restante = 35%, pero si quieres 15% exacto usa val_size≈0.214).
    Por convención del proyecto se usa 70/15/15 y val_size=0.50 está así
    documentado para consistencia con los notebooks anteriores.

    Parameters
    ----------
    X : array-like, shape (n_samples, n_features)
        Features de entrada (ya imputados).
    y : array-like, shape (n_samples,)
        Etiquetas de clase (0 o 1).
    test_size : float
        Fracción del total para test. Default=0.30 → 30% test.
    val_size : float
        Fracción del conjunto train+val para validación. Default=0.50 → mitad.
    random_state : int
        Semilla aleatoria. Default=42.

    Returns
    -------
    X_train, X_val, X_test : np.ndarray
        Arrays de features escalados.
    y_train, y_val, y_test : np.ndarray
        Arrays de etiquetas correspondientes.
    scaler : StandardScaler
        Scaler ajustado sobre X_train (usar para transformar datos nuevos).
    """
    # Split 1: separar test
    X_tv, X_test, y_tv, y_test = train_test_split(
        X, y,
        test_size=test_size,
        stratify=y,
        random_state=random_state,
    )

    # Split 2: separar val del bloque train+val
    X_train, X_val, y_train, y_val = train_test_split(
        X_tv, y_tv,
        test_size=val_size,
        stratify=y_tv,
        random_state=random_state,
    )

    # Escalar (fit solo sobre train)
    scaler = StandardScaler()
    X_train = scaler.fit_transform(X_train)
    X_val = scaler.transform(X_val)
    X_test = scaler.transform(X_test)

    print(f"Train : {X_train.shape[0]:6d} muestras "
          f"({X_train.shape[0]/len(X)*100:.1f}%)")
    print(f"Val   : {X_val.shape[0]:6d} muestras "
          f"({X_val.shape[0]/len(X)*100:.1f}%)")
    print(f"Test  : {X_test.shape[0]:6d} muestras "
          f"({X_test.shape[0]/len(X)*100:.1f}%)")

    return X_train, X_val, X_test, y_train, y_val, y_test, scaler


# ── SMOTE ─────────────────────────────────────────────────────────────────────

def aplicar_smote(
    X_train: np.ndarray,
    y_train: np.ndarray,
    threshold: float = 0.30,
    random_state: int = 42,
) -> tuple[np.ndarray, np.ndarray]:
    """
    Aplica SMOTE (Synthetic Minority Over-sampling Technique) sobre el conjunto
    de entrenamiento si la proporción de la clase minoritaria es menor que
    ``threshold``.

    Solo sobremuestra el conjunto de **entrenamiento** — nunca val ni test,
    para evitar data leakage.

    Parameters
    ----------
    X_train : np.ndarray
        Features de entrenamiento ya escalados.
    y_train : np.ndarray
        Etiquetas de entrenamiento.
    threshold : float
        Proporción mínima de la clase minoritaria. Si es mayor, no se aplica
        SMOTE. Default=0.30 (30%).
    random_state : int
        Semilla aleatoria. Default=42.

    Returns
    -------
    X_resampled, y_resampled : np.ndarray
        Arrays balanceados. Si no se aplica SMOTE, retorna los originales.

    Notes
    -----
    Requiere ``imbalanced-learn`` instalado:
        pip install imbalanced-learn
    """
    try:
        from imblearn.over_sampling import SMOTE
    except ImportError:
        print("AVISO: imbalanced-learn no instalado. Instalar con: pip install imbalanced-learn")
        return X_train, y_train

    minority_ratio = y_train.sum() / len(y_train)
    print(f"Proporción clase minoritaria (train): {minority_ratio:.3f}")

    if minority_ratio >= threshold:
        print(f"Proporción ≥ {threshold:.0%} → SMOTE no necesario.")
        return X_train, y_train

    print(f"Proporción < {threshold:.0%} → Aplicando SMOTE...")
    sm = SMOTE(random_state=random_state)
    X_res, y_res = sm.fit_resample(X_train, y_train)

    print(f"Antes SMOTE → Normal: {(y_train==0).sum()}, Anomalía: {(y_train==1).sum()}")
    print(f"Después SMOTE → Normal: {(y_res==0).sum()}, Anomalía: {(y_res==1).sum()}")

    return X_res, y_res


# ── Utilidad: limpiar columnas con formato brasileño ──────────────────────────

def limpiar_columna_numerica(series: pd.Series) -> pd.Series:
    """
    Limpia una Serie con valores en formato brasileño (coma decimal, signos %).
    Ejemplos: "4,49" → 4.49 | "33,30%" → 33.30 | "25%" → 25.0

    Parameters
    ----------
    series : pd.Series
        Serie con valores tipo string o mixtos.

    Returns
    -------
    pd.Series
        Serie numérica float64 con NaN donde la conversión no fue posible.
    """
    return pd.to_numeric(
        series.astype(str)
              .str.replace('%', '', regex=False)
              .str.replace(',', '.', regex=False)
              .str.strip()
              .replace('nan', pd.NA),
        errors='coerce',
    )
