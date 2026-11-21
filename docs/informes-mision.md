# Informes previos a la misión

La ficha posterior al video utiliza el papel y el marco de bronce del selector de campaña. `EstiloInforme` muestra una región limpia del papel mediante AtlasTexture y el borde exterior mediante NinePatchRect sin centro. No se retocan los JPEG ni se muestran los textos, candados y placas impresos en ellos.

La composición tiene 1120×620 unidades dentro del viewport de 1280×720. Cabecera con nombre/fecha/ubicación; paisaje completo a la izquierda, etiqueta de operación y repetición de introducción; historia y tres objetivos a la derecha; regreso al selector y comienzo de misión al pie. Usa Oswald, papel crema, tinta oscura y botones arena/bronce con foco visible. El escalado `canvas_items` y aspecto `keep` conservan el encuadre al cambiar el tamaño de ventana.

## Datos y comportamiento

`GestorMisiones` añade `contexto_historico`, `operacion`, `imagen_informe` y `objetivos_informe`. Los textos antiguos permanecen disponibles para los demás consumidores. El aviso de Francia lee `evacuacion_segundos` de `DatosCampana`; El Alamein y Berlín no muestran cuenta atrás.

`CinematicaPanel` conserva las rutas de navegación y usa `VideoMision` para la reproducción inicial y repetida. Tras la introducción muestra el informe con un fundido de 0,25 segundos. Solo el contexto se escribe progresivamente, a 0,018 segundos por carácter, dentro de una zona de tamaño fijo. Los objetivos aparecen completos desde el principio.

«Mostrar texto completo» revela el contexto y desaparece sin desplazar otros elementos. Cuando el foco está en el informe, Enter/Espacio revela primero y comienza la misión en una pulsación posterior. Los botones conservan su acción propia: comenzar permite entrar durante la escritura. Tab y las flechas recorren acciones disponibles con un foco visible; Escape vuelve al selector.

Al repetir la introducción se cancela la escritura y se oculta el informe. Al terminar u omitir se revela todo el contexto. La pulsación usada para omitir no se reutiliza: se ignora el mismo fotograma, se espera la liberación de las teclas que siguen presionadas y se descartan los ecos. Sin recurso de video la ficha sigue disponible y se explica por qué «Ver introducción» está deshabilitado.

La animación de texto se actualiza por delta y el fundido usa un Tween cancelable; no quedan temporizadores de escritura al salir o repetir. El cambio de escena se protege contra duplicados. Volver conserva misión seleccionada, inventario y progreso; no hay migración del guardado.

## Comprobación

`tests/test_informe.gd` verifica las tres misiones, objetivos, plazo de Francia, revelado, estabilidad de posiciones, repetición/omisión, teclado, regreso, progreso intacto, recurso ausente e inicio del combate. `-- capturas` usa el renderer gráfico para revisar cada misión en 960×540, 1280×720, 1920×1080 y 1280×800; las imágenes quedan en `.godot/qa-informe/`. Comprueba líneas de texto y controles dentro del marco. Incluye capturas de entrada y del estado completo.

La build QA admite `-- informe`. Las suites `test_core.gd` y `test_videos.gd` comprueban navegación/combate y videos. La entrega actualizada se empaqueta en `builds/SecondWarNow-Informes-Windows-x64.zip`.
