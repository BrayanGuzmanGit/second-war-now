# Entrega Windows x64

## Selector sonoro — 19 de noviembre de 2026

Cinco sonidos metálicos de selección y clics de apertura/cierre, reutilizando
originales CC0. Una voz centrada en Efectos, con sustitución mediante fundido
de 15 ms, pausa y limpieza al salir. No cambia daño, turnos ni guardado.
Detalle en [sonidos del selector](sonidos-selector.md).

Verificación: selector en las tres misiones con ratón/teclado, rechazos y cambios
automáticos silenciosos, cambios rápidos, volumen, pausa y finales. Regresiones
de audio, pausa y combate correctas. La primera ejecución paralela de core tuvo
cinco fallos de persistencia; una repetición con perfil separado pasó sin cambios
en el guardado. Registros .godot/selector-*.log.

Se generaron tres muestras reales del mezclador en .godot/qa-selector/. Picos
entre −25,2 y −24,6 dBFS, sin recorte digital. La escucha humana para valorar
el carácter de cada efecto queda pendiente. Exportación y arranque Windows
correctos; paquete con EXE, PCK, créditos actualizados, licencia de fuente y LEEME.
La suite compilada de Windows QA (-- selector_audio) terminó con cero fallos.

Build actualizada con resultados educativos el 15 de noviembre de 2026, con Godot 4.7.2. Incluye los informes en pergamino, seis videos, audio de combate, terreno destructible, tienda, monedas y seis apariencias.

## Archivos de distribución

- `builds/windows/SecondWarNow.exe`
- `builds/windows/SecondWarNow.pck`
- `builds/windows/CREDITOS-AUDIO.txt`
- Paquete: `builds/SecondWarNow-SelectorSonoro-Windows-x64.zip`

Mantener ambos archivos juntos. No requiere el editor. El guardado continúa en `user://save_data.json`; no se entrega ningún guardado precompletado.

Las preferencias de sonido se conservan en `user://audio.cfg`, sin migrar el guardado v3. F8 o el botón Sonido abre los controles de efectos/avisos. El audio de videos conserva su volumen anterior. Las licencias de audio también están incluidas dentro del PCK.

El preset de distribución excluye pruebas, herramientas, documentación y el MP4 fuente. El video de juego es Ogg Theora. La fuente Oswald incluye su licencia en el paquete. La configuración y los archivos generados de exportación no contienen datos de usuario.

## Reproducir la exportación

Desde la raíz, usar Node.js 24 o posterior para obtener únicamente las plantillas Windows:

```powershell
node tools/descargar_plantillas.mjs
New-Item -ItemType Directory -Path builds/windows -Force
& 'C:\ruta\Godot_console.exe' --headless --path . --export-release 'Windows x64'
```

La herramienta descarga rangos del [paquete oficial de Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), valida tamaño/CRC de las entradas ZIP y guarda las dos plantillas en `.godot/plantillas/`. Esa carpeta está ignorada por Git.

## Verificación registrada

- Suite de combate/navegación: correcta.
- Suite de inicio audiovisual: correcta.
- Suite de campaña: cero fallos, incluidos recorridos físicos y guardado leído desde otro proceso.
- Partidas completas en el motor: tres victorias, con disparos reales y sin modificar salud, posición o plazo.
- Exportación release x64: correcta.
- Arranque del ejecutable distribuible durante trece segundos en headless: código 0 y sin errores de recursos/scripts en su registro.

El preset separado `Windows x64 QA` activa la escena `InicioQA` y ejecuta las partidas contra scripts compilados y escenas exportadas. Solo esa build contiene las pruebas; no distribuirla como juego.

Resultado de la build QA release: código 0, tres victorias y cero fallos. Francia: 3 disparos/27 HP; El Alamein: 7 disparos/25 HP; Berlín: 6 disparos/100 HP. Registro local: `.godot/build-qa.log`.

Para reproducirla, crear `builds/qa`, exportar el preset `Windows x64 QA` y ejecutar su EXE con `--headless --fixed-fps 60`. Las plantillas release no admiten `--script`: la escena QA arranca las pruebas. `-- economia` selecciona economía/apariencias y `-- terreno` selecciona terreno. Las suites usan guardados aislados por proceso.

## Verificación de tienda y skins

