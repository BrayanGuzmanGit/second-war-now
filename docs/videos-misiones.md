# Videos de introducción y victoria

Se integran los seis MP4 aportados por el usuario: tres introducciones y tres victorias. La victoria de Berlín se reproduce antes del resumen histórico, recompensas y epílogo de campaña.

| Fuente conservada en raíz | Recurso Ogg Theora en `Vistas/Recursos/Misiones/` |
|---|---|
| Francia introducción.mp4 | FranciaIntroduccion.ogv |
| Francia victoria.mp4 | FranciaVictoria.ogv |
| alamein Introduccion.mp4 | AlameinIntroduccion.ogv |
| Alamein victoria.mp4 | AlameinVictoria.ogv |
| berlin Introduccion.mp4 | BerlinIntroduccion.ogv |
| Berlin victoria.mp4 | BerlinVictoria.ogv |

Las piezas recibidas duran aproximadamente diez segundos, incluidas las victorias inicialmente previstas para ocho. Se conservan completas para no cortar la narración. Se convierten con FFmpeg a Theora/Vorbis, 1280×720, 30 FPS, manteniendo proporción, bandas negras cuando correspondan y audio original. Los MP4 se conservan como fuentes y se excluyen de los presets de exportación.

## Flujo y responsabilidades

`GestorMisiones` configura `video_introduccion` y `video_victoria` por misión. Las seis rutas están completas. `Berlin victoria.mp4` conserva sus 10,03 segundos y audio estéreo en la conversión Theora/Vorbis; no se recorta a los ocho segundos planteados originalmente.

`VideoMision` es una capa modal compartida, en negro y con encuadre 16:9; reproduce una sola vez sin bucle. Permite omitir mediante botón, Escape, Enter o Espacio. Detiene el reproductor y libera el sonido al finalizar, omitir o abandonar su escena. Si el recurso no existe, falla al cargar o el reproductor deja de funcionar, se continúa con el panel; un límite de seguridad de treinta segundos evita bloquear la navegación. No agrega otra narración ni títulos sobre los ya incluidos en el material.

La introducción se reproduce al abrir la ficha histórica. Terminar u omitir abre el [informe en pergamino](informes-mision.md), con contexto de escritura saltable y objetivos visibles. Permite repetir el video, volver al selector o comenzar el combate. Al repetir y regresar el contexto queda completamente revelado. No corre el tiempo de misión durante la introducción.

Al alcanzar una victoria real, el controlador liquida primero el resultado y presenta después el video disponible. El resumen y las recompensas se revelan al finalizar u omitir. La liquidación conserva su identificador original y los reintentos de guardado no repiten el video ni acreditan otra recompensa. Las derrotas no reproducen videos de victoria. El progreso y las monedas siguen en guardado v3.

La apertura general del juego mantiene su video y audio propios; los videos de misión solo existen dentro de sus escenas, tras salir del menú general.

## Verificación

`test_videos.gd` verifica las tres introducciones y tres victorias, cierre/omisión, epílogo tras Berlín, detención de sonidos de combate, ausencia de video en derrota, recursos ausentes y estabilidad del saldo. Con `-- reproduccion` deja terminar las seis piezas y comprueba que las victorias no terminen anticipadamente; sin él comprueba botón y Escape en la victoria de Berlín. La build QA acepta `-- videos` y `-- videos reproduccion`.

Se ejecutan las regresiones de navegación/combate y economía para comprobar que los paneles y las recompensas siguen accesibles. La prueba gráfica permite comprobar imagen, proporción, botón y reproducción completa; la escucha humana final de claridad y volumen sigue siendo necesaria.

Integración de Berlín verificada el 15 de noviembre de 2026: duración original y
convertida 10,026667 segundos, audio estéreo a 48 kHz y video Theora a 30 FPS.
Suite de omisión en motor y build Windows QA: 0 fallos. Reproducción gráfica
completa de las seis piezas: 0 fallos; captura de Berlín revisada en
`.godot/qa-videos/berlin-victoria.png`. El PCK de distribución incluye
`BerlinVictoria.ogv`. Paquete: `builds/SecondWarNow-CampanaCompleta-Windows-x64.zip`.
