# Estado actual — Second War Now

**21 de noviembre de 2026.** Las cinco municiones tienen fogonazo, humo y efectos de contacto por material. El barrido convexo de proyectiles y fragmentos alcanza el contorno del casco, rodaje y cañón orientable de cada apariencia. El apoyo del tanque en terreno se calcula por separado. La compilación está en `builds/SecondWarNow-Impactos-Windows-x64.zip` y la secuencia visual en `builds/Impactos-demostracion.mp4`.

Para inspeccionar la geometría en una misión, iniciar con `-- impactos-debug`. El contorno turquesa muestra el blanco y el proyectil, la cruz indica el contacto y el trazo verde su normal. La suite `test_contornos.gd` cubre las seis apariencias, boca a dos píxeles, tiros rasantes y prioridad del obstáculo. La tolerancia de dos píxeles se ha medido en la boca. Las orugas usan una envolvente estable del recorrido de los eslabones.

Selector sonoro integrado: cinco identidades metálicas y dos clics, una sola voz
centrada en Efectos, fundido de sustitución de 15 ms y limpieza al salir.
Detalles en [sonidos del selector](docs/sonidos-selector.md).
Entrega más reciente: builds/SecondWarNow-SelectorSonoro-Windows-x64.zip.

Menú de pausa implementado: Escape/F8 o Menú / Pausa detienen toda la misión,
incluido audio y evacuación. Permite continuar, ajustar Efectos/Avisos/Videos y
abandonar con confirmación sin recompensas. Motor +3 dB y cadenas/contacto +2 dB.
Entrega más reciente: builds/SecondWarNow-Pausa-Sonido-Windows-x64.zip.
Detalles y límites de revisión en [menú de pausa](docs/menu-pausa.md).

Corrección de Berlín: retirados los dos bloques elevados de ruinas y sus colisiones. Se conservan las rampas de escombros y el terreno destructible. Esos bloques parecían suelo flotante e interceptaban los disparos de la IA.

Resultados rediseñados con el pergamino del selector, ficha de monedas, lectura histórica desplazable, cronología, preguntas y fuentes. Los tres cierres distinguen la partida de los hechos reales y conservan la liquidación v3 y los videos. Detalles y verificación en [resultados educativos](docs/resultados-mision.md). Entrega actual: `builds/SecondWarNow-ResultadosEducativos-Windows-x64.zip`.

Audio de partidas integrado: 44 recursos derivados con licencias, motor/cadenas por superficie, engranajes, cinco municiones por material, fuego/bombardeo y avisos. Sonido/F8 abre controles persistentes separados; videos conservan su volumen. Suites de audio y regresiones correctas, incluido recorrido Windows con las cinco skins. La escucha humana de naturalidad sigue pendiente. Detalles en [audio de partidas](docs/audio-partidas.md). Entrega anterior: `builds/SecondWarNow-CampanaCompleta-Windows-x64.zip`.

Informes previos rediseñados con pergamino, marco de bronce, vista del escenario y objetivos separados de la historia. Escritura saltable, regreso al selector y repetición de introducción. Comprobados en cuatro tamaños de ventana; nueva suite `test_informe.gd`. Véase [informes de misión](docs/informes-mision.md).

Videos de misión integrados: tres introducciones y tres victorias, incluida Berlín, con audio original y omisión por teclado/ratón. Las seis fuentes duran 10,03 segundos y se conservan completas. Tras la victoria de Berlín se presenta su resumen, recompensas y epílogo. Detalles en [videos de misión](docs/videos-misiones.md).

Actualización: 15 de noviembre de 2026. Motor comprobado: Godot 4.7.2, GDScript, Compatibility.

## Rodaje de seis apariencias

Las seis apariencias usan `VisualRodaje`: ruedas independientes, cadena MultiMesh continua y apoyos amortiguados hasta dos píxeles. La distancia procede del movimiento físico real y conserva el sentido reflejado de la IA. Se retiró el shader exclusivo del Sherman. Recursos derivados en memoria, configuración por modelo y limitaciones de reconstrucción descritas en [docs/rodaje.md](docs/rodaje.md). La entrega hist?rica de esa fase es `builds/SecondWarNow-Rodaje-Windows-x64.zip`.

