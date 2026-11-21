# Rodaje compartido de los seis tanques

Implementación del 14 de noviembre de 2026. Se conserva la física y el guardado v3; la tienda mantiene las vistas previas estáticas. No se necesitan imágenes adicionales.

## Recursos y montaje

`Modelos/DatosRodaje.gd` guarda por identificador los centros/radios en píxeles de fuente, el contorno cerrado, el paso de cadena, el recorte de eslabón y las cubiertas. Incluye TNQ-01, TNQ-02, TNQ-03, TNQ-04, TNQ-06 y ENM-01. `CatalogoApariencias.obtener()` publica estos datos como `rodaje`.

Las piezas se derivan en memoria de los PNG existentes; no hay un segundo juego de PNG retocados ni se modifican los originales. Los recortes circulares crean sprites independientes. Donde un brazo tapa media rueda del Sherman/Cromwell, el shader reconstruye esa mitad por simetría de la parte inferior y dibuja encima la cubierta fija. Las ruedas interiores parcialmente ocultas del enemigo usan una rueda completa del mismo modelo, conservando orden de superposición. Churchill/KV-2 conservan recortes de cajas y brazos de suspensión. El interior oculto del tren se completa con un fondo oscuro; es una reconstrucción gráfica simplificada, no una restauración detallada de la ilustración oculta.

El contorno se suaviza con curvas cuadráticas. Un `MultiMeshInstance2D` coloca un número fijo de eslabones sobre su longitud, usando la tangente para orientarlos. Las ruedas permanecen detrás de las cubiertas y el cañón conserva su pivote y marcador. El shader antiguo `suspension_tanque.gdshader` se retiró.

## Distancia e interpolación

Jugador e IA llaman a `VisualTanque.actualizar_movimiento(delta, desplazamiento_real, en_suelo, normal_suelo)` después de `move_and_slide()` y del límite del mapa. El componente tangencial determina la distancia; el giro es distancia/radio efectivo vertical en mundo. La orientación reflejada se aplica una vez. La misma distancia hace que el tramo inferior de la cadena circule contra el avance.

`VisualRodaje` mantiene estados independientes e interpola entre la distancia anterior/actual y los apoyos anteriores/actuales. Parar o invertir no reinicia la fase. No circula al estar bloqueado, en el aire ni durante el fotograma de aterrizaje. Los cambios de apariencia, apariciones y colocaciones explícitas reinician; un salto horizontal de 20 píxeles en una actualización también se trata como reubicación. El movimiento normal máximo actual es 3 píxeles por actualización física.

Los apoyos consultan `TerrenoDestructible.obtener_altura()`. Se limitan a ±2 píxeles del mundo y alcanzan aproximadamente el 95 % del ajuste en 0,12 segundos en movimiento o 0,25 en reposo/aire. El recorrido interpola espacialmente entre apoyos vecinos. No se desplaza el montaje del cañón ni se alteran hitboxes, estadísticas, combustible o velocidad. Al destruirse se congela el rodaje; la animación de caída del resto sigue perteneciendo a `Tanque`.

## Verificación reproducible

`tests/test_rodaje.gd` comprueba seis modelos, integración a 30/60/120 pasos por segundo, avance/retroceso, circunferencia, bloqueo, aire, espejo de IA, reinicio, límite de suspensión, cantidad de eslabones y restos quietos. Esta comprobación de frecuencias prueba las matemáticas con distintos pasos; no equivale a medir rendimiento de GPU a 120 FPS.

Con renderer gráfico y `-- capturas`, guarda doce fotogramas por apariencia en `.godot/qa-rodaje/`. Las secuencias aíslan la articulación del tren, ocultan el HUD y permiten comparar varias fases de giro. Las partidas de `test_partidas.gd` verifican desplazamiento físico y combate reales con las cinco skins, repartidas entre las tres misiones. Las suites de combate, terreno, economía e introducción cubren las regresiones relacionadas.

La build QA admite `SecondWarNowQA.exe --headless --fixed-fps 60 -- rodaje`; sin argumento ejecuta las cinco partidas. La valoración humana final de fluidez y acabado, y la certificación en otro equipo Windows, siguen siendo una revisión de entrega pendiente.
