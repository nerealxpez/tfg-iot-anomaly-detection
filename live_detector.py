from scapy.all import sniff
from collections import Counter
import numpy as np
import time

WINDOW = 5

packets_window=[]

def entropy(iplist):
    counts=Counter(iplist)
    probs=np.array(list(counts.values()))/sum(counts.values())
    return -np.sum(probs*np.log2(probs))

def dispersion(lengths):
    return np.std(lengths)/np.mean(lengths)

def process_window():

    global packets_window

    if len(packets_window)==0:
        return

    ips=[p["src"] for p in packets_window]
    lengths=[p["len"] for p in packets_window]

    H=entropy(ips)
    D=dispersion(lengths)

    print("---- WINDOW ----")
    print("Entropy:",round(H,3))
    print("Dispersion:",round(D,3))

    if H>0.8 or D>0.5:
        print("ANOMALY DETECTED")
    else:
        print("Normal")

    packets_window=[]


def packet_callback(pkt):

    global packets_window

    if "IP" in pkt:
        packets_window.append({
            "src":pkt["IP"].src,
            "len":len(pkt)
        })

print("Listening...")

start=time.time()

while True:

    sniff(timeout=WINDOW,
          prn=packet_callback,
          store=0)

    process_window()