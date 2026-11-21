# Requisitos y alcance

Este documento sintetiza los requisitos del GDD, la comprensión acordada y el estado observado. El objetivo es intentar cubrir los sistemas obligatorios dentro del plazo de un mes; los recortes se concentran primero en contenido ambiental y pulido.

| ID | Requisito | Prioridad de entrega | Estado actual |
|---|---|---|---|
| F01 | Combate por turnos contra IA con trayectoria parabólica | Esencial | Implementado con fases y combates sucesivos; pendiente de balance humano integral |
| F02 | Movimiento limitado por combustible, apuntado y disparo | Esencial | Implementado: A/D y combustible; joystick virtual de arrastre con ángulo determinado por dirección y potencia por distancia, cañón visual alineado al vector y disparo desde su boca |
| F03 | Cinco municiones y ciclo rotativo obligatorio | Esencial | Parcial: Factory, ciclo independiente por tanque y efectos básicos |
| F04 | Tienda simulada de cosméticos de tanques | Obligatorio, UI simple | Ampliación implementada: monedas por partida, paquetes simulados COP, cinco skins persistentes y apariencia enemiga |
| F05 | Tres misiones, selección y desbloqueo progresivo | Obligatorio | Reglas propias implementadas: Francia cronometrada, dos defensas en El Alamein y Berlín, geometría propia y objetivo final; validación humana pendiente |
| F06 | Información histórica antes y después de cada misión | Obligatorio, presentación sencilla | Tres videos de introducción y tres de victoria, con informes históricos, recompensas y epílogo tras la victoria de Berlín |
| F07 | Destrucción del tanque legible sin interrumpir el combate | Pulido de jugabilidad | Implementado: resto visible, explosión breve y animación no bloqueante; retirada del jugador comienza al neutralizar al enemigo |
| F08 | Pantalla de carga inicial con video de apertura | Presentación inicial | Implementado: video Ogg Theora de 10,03 segundos, progreso combinado, arte de menú principal con zonas interactivas escalonadas y fotograma de fondo fijo; el audio continúa a -18 dB mientras permanece el menú |
| NF01 | Teclado y ratón | Esencial | Implementado a nivel de controles: teclado para movimiento/Espacio y ratón para arrastrar el joystick y disparar fuera de su área; el turno avanza automáticamente. Falta validar manualmente la comodidad y el balance |
| NF02 | Godot 4.7.2, 2D y GDScript | Esencial | Implementado; validado con Godot 4.7.2 |
| NF03 | Windows 10/11 de 64 bits | Esencial | Pendiente de validar exportación |
| NF04 | Guardado automático JSON de progreso y cosméticos | Esencial | Implementado; test_campana verifica su lectura desde un segundo proceso, usa archivos aislados; versión 3 con migración, respaldo y recibos idempotentes |

## Recortes de bajo impacto permitidos

- Reducir animaciones y transiciones de la cinemática a panel, imagen y texto.
- Usar IA de dificultad básica y ajustar después el balance.
- Mantener sencillos los mapas y efectos de proyectil, siempre que se distingan los cinco comportamientos funcionales.
- Diferir NPC ambientales, música original y variedad de efectos/arte no necesarios para comprender el juego.
- Mantener la tienda operativa con arte disponible o provisional, sin pagos reales.

## Fuera de alcance para la primera entrega

- Monetización real, multijugador y sistemas no incluidos en el GDD.
- Arte y audio de producción que no estén disponibles o cuya licencia no se haya confirmado.
- Simulación histórica exacta de cada movimiento militar; las misiones son escenarios educativos inspirados en hechos reales.

## Criterios de aceptación global

- Terreno físico deformable en las tres misiones; misma geometría para dibujo y colisión. Cráteres acumulativos con profundidad máxima 80 y pendiente máxima 32°, sin daño por caída y con ruta final protegida.
- Bombardeo sin excavación durante los 1,4 segundos de señalización y con retirada progresiva durante los 0,9 segundos de animación. Un único daño y un único objetivo de cráter, sin repetición de excavación por fotograma.
- Superficies e interiores usan las seis imágenes suministradas, omiten el damero incrustado y exponen subsuelo al excavar. Los fondos originales se conservan.
- Jugador e IA pueden descender, salir de cráteres y apuntar desde sus posiciones reales. Reiniciar cancela operaciones y restaura alturas; la retirada de Francia no pausa su cuenta atrás.

