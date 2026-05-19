from scapy.all import sniff
from collections import Counter
import numpy as np
import matplotlib.pyplot as plt
import time

# === CONFIGURACIÓN ===
WINDOW = 5  # segundos

# Umbrales simples basados en tus resultados previos
ENTROPY_THRESHOLD = 0.8
DISPERSION_THRESHOLD = 0.5

packets_window = []

entropy_values = []
dispersion_values = []
time_values = []
anomaly_values = []

start_time = time.time()


def calculate_entropy(ip_list):
    counts = Counter(ip_list)
    probs = np.array(list(counts.values())) / sum(counts.values())
    return -np.sum(probs * np.log2(probs))


def calculate_dispersion(lengths):
    if len(lengths) == 0 or np.mean(lengths) == 0:
        return 0
    return np.std(lengths) / np.mean(lengths)


def packet_callback(pkt):
    global packets_window

    if "IP" in pkt:
        packets_window.append({
            "src": pkt["IP"].src,
            "len": len(pkt)
        })


def process_window():
    global packets_window

    if len(packets_window) == 0:
        return None, None, False

    ips = [p["src"] for p in packets_window]
    lengths = [p["len"] for p in packets_window]

    entropy = calculate_entropy(ips)
    dispersion = calculate_dispersion(lengths)

    anomaly = entropy > ENTROPY_THRESHOLD or dispersion > DISPERSION_THRESHOLD

    packets_window = []

    return entropy, dispersion, anomaly


# === CONFIGURAR GRÁFICA ===
plt.ion()
fig, ax = plt.subplots(figsize=(10, 5))

print("Listening and plotting in real time...")

while True:
    sniff(timeout=WINDOW, prn=packet_callback, store=0)

    entropy, dispersion, anomaly = process_window()

    if entropy is None:
        continue

    current_time = round(time.time() - start_time, 1)

    entropy_values.append(entropy)
    dispersion_values.append(dispersion)
    time_values.append(current_time)
    anomaly_values.append(anomaly)

    print("---- WINDOW ----")
    print("Time:", current_time)
    print("Entropy:", round(entropy, 3))
    print("Dispersion:", round(dispersion, 3))

    if anomaly:
        print("ANOMALY DETECTED")
    else:
        print("Normal")

    ax.clear()

    ax.plot(time_values, entropy_values, marker="o", label="Entropy")
    ax.plot(time_values, dispersion_values, marker="s", label="Dispersion")

    # sombrear zonas anómalas
    for i, is_anomaly in enumerate(anomaly_values):
        if is_anomaly:
            ax.axvspan(
                time_values[i] - WINDOW / 2,
                time_values[i] + WINDOW / 2,
                alpha=0.25,
                color="red"
            )

    ax.set_xlabel("Time (s)")
    ax.set_ylabel("Metric value")
    ax.set_title("Real-Time IoT Anomaly Detection")
    ax.legend()
    ax.grid(True)

    plt.pause(0.1)