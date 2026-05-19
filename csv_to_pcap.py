from scapy.all import *
import pandas as pd

# === CARGAR CSV ===
data = pd.read_csv(
    "/Users/nerealopezcastillo/Desktop/TFG/datos/procesados/iot_traffic_validation_clean.csv",
    sep=";",
    engine="python",
    skiprows=1,
    on_bad_lines="skip"
)

# limpiar nombres de columnas
data.columns = data.columns.str.strip()

# extraer columnas necesarias
times = pd.to_numeric(data["Time"], errors="coerce")
sources = data["Source"]
destinations = data["Destination"]
lengths = pd.to_numeric(data["Length"], errors="coerce")

# limpiar datos inválidos
valid = times.notna() & lengths.notna()
times = times[valid].reset_index(drop=True)
sources = sources[valid].reset_index(drop=True)
destinations = destinations[valid].reset_index(drop=True)
lengths = lengths[valid].reset_index(drop=True)

packets = []

print("Generating packets...")

for i in range(len(times)):

    try:
        src = sources[i]
        dst = destinations[i]
        size = int(lengths[i])

        # crear paquete básico
        pkt = IP(src=src, dst=dst) / TCP() / Raw(load="X" * max(1, size - 40))

        # guardar timestamp
        pkt.time = times[i]

        packets.append(pkt)

    except:
        continue

# === GUARDAR PCAP ===
wrpcap("iot_replay.pcap", packets)

print("PCAP generado: iot_replay.pcap")