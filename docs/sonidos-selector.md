# Sonidos del selector — 19 de noviembre de 2026

El selector reproduce clics suaves de apertura/cierre y cinco sonidos de carga
metálica. Estándar: encaje seco (0,15 s); pesado: cierre grave (0,25 s);
dispersión: tres encajes (0,25 s); bombardeo: cierre y trinquete (0,30 s);
incendiario: encaje y encendido breve (0,25 s). Los clics duran 0,10 s.

## Interacción e integración

El HUD reproduce abrir/cerrar solo en acciones voluntarias. El controlador valida
fase, turno, vuelo, disponibilidad y pausa antes de aceptar una selección.
Un cambio válido cierra sin clic adicional y reproduce la identidad elegida.
Repetir la seleccionada solo produce cierre si el selector estaba abierto.
Rechazos, actualizaciones del HUD, selección automática e IA son silenciosos.
Los cierres por pausa, fin de turno o resultado tampoco generan clics.
Escape conserva la pausa existente.

GestorAudioPartida.interfaz(tipo, municion) acepta abrir, cerrar y seleccion.
CatalogoSonidos.SELECTOR enumera los siete recursos. Una AudioStreamPlayer
centrada utiliza PartidaEfectos: selección a −18 dB, clics a −24 dB.
No modifica el ducking de mecanismos ni ocupa las voces del combate.
Una nueva petición desvanece la voz anterior 15 ms; durante ese fundido solo
se conserva la petición más reciente. La voz y el tween heredan la pausa.
finalizar/detener_todo cancelan fundido, petición y reproducción.
La señal selector_reproducido(tipo, municion) permite verificar los inicios reales.

## Recursos

Siete WAV mono PCM16 a 44,1 kHz, con pico normalizado 0,65 y fundidos breves.
Originales CC0 de Kenney (UI Audio e Impact Sounds) y AntumDeluge (Fire Crackling),
ya conservados en tools/audio/originales. Créditos completos en CREDITOS-AUDIO.txt.
No se sobrescriben originales ni se añaden dependencias de ejecución.

Ejecutar node tools/audio/preparar-selector.cjs con FFmpeg disponible en la ruta
local habitual o mediante FFMPEG. El preparador general también ejecuta esta receta.
manifest.json conserva las capas, filtros, posiciones y duraciones exactas.

## Verificación

test_selector_audio.gd comprueba las tres misiones, ratón/teclado, apertura/cierre,
selección sin duplicación, munición repetida, rechazos, cambios automáticos,
ráfagas de cambios, silencio, pausa, victoria, derrota y abandono.
El preset Windows QA admite -- selector_audio.
Con -- grabar se guardan WAV reales del mezclador en .godot/qa-selector/,
con las cinco selecciones, clics, motor y avisos.

La medición digital de picos detecta recorte; no sustituye una escucha humana
con auriculares y altavoces para aprobar el carácter y equilibrio de la mezcla.
El guardado v3 y audio.cfg permanecen compatibles, sin nuevos controles.
