import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# === CARGAR DATOS ===
data = pd.read_csv(
    "/Users/nerealopezcastillo/Desktop/TFG/datos/procesados/iot_traffic_validation_clean.csv",
    sep=";",
    engine="python",
    skiprows=1,
    on_bad_lines="skip"
)

print(data.head())
print("Column names:")
print(data.columns.tolist())

# === LIMPIAR NOMBRES DE COLUMNAS ===
data.columns = data.columns.str.strip()

# === EXTRAER COLUMNAS ===
times = pd.to_numeric(data["Time"], errors="coerce")
sources = data["Source"].astype(str)
lengths = pd.to_numeric(data["Length"], errors="coerce")

# === LIMPIAR FILAS INVÁLIDAS ===
valid = times.notna() & lengths.notna()
times = times[valid].reset_index(drop=True)
sources = sources[valid].reset_index(drop=True)
lengths = lengths[valid].reset_index(drop=True)

data = pd.DataFrame({
    "Time": times,
    "Source": sources,
    "Length": lengths
})

# === PARÁMETRO: tamaño de ventana ===
window_size = 5   # segundos

t_start = data["Time"].min()
t_end = data["Time"].max()

entropy_list = []
dispersion_list = []

# === RECORRER VENTANAS ===
t = t_start

while t < t_end:
    window = data[(data["Time"] >= t) & (data["Time"] < t + window_size)]

    if len(window) == 0:
        t += window_size
        continue

    # === ENTROPÍA ===
    ips = window["Source"]
    counts = ips.value_counts()
    prob = counts / counts.sum()
    entropy = -np.sum(prob * np.log2(prob))

    # === DISPERSIÓN ===
    bytes_data = window["Length"]

    if len(bytes_data) == 0 or np.mean(bytes_data) == 0:
        t += window_size
        continue

    dispersion = np.std(bytes_data) / np.mean(bytes_data)

    entropy_list.append(entropy)
    dispersion_list.append(dispersion)

    t += window_size

print("Entropy values:", entropy_list)
print("Dispersion values:", dispersion_list)

# === DETECTAR ANOMALÍAS ===
mean_e = np.mean(entropy_list)
std_e = np.std(entropy_list)

mean_d = np.mean(dispersion_list)
std_d = np.std(dispersion_list)

anomalies = []

for e, d in zip(entropy_list, dispersion_list):
    if abs(e - mean_e) > std_e or abs(d - mean_d) > std_d:
        anomalies.append(True)
    else:
        anomalies.append(False)

print("Anomalies:", anomalies)

# === GRAFICAR ===
plt.figure()

for e, d, a in zip(entropy_list, dispersion_list, anomalies):
    if a:
        plt.scatter(e, d, color="red")
    else:
        plt.scatter(e, d, color="blue")

plt.xlabel("Entropy")
plt.ylabel("Dispersion")
plt.title("Anomaly Detection (Python)")
plt.grid()
plt.show()