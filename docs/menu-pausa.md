# Menú de pausa — 15 de noviembre de 2026

Menú central con el papel, marco y fuente del selector. Escape, F8 y Menú / Pausa
abren la página principal: Continuar, Sonido y Volver a misiones. Sonido contiene
Efectos, Avisos e Introducciones/videos, porcentajes y silencios independientes.
Escape vuelve desde una subpágina y reanuda desde la principal. Tab y flechas
navegan; izquierda/derecha ajustan los deslizadores. Los videos conservan Escape
para omitir y los resultados no abren la pausa.

Volver pide confirmar que se pierde el avance de esa partida sin monedas.
Seguir jugando cancela la confirmación manteniendo la pausa. Abandonar invalida
la secuencia del controlador, limpia audio y cambia al selector sin liquidar ni
alterar saldo, compras, bonos o progreso previo. No hay guardado de partida parcial.

## Implementación

PanelSonido conserva su ruta para compatibilidad, reemplazando su contenido por
un menú con señales pausa_solicitada y abandono_solicitado. El controlador congela
el SceneTree y solo el menú tiene PROCESS_MODE_ALWAYS. Los reproductores de partida
heredan la pausa y conservan su posición. Al reanudar se cancela el arrastre del
joystick y se absorbe la activación mantenida del disparo.

Las esperas de IA, bengala y ticks de fuego usan temporizadores pausable; las
corrutinas de asentamiento, movimiento enemigo y excavación esperan además a que
termine la pausa, pues physics_frame continúa emitiéndose. Los tweens vinculados
y procesos normales conservan su avance.

Videos es un bus independiente utilizado por PantallaCarga y VideoMision.
configurar_volumen admite el canal videos; audio.cfg incorpora videos y
silencio_videos. Los archivos antiguos conservan sus canales y reciben videos
al 100 %. Efectos y avisos siguen inicialmente al 80 %. No cambia el guardado v3.
Ante error de escritura, se conserva el ajuste de sesión y se ofrece Reintentar.

## Verificación

test_pausa.gd cubre movimiento/combustible/audio, Escape/F8, temporizador de IA,
vuelo, bengala, excavación, fuego, evacuación y refuerzo; cancelación y abandono;
preferencias antiguas, persistencia de videos y fallo/reintento de escritura.
Con -- capturas genera las tres páginas a 960×540, 1280×720 y 1920×1080.
El EXE QA admite -- pausa. Las regresiones de campaña, terreno, audio, economía
y videos se ejecutan con perfiles de prueba separados.

Capturas: .godot/qa-pausa/. grabar_motor.gd genera tres muestras WAV del mezclador:
dos segundos de reposo, desplazamiento, asentamiento y disparo. Los niveles del
motor suben 3 dB y los de cadenas/contacto 2 dB. La revisión técnica de niveles
no sustituye una escucha humana con auriculares y altavoces.