## Terreno destructible implementado

Suelo, dunas y escombros comparten un perfil deformable de 4 unidades por muestra, con bloques físicos de 128 unidades. Profundidad acumulada limitada a 80 y pendientes a 32°. Hay soporte protegido para futuras posiciones y llegada. Edificios/barricadas conservan sus reglas. Los cráteres duran toda la misión; reiniciar los elimina.

Las seis imágenes del usuario se usan directamente; el shader omite el falso damero de los JPEG, mezcla superficie/interior y conserva los fondos. No se sobrescribe ningún original. La superficie recién excavada expone tierra/grava, sin regenerar césped o pavimento. Se revisaron capturas reales con OpenGL Compatibility en la RTX 2050.

Bombardeo: espera de 1,4 segundos y excavación progresiva de 0,9 segundos con un único reloj compartido con el VFX. Daño aplicado una sola vez. Fragmentos excavan individualmente; el fuego solo excava al impacto inicial. No hay daño por caída. El controlador espera publicación/asentamiento antes del siguiente turno; la retirada y el reloj de Francia siguen inmediatamente disponibles.

Las pruebas nuevas de terreno y las regresiones de combate pasan. Las tres partidas con tiros reales y deformación activa terminan en victoria: Francia 3 disparos/27 HP, El Alamein 7 disparos/25 HP y Berlín 6 disparos/100 HP. Consultar [documentación técnica](docs/terreno-destructible.md).

## Campaña implementada

| Misión | Secuencia y objetivo | Particularidades |
|---|---|---|
| Francia | Destruir un enemigo y evacuar vivo a Dunkerque | 30 segundos visibles; al vencer llegan refuerzos, se cierra la victoria y a los 2 segundos comienza un disparo letal |
| El Alamein | Destruir la primera defensa, avanzar, destruir la segunda y alcanzar la bandera | Dunas con colisión, desniveles y dos combates sucesivos |
| Berlín | Superar la defensa urbana, avanzar, destruir la defensa final y alcanzar el objetivo | Escombros transitables, ruinas elevadas que interceptan proyectiles y epílogo de campaña |

La resistencia de Francia consiste en derrotar al enemigo inicial, sin mínimo de turnos. Es una adaptación de diseño aprobada el 12 de noviembre. Si llegada y vencimiento coinciden en una actualización, se evalúa primero la llegada. El disparo de refuerzos comienza a los 2 segundos del anuncio y tarda 0,35 segundos en alcanzar al jugador; el plazo de victoria ya está cerrado.

Los avances entre posiciones permiten movimiento sin combustible y desactivan el ataque. Al activar el segundo combate se recupera el movimiento limitado y se rellena combustible. Vida y ciclo de municiones del jugador se conservan. Cada enemigo tiene su propia Factory/ciclo. La segunda posición no existe como enemigo activo hasta cruzar su umbral, después de neutralizar la primera y terminar los efectos pendientes del disparo.

La base de nivel y los fondos se reutilizan, pero configuración táctica, apariciones, relieve, objetivos y transiciones varían por misión. El escenario mide 1800 × 1005 unidades; la cámara sigue el combate y después al jugador. Los fondos son ilustraciones y las geometrías superpuestas representan el relieve físico.

## Componentes y contratos

- `Modelos/DatosCampana.gd`: datos tácticos por misión; apariciones, activación de segunda posición (x=970), objetivos, plazo, geometría y escala de daño de IA.
- `Controladores/ControladorCombate.gd`: fases COMBATE, AVANCE, EVACUACION, REFUERZOS y RESULTADO; secuencias de disparo y condiciones de victoria/derrota.
- `Vistas/Niveles/EscenarioCampana.gd`: construye dibujo y colisión desde los mismos polígonos; no decide progreso.
- `GestorMisiones`: fichas históricas, introducción, cierre y epílogo; desbloqueo secuencial.
- `GestorGuardado`: JSON versión 3 con monedas, bonos, recibos idempotentes, migración y respaldo. Victoria, recompensa y progreso se guardan conjuntamente al alcanzar el objetivo final.
- HUD: objetivo activo, posición defensiva, combustible ilimitado durante avance y cuenta atrás exclusiva de Francia.

