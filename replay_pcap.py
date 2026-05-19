from scapy.all import rdpcap, sendp
import time

print("Loading PCAP...")

packets = rdpcap("iot_replay.pcap")

print("Replaying packets...")

for i in range(len(packets)):
    sendp(packets[i], iface="lo0", verbose=False)  # loopback en Mac
    
    # Simular tiempo entre paquetes
    if i < len(packets) - 1:
        delay = float(packets[i+1].time) - float(packets[i].time)

if delay > 0 and delay < 2:
    time.sleep(delay)

print("Replay finished")