- Se puede iniciar desde el menú, jugar una misión y llegar a una pantalla de victoria o derrota.
- Al iniciar el juego, la pantalla de carga reproduce la introducción de 10 segundos mientras carga el menú en segundo plano, informa errores de carga y presenta el menú cuando ambas tareas terminan.
- En el tramo final de la introducción aparece el arte del menú sobre el fotograma fijo y las zonas de interacción para misión, tienda y salida se revelan escalonadamente; el audio continúa reproduciéndose en segundo plano a volumen reducido. El arte debe conservar visible el tanque de la placa de tienda.
- El HUD identifica quién tiene el turno y desactiva las acciones del jugador mientras actúa la IA o hay un proyectil en vuelo.
- La dirección del joystick controla el ángulo y la distancia arrastrada controla la potencia de salida; el HUD limita el desplazamiento y captura el clic de arrastre para que no dispare. Al soltar, conserva el apuntado. La visualización muestra solo el 62 % inicial del vuelo previsto hasta el suelo, para no revelar el impacto; el proyectil aparece en el marcador de disparo y conserva la trayectoria física completa.
- El cañón visual acompaña el vector inicial de la trayectoria, y el marcador de disparo sigue la boca al apuntar tanto con el jugador como con la IA.
- Las ruedas y la suspensión se animan con el desplazamiento real de ambos tanques; el rig visual no modifica el cuerpo físico ni la silueta de hitbox, que sigue derivándose del arte fuente completo.
- Las colisiones físicas de jugador e IA se generan desde la silueta alfa con escala, orientación y offset; la caja rectangular de referencia queda desactivada. Las pruebas verifican cobertura de un píxel opaco y exclusión de una muestra transparente.
- Proyectil principal y fragmentos comprueban por raycast el segmento recorrido en cada paso y entregan el punto de contacto; el barrido no tiene radio. El daño de área mide al punto central de referencia del tanque.
- Las cinco municiones tienen siluetas y rastros de vuelo distintos, un efecto de salida desde el punto de disparo y efectos de impacto acordes a su comportamiento; bombardeo señala el área durante su demora, dispersión produce cinco fragmentos e incendiario mantiene una zona de fuego mientras aplica ticks.
- Los efectos visuales son independientes de la Factory, del cálculo físico y de la salud; `Tanque` conserva la responsabilidad de daño y los ticks incendiarios no repiten el VFX.
- Rechazar una munición ya usada conserva el turno; seleccionar otra actualiza de inmediato su curva y permite disparar sin finalizar el turno manualmente.
- Después de cada disparo del jugador, el HUD selecciona una munición aún disponible; no se puede quedar seleccionado un tipo ya consumido.
- La IA se reposiciona y responde con un disparo calculado hacia el centro de colisión del jugador.
- Tras neutralizar al enemigo, aparece un aviso animado con el mensaje contextual de la misión; el jugador puede avanzar y retroceder sin consumir combustible ni quedar limitado por él.
- La retirada es una fase distinta del turno de combate: el HUD deshabilita el selector y no ofrece acciones ofensivas; intentar disparar no debe consumir el control de movimiento ni reactivar a la IA.
- Al destruirse un tanque, sus colisiones y física se desactivan, pero el sprite permanece como resto con un destello, caída y oscurecimiento mientras se reproduce una explosión breve; el cambio de fase no espera a terminar estos efectos visuales.
- Francia inicia 30 segundos al neutralizar la primera posición. Se comprueba llegada antes del vencimiento en la misma actualización; vencer bloquea la victoria, anuncia un refuerzo y a los dos segundos inicia un disparo letal de 0,35 segundos de vuelo. No aparecen refuerzos después de un resultado.
- El Alamein y Berlín requieren dos defensas sucesivas y la llegada al objetivo final. Vida y ciclo de munición persisten; el avance es ilimitado y el segundo combate restituye combustible limitado. La primera posición impide avanzar más allá del umbral de activación mientras siga activa.
- La llegada a `ZonaEvacuacion` se detecta física o geométricamente, solo en fase final y con el jugador vivo. El resultado permanece hasta volver a misiones.
- Los tres mapas ilustrados se seleccionan según la misión y cubren el mundo de 1800 × 1005 unidades. El suelo transitable ocupa el ancho del mundo; la cámara ajusta el zoom hasta 1.08, respeta límites y sigue el combate, pasando al jugador durante retirada y agregando margen inferior para cráteres.
- Los turnos, combustible, disparo, impactos y acciones de IA se reflejan correctamente sin dejar el combate bloqueado ante un fallo al crear o registrar munición.
- El viewport es 1280 × 720 y usa `canvas_items` con aspecto `keep`; comprobar el encuadre al redimensionar.
- La munición respeta el ciclo de uso; la campaña respeta el bloqueo/desbloqueo.
- El progreso de campaña y cosméticos se conserva en JSON y los errores no se ocultan.
- La documentación y las escenas reflejan la implementación real.
