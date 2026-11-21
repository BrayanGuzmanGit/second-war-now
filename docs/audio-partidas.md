# Audio de partidas

Motor común a las seis apariencias; cada unidad conserva su estado propio.
44 recursos derivados, con originales, créditos y recetas reproducibles. El audio
de introducciones y videos usa el bus independiente Videos, inicialmente al 100 %.

## Comportamiento

- Motor al ralentí y mezcla de cadenas/contacto según desplazamiento físico real.
  La tangente de apoyo elimina la caída del cálculo. Respuesta exponencial 0,15 s.
- Suelo: tierra en Francia, arena en El Alamein y escombros en Berlín. Los bloques
  y ruinas publican `material_audio`; los tanques se identifican por su grupo.
- Elevación: se muestrea el ángulo final una vez por frame, ignorando el estado
  inicial y cambios inferiores a 0,002 rad. Asentamiento del casco no es puntería.
- Una colisión emite un evento antes de aplicar daño. El daño de área y los ticks
  no duplican el impacto. Dispersión admite cuatro impactos sonoros por paso físico.
- Bombardeo: bengala al contacto, impacto tras su espera y bucle que sigue el
  progreso del efecto de excavación. El fuego pertenece a su zona visual.
- Avisos centrados de turno, retirada, últimos cinco segundos y refuerzos.
  Los saltos de tiempo producen un único aviso, sin reproducir los omitidos.
- Los restos detienen mecanismos. Resultado detiene bucles/avisos; permite colas
  breves. Video o salida de escena detiene todo e invalida la sesión anterior.

## Arquitectura y controles

`CatalogoSonidos` resuelve rutas y materiales. `GestorAudioPartida` es un autoload
de presentación, con `iniciar`, `evento`, `impacto`, `actualizar_tanque`, `bucle`,
`reiniciar_unidad`, `detener_unidad`, `finalizar`, `detener_todo` y controles de volumen.
La señal `evento_reproducido` permite comprobar eventos sin cambiar la simulación.

Los buses PartidaEfectos, PartidaMecanismos y PartidaAvisos no modifican Master.
Los mecanismos pasan por Efectos; sus niveles bajan 7 dB durante eventos importantes.
Efectos usa un limitador a -2 dB, hasta 18 voces breves; las variantes evitan repetir
el archivo anterior. Los sonidos del mundo usan estéreo moderado y distancia amplia.

Menú / Pausa, Escape o F8 abre el menú modal. Sonido incluye efectos y avisos al
80 % inicial y videos al 100 %, con volumen y silencio independientes. Toda la
misión y su audio quedan pausados, incluidos la evacuación y los refuerzos.
Las preferencias se guardan en `user://audio.cfg`, fuera del guardado v3. Un error
de escritura mantiene el ajuste durante la sesión y se muestra en el panel.

Motor: ralentí −33 dB, movimiento −21 dB; cadenas/contacto −23 dB a intensidad
completa. Son incrementos de 3/2 dB respectivamente, conservando suavizado,
limitador y atenuación. No se incrementan engranajes, disparos ni explosiones.
Detalles de navegación y pruebas en [menú de pausa](menu-pausa.md).

## Preparación y verificación

`node tools/audio/preparar.cjs` reproduce las ediciones usando FFmpeg; admite su
ruta mediante `FFMPEG`. WAV mono PCM16 para eventos, Vorbis para bucles. Picos
normalizados a 0,65 antes de la mezcla; los bucles de motor/mecanismos/fuego tienen
unión circular. `CREDITOS-AUDIO.txt` se incluye en el paquete de distribución.

Suite `tests/test_audio.gd`: materiales, variantes, colisiones repetidas, efectos
temporizados, polifonía, preferencias, HUD, seis apariencias a 30/60/120 FPS,
refuerzo, segunda posición, llegada prioritaria y limpieza de escenas.
En build QA se ejecuta con `-- audio`; `-- grabar_audio francia|alamein|berlin`
ejecuta el bot de partidas completas para capturar el mezclador con Movie Maker.

La evaluación auditiva de naturalidad con auriculares y altavoces requiere escucha
humana; las comprobaciones automáticas no sustituyen esa evaluación.

## Resultado de verificación — 15 de noviembre de 2026

- Suite de audio: 0 fallos en editor y ejecutable Windows QA; preferencias
  escritas y verificadas desde procesos separados.
- Regresiones: core, campaña, terreno, economía/guardado, rodaje, videos e informes
  completadas con 0 fallos de sus verificaciones.
- Windows QA: cinco partidas ganadas (Sherman/Cromwell/KV-2 en Francia,
  T-34 en El Alamein y Churchill en Berlín), usando apuntado y disparos reales.
- Capturas del panel a 1280×720 y 960×540; corregida la superposición del joystick.
- Grabaciones de las tres misiones con el mezclador estéreo real, sin micrófono:
  `builds/revision-audio/francia.mp4`, `alamein.mp4` y `berlin.mp4`.
- Medición del audio PCM original: picos máximos de -3,77 dBFS en Francia
  (incluye comienzo del video de victoria), -14,02 en El Alamein y -14,44 en
  Berlín. Ninguna grabación alcanzó 0 dBFS ni recorte digital.
- Arranque del ejecutable de distribución correcto. Créditos y manifest incluidos
  en el PCK, y créditos visibles junto al ejecutable.

El entorno de pruebas avisa que no puede leer el almacén de certificados de
Windows; no impide estas pruebas locales. Una ejecución de terreno avisó de
objetos pendientes al salir; la repetición con diagnóstico no reprodujo el aviso.
No se afirma una aprobación auditiva humana: las grabaciones quedan disponibles
para revisar naturalidad, equilibrio y comodidad antes del cierre perceptual.

## Banda sonora

El menú y el selector comparten el tema de navegación. La tienda utiliza una mezcla armónica más lenta de la misma grabación. Los informes recuperan el tema principal a menor volumen. La introducción inicial cede el audio al menú después de congelar el último fotograma. Los videos de misión toman el audio inmediatamente y los resultados dejan terminar el fundido.

Cada misión reproduce una pista independiente. El gestor utiliza dos voces pausables, fundidos de un segundo y una reducción de 4 dB durante avisos. La cuenta atrás mantiene esa reducción desde el primer pitido hasta los refuerzos o el resultado. Música tiene volumen inicial del 40 % y silencio independiente en audio.cfg.

Las fuentes CC0 y las ediciones se detallan en [los créditos distribuidos](../Vistas/Recursos/Audio/CREDITOS-AUDIO.txt). Los originales se conservan en tools/audio/originales/musica. Para regenerar los cinco Ogg, ejecutar tools/audio/preparar-musica.py con Python, NumPy y FFmpeg. Los grabados conservan las frases musicales originales, incluidos los 70 segundos del bucle de El Alamein.

La suite test_musica.gd verifica la navegación, pausa, reducción por avisos y silencio al alcanzar resultados. El preset Windows x64 QA admite el argumento musica. La muestra Muestra-banda-sonora.mp4 contiene audio capturado del mezclador del juego.