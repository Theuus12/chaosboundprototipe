"""Generate an original short impact sound without external audio assets."""
import math, random, struct, wave
from pathlib import Path
out = Path(__file__).resolve().parent.parent / 'assets/audio/hit.wav'
out.parent.mkdir(parents=True, exist_ok=True)
rng = random.Random(35)
rate = 44100
samples = []
filtered = 0.0
phase = 0.0
for i in range(int(rate * 0.14)):
    t = i / rate
    phase += 2 * math.pi * (110 + 100 * math.exp(-t * 45)) / rate
    noise = rng.uniform(-1, 1)
    filtered = filtered * 0.6 + noise * 0.4
    body = math.sin(phase) * math.exp(-t * 33)
    crack = (noise - filtered) * math.exp(-t * 90)
    sample = (body * 0.6 + crack * 0.3) * min(1, t * 2000)
    samples.append(struct.pack('<h', int(max(-1, min(1, sample)) * 26000)))
with wave.open(str(out), 'wb') as audio:
    audio.setnchannels(1)
    audio.setsampwidth(2)
    audio.setframerate(rate)
    audio.writeframes(b''.join(samples))
print(out)