La IA de Francia conserva el daño base; El Alamein usa 45 % y Berlín 55 % para dos combates sin curación. Son valores iniciales sujetos a balance manual. El proyectil principal ya no desaparece en x=1400: puede recorrer todo el escenario. La dispersión ahora también se divide al impactar antes de su demora.

## Tienda y presentación

Monedas por resultado, bono único, tienda de skins y paquetes simulados COP. Cinco apariencias del jugador y una enemiga con casco/cañón separados, sin ventajas físicas. Véase [tienda y economía](docs/tienda-economia.md).

La build QA de Windows valida economía y cinco partidas completas, una por skin, con cero fallos. Se revisaron capturas de tienda, paquetes, skins y resultados. ZIP de entrega: `builds/SecondWarNow-Tienda-Monedas-Windows-x64.zip`. Pendiente la prueba humana y Windows limpio.

Cada misión tiene introducción con texto progresivo y cierre histórico. Berlín incluye un epílogo educativo. El video general de apertura y los menús ilustrados se conservan. El viewport es 1280 × 720 y se fija aspecto `keep`.

## Verificación

- `tests/test_core.gd`: regresión de navegación, Factory, turnos, joystick, impactos, VFX, retirada y progreso.
- `tests/test_pantalla_carga.gd`: introducción, menú y navegación.
- `tests/test_campana.gd`: plazo, llegada prioritaria, refuerzo letal, ausencia de refuerzos tras resultado, sucesión de enemigos, conservación de vida/ciclo, bloqueo de salida prematura, impactos de proyectiles/fragmentos y recorridos físicos completos con A/D.
- `tests/verificar_guardado.gd`: segundo proceso que verifica campaña completada y cosmético comprado/equipado desde el JSON. La suite usa un guardado aislado.
- `tests/test_partidas.gd`: juega las tres misiones con movimiento y tiros balísticos reales contra la IA, sin modificar vida, posiciones ni reloj. Resultado: Francia 3 disparos/27 HP; El Alamein 7 disparos/25 HP; Berlín 6 disparos/100 HP. Todas ganadas. El bot calcula tiros precisos; esto no mide la dificultad para una persona.

Las pruebas de reglas preparan destrucciones mediante daño controlado; la suite adicional de partidas sí gana los cinco combates disparando contra la IA. Ninguna sustituye la evaluación humana del joystick. Se generaron y revisaron capturas del renderer real mediante `previsualizar_terreno.gd`; el balance humano y la comodidad de los controles siguen pendientes.

## Entrega y pendientes

El preset `Windows x64` está en `export_presets.cfg`; utiliza plantillas locales en `.godot/plantillas/` y genera `builds/windows/SecondWarNow.exe`. No se incluyen pruebas, documentación ni herramientas en la exportación. La compilación y su estado de verificación se registran en `docs/entrega-windows.md`.

Exportación Windows release generada correctamente. La build separada `Windows x64 QA` también ganó las tres misiones con recursos exportados y scripts compilados, con cero fallos. La distribución inicia sin errores en la prueba headless. El ZIP de distribución contiene únicamente el EXE y su PCK.

La build QA ya completa las tres misiones y las pruebas de terreno con cero fallos. Sigue pendiente la validación humana y en Windows 10/11 limpio. Quedan como mejoras SFX de combate, balance y revisión histórica editorial. El terreno destructible forma parte de la ampliación aprobada del 13 de noviembre; se añadió la ampliación acordada de monedas y skins; pagos reales y NPC quedan fuera.

Los documentos `fase1_comprension.md` y `fase2_estado_actual.md` son referencias históricas, no inventarios de implementación actual.