- Economía y apariencias: código 0 y cero fallos tanto en editor como en build QA compilada.
- Regresiones de combate, inicio, campaña y terreno: correctas, sin errores de script.
- Cinco partidas completas con disparos/movimiento reales, una por skin: Sherman/Francia, Cromwell/Francia, T-34/El Alamein, Churchill/Berlín y KV-2/Francia. Todas terminan en victoria tanto en motor como en EXE exportado.
- ENM-01 comprobado en primeras/segundas defensas, refuerzo y restos; independiente del inventario.
- Revisión de capturas OpenGL: tienda, paquetes, cinco skins y resultado de Berlín; controles dentro del viewport y cañones conectados.
- Distribuible: arranque y transición de introducción a menú con código 0.
- Registros: `.godot/test-*-tienda.log`, `.godot/build-qa-economia-tienda.log`, `.godot/build-qa-partidas-tienda.log` y `.godot/arranque-tienda-windows.log`.
- El aviso de guardado corrupto en la suite económica es una prueba deliberada, con archivos aislados.
- ZIP: `builds/SecondWarNow-Tienda-Monedas-Windows-x64.zip`, con EXE y PCK juntos.

Reglas y recursos en [tienda y economía](tienda-economia.md); prompts exactos de preparación en [prompts-skins.md](prompts-skins.md). Las capturas están en `.godot/qa-economia/`.

## Entrega de rodaje — 14 de noviembre de 2026

- Nuevo distribuible: `builds/SecondWarNow-Rodaje-Windows-x64.zip`; EXE y PCK también en `builds/windows/`.
- Presets Windows y QA exportados sin errores. Arranque del distribuible hasta menú: salida 0.
- Suite de rodaje en EXE QA: cero fallos; incluye seis modelos, avance/retroceso, reposo, aire, espejo, circunferencia, suspensión y reinicio.
- Cinco partidas automáticas completas en EXE QA: cero fallos (Francia con Sherman/Cromwell/KV-2, El Alamein con T-34 y Berlín con Churchill).
- Regresiones de combate, terreno, tienda/guardado e introducción: correctas. Los avisos de misiones bloqueadas/corrupción pertenecen a casos deliberados de prueba.
- Revisión de secuencias OpenGL de doce fotogramas por modelo, en `.godot/qa-rodaje/`, con corrección de centros, cubiertas y superposición. Las capturas aíslan el giro; las partidas automáticas verifican el desplazamiento real.
- Registros: `.godot/rodaje-visual.log`, `.godot/rodaje-core-final.log`, `.godot/build-qa-rodaje.log`, `.godot/build-qa-partidas-rodaje.log` y `.godot/arranque-rodaje-windows.log`.

La comprobación de 30/60/120 frecuencias corresponde a integración matemática, no a una certificación de rendimiento gráfico. La preparación de capas utiliza recortes y reconstrucción simplificada en memoria, descrita en [rodaje](rodaje.md).

## Entrega con seis videos de misión

Se incluyen tres introducciones y las victorias de Francia, El Alamein y Berlín. Los MP4 originales permanecen en el proyecto y la build distribuye sus conversiones Theora/Vorbis a 1280×720, 30 FPS, 10,03 segundos completos y sonido estéreo. Berlín reproduce su victoria antes del resumen, recompensas y epílogo.

Verificación: omisión por Escape y botón, retorno a fichas/resultados, liquidación única, derrota sin video y recurso ausente con recuperación. La suite gráfica reproduce las seis piezas completas y genera capturas en `.godot/qa-videos/`. La build QA valida también el flujo de videos. La integración de Berlín reutiliza el controlador existente, sin cambios de economía, guardado ni volumen de las cinemáticas.

Registros: `.godot/videos-core.log`, `.godot/videos-economia.log`, `.godot/videos-reproduccion.log`, `.godot/videos-qa-windows.log`, `.godot/videos-qa-reproduccion-windows.log` y `.godot/videos-arranque-windows.log`. El aviso de recurso `ausente.ogv` es deliberado. Paquete: `builds/SecondWarNow-Videos-Windows-x64.zip`.

## Entrega con informes en pergamino

Rediseño de las tres fichas previas usando el papel/marco existente, Oswald y las vistas de escenario. Historia y objetivos separados, revelado instantáneo, repetición de video, regreso al selector y comienzo directo. El aviso de Francia lee su plazo de la configuración.

