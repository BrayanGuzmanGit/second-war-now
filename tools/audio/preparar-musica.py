"""Renderiza las cuatro grabaciones CC0 y la mezcla armónica para la tienda."""
from pathlib import Path
import subprocess
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
FF = next((ROOT / ".godot/herramientas").rglob("ffmpeg.exe"))
SRC = Path(__file__).parent / "originales/musica"
OUT = ROOT / "Vistas/Recursos/Musica"
OUT.mkdir(exist_ok=True)
RATE = 44100

def render(nombre, fuente, ganancia, ligera=False):
    raw = subprocess.check_output([FF, "-v", "error", "-i", SRC / fuente, "-ac", "2",
                                   "-ar", str(RATE), "-f", "f32le", "-"])
    audio = np.frombuffer(raw, "<f4").reshape(-1, 2).copy()
    if ligera:
        # Mediana temporal por banda: conservar notas sostenidas y suavizar ataques.
        tam, paso = 2048, 512
        ventana = np.sqrt(np.hanning(tam))
        for canal in range(2):
            x = np.pad(audio[:, canal], tam, mode="wrap")
            mezcla = np.zeros_like(x)
            marcos = np.lib.stride_tricks.sliding_window_view(x, tam)[::paso]
            for inicio in range(0, len(marcos), 96):
                fin = min(inicio + 96, len(marcos))
                izq, der = max(0, inicio-8), min(len(marcos), fin+8)
                espectro = np.fft.rfft(marcos[izq:der] * ventana)
                amplitud = np.abs(espectro)
                for i in range(inicio, fin):
                    j = i - izq
                    sostenido = np.median(amplitud[max(0,j-8):j+9], axis=0)
                    mascara = np.clip(sostenido / (amplitud[j]+1e-8), 0.08, 1)
                    mezcla[i*paso:i*paso+tam] += np.fft.irfft(espectro[j]*mascara) * ventana / 2
            audio[:, canal] = mezcla[tam:-tam]
    # Microfundido circular en la unión de las tomas, sin insertar silencio.
    n = int(RATE * 0.018)
    rampa = np.linspace(0, 1, n)[:, None]
    audio[-n:] = audio[-n:] * (1-rampa) + audio[:n] * rampa
    comando = [FF,"-v","error","-y","-f","f32le","-ar",str(RATE),"-ac","2","-i","-"]
    filtro = "atempo=0.93,treble=g=-3," if ligera else ""
    subprocess.run(comando+["-af",filtro+f"volume={ganancia}dB","-c:a","libvorbis","-q:a","5",
                           OUT / (nombre+".ogg")], input=audio[n:].astype("<f4").tobytes(), check=True)

render("menu","rpg.ogg",-3)
render("francia","determined_pursuit_loop.wav",-6)
render("alamein","hope_orchestral_battle_music_bpm165.ogg",-9)
render("berlin","the_final_battle.ogg",-5)
render("tienda","rpg.ogg",-3,True)