La suite de informes pasa en el renderer gráfico y verifica navegación, omisión, repetición, recurso ausente y progreso intacto. Capturas en `.godot/qa-informe/`: tres misiones a 960×540, 1280×720, 1920×1080 y 1280×800, más sus estados de entrada. Las regresiones de navegación/combate y videos pasan. Registros: `.godot/informe-visual.log`, `.godot/informe-core.log`, `.godot/informe-videos.log` y `.godot/informe-qa-windows.log`.

Distribuible: `builds/SecondWarNow-Informes-Windows-x64.zip`. La build QA admite `-- informe`; detalle técnico en [informes de misión](informes-mision.md).

## Entrega con resultados educativos — 15 de noviembre de 2026

`builds/SecondWarNow-ResultadosEducativos-Windows-x64.zip` incluye el informe posterior a cada misión: pergamino y escenario, monedas/saldo, hechos y significado, cronología, pregunta con explicación y fuentes. Detalle en [resultados de misión](resultados-mision.md).

La suite `test_resultados.gd` pasa con cero fallos tanto en renderer gráfico como en el EXE QA compilado (`-- resultados`). Capturas revisadas de las tres misiones y de error de guardado/derrota en `.godot/qa-resultados/`, con cuatro tamaños de ventana. Se comprobó acreditación única, lectura completa, navegación por Tab, explicación, reintento y regreso al selector.

Regresiones de combate/navegación, campaña, economía, informes previos y videos: correctas, sin errores de script. Exportaciones de producción y QA completadas; arranque de producción con código 0. Registros: `.godot/resultados-*.log` y `.godot/qa-resultados-capturas.log`. El aviso del almacén de certificados de Windows procede del entorno; las pruebas de corrupción, misiones bloqueadas y video ausente generan avisos deliberados.

## Menú de pausa y sonido — 15 de noviembre de 2026

Nuevo menú en pergamino con pausa completa, ajustes persistentes de Efectos,
Avisos y Videos, y abandono confirmado sin recompensa. Motor +3 dB y
cadenas/contacto +2 dB. Guardado de campaña v3 intacto.

Suite de pausa correcta en renderer y EXE QA. Capturas de tres páginas en tres
resoluciones en .godot/qa-pausa/. Regresiones: campaña, terreno, economía,
audio, videos, inicio y controles. Exportación de producción y arranque correctos.
Registros: .godot/pausa-*.log. Algunas suites muestran avisos de recursos retenidos
al cerrar (hasta diez instancias/cuatro recursos en QA con acciones canceladas);
no hubo errores de script. Estos avisos requieren seguimiento separado.

Tres WAV del mezclador permiten revisar ralentí/desplazamiento/disparo en cada
superficie. Picos medidos entre −23,4 y −23,2 dBFS, sin recorte en esas muestras.
La escucha humana en auriculares/altavoces continúa pendiente.
Paquete: builds/SecondWarNow-Pausa-Sonido-Windows-x64.zip.

## Validaciones humanas pendientes

La captura de ventanas falló en el trabajo anterior, pero ahora se generaron y revisaron imágenes del renderer real OpenGL Compatibility en la RTX 2050. Se comprobaron las tres misiones, el borde sin damero/halo y estados intermedios de bombardeo. Capturas en `.godot/qa-terreno/`. Esta revisión no mide comodidad del joystick ni mezcla de audio.

Pendiente recorrer manualmente la build con teclado/ratón y probarla en Windows 10/11 limpio. Las victorias del bot usan tiros calculados con precisión y no certifican la dificultad para un jugador nuevo.

## Terreno: comprobaciones adicionales

`tests/test_terreno.gd` verifica los límites de excavación, progresión del bombardeo, daño único, ticks de fuego, caída de jugador/IA sin daño, salida de cráteres y cancelación al reiniciar. La build QA ejecuta esta suite con `SecondWarNowQA.exe --headless -- terreno`. Se conserva la suite de partidas completas sin argumentos adicionales.

El ZIP actualizado se genera como `builds/SecondWarNow-Terreno-Windows-x64.zip`. Mantener juntos su EXE y su PCK.

Verificación del 13 de noviembre: suite de terreno exportada con código 0 y cero fallos; tres partidas de QA exportadas ganadas con cero fallos; regresión de combate/controles correcta; inicio normal del EXE final con código 0 y sin errores en el registro. Logs: `.godot/build-qa-terreno.log`, `.godot/build-qa-partidas-terreno.log`, `.godot/test-core-terreno.log` y `.godot/build-inicio-terreno.log`.
