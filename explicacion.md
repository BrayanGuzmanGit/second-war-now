# Explicación del proyecto Second War Now

> Informe previo rediseñado: `EstiloInforme` compone la ficha con recortes del papel y marco del selector, fondos existentes y controles Oswald. `CinematicaPanel` administra escritura cancelable, revelado, repetición de video y navegación protegida; `GestorMisiones` centraliza historia/objetivos/imagen/tipo de operación. Véase [informes de misión](docs/informes-mision.md).

> Videos de misión: `VideoMision` reproduce las tres introducciones y las victorias de Francia/El Alamein desde recursos Theora/Vorbis. La ficha aparece después de la introducción y los resultados después del cierre; Berlín conserva el epílogo sin video de victoria. El controlador liquida antes de reproducir y la omisión no modifica recompensas. Véase [videos de misiones](docs/videos-misiones.md).

> Actualización del 13 de noviembre: suelo, dunas y escombros se unifican en `PerfilTerreno` y `TerrenoDestructible`. Los JPEG del usuario se muestrean mediante máscaras de shader sin modificar originales. El bombardeo excava progresivamente durante 0,9 segundos, después de la bengala de 1,4 segundos; el controlador espera la publicación de colisiones y el asentamiento. La plataforma de `suelo.tscn` ya no es física y las apariciones/curvas/cámara usan el relieve actual. Ver [terreno-destructible.md](docs/terreno-destructible.md) para los contratos vigentes, materiales y pruebas.

> Actualización de campaña, 12 de noviembre de 2026: el recorrido por posiciones y las reglas vigentes se detallan en [estado.md](estado.md). La escena base se comparte, pero cada misión tiene datos tácticos y geometría propios. Francia tiene evacuación de 30 segundos y refuerzo letal; El Alamein/Berlín tienen dos defensas sucesivas. Los apartados originales de funciones se conservan como referencia; las nuevas funciones de fase se describen a continuación.

## Fases de campaña y nuevos componentes

`Modelos/DatosCampana.gd` separa los datos tácticos de la presentación: apariciones, activación, geometrías, objetivos, daño de IA y plazo. `Vistas/Niveles/EscenarioCampana.gd` genera obstáculos visibles con colisiones a partir de esos puntos. Las dunas y rampas de escombros se recorren con A/D; las ruinas elevadas bloquean proyectiles y dejan paso al tanque por debajo.

`ControladorCombate._actualizar_fase(delta)` evalúa primero la victoria, después activa la segunda defensa o actualiza la cuenta atrás. `_iniciar_siguiente_posicion()` crea el segundo enemigo y su gestor sin curar al jugador ni reiniciar sus municiones. `_iniciar_refuerzos()` cierra la victoria y bloquea el control; `_disparar_refuerzo()` comienza la animación letal tras dos segundos. `_actualizar_objetivo()` sincroniza fase/posición con el HUD. Los callbacks anteriores se invalidan mediante una secuencia y la segunda posición espera a que terminen los efectos del disparo anterior.

El HUD añade `actualizar_objetivo()` y `actualizar_cuenta_atras()`. `GestorMisiones` incorpora textos de introducción y epílogo. El esquema se amplió a versión 3 con monedas y recibos; véase [economía](docs/tienda-economia.md). `test_campana.gd` comprueba transiciones, recorridos físicos, impactos y persistencia desde otro proceso mediante `verificar_guardado.gd`.

## 1. Para qué sirve este documento

Esta guía describe la versión actual del proyecto Godot: cómo comienza una partida, cómo se relacionan las escenas, qué responsabilidad tiene cada script, qué hacen sus funciones y dónde se configuran los recursos. Está escrita para que una persona nueva pueda orientarse antes de cambiar código.

El proyecto es un videojuego 2D educativo, de estrategia y combate por turnos, ambientado en la Segunda Guerra Mundial. El jugador selecciona una misión, consulta una ficha histórica y combate con un tanque. El combate combina movimiento limitado por combustible durante el enfrentamiento, movimiento ilimitado en la retirada, disparo balístico, una IA, cinco clases de munición, objetivos de misión y progreso persistente.

La arquitectura sigue una adaptación práctica de MVC a Godot:

- **Vistas:** escenas `.tscn`, sus nodos y la interfaz.
- **Controladores y servicios:** coordinan el combate, crean proyectiles, ofrecen el catálogo y administran la campaña y el guardado.
- **Entidades:** scripts acoplados a nodos físicos de Godot, como `CharacterBody2D` y `Area2D`.
- **Datos:** `Modelos/DatosCampana.gd` define la configuración táctica independiente de nodos; el resto de catálogos utiliza diccionarios y constantes.

## 2. Cómo inicia y cómo se recorre el juego

### Inicio del proyecto

[`project.godot`](project.godot) configura el inicio en `res://Vistas/UI/PantallaCarga.tscn`, los Autoloads, controles, viewport de 1280 × 720 y estiramiento `canvas_items` con aspecto `keep`. El preset exclusivo de QA cambia el arranque a `tests/InicioQA.tscn`; la distribución normal conserva el video.

Antes de ejecutar la escena principal, Godot crea estos Autoloads:

1. **`GameConfig`** aporta constantes compartidas, en particular la gravedad.
2. **`GestorGuardado`** carga o crea el estado de campaña y cosméticos.
3. **`GestorMisiones`** ofrece el catálogo de misiones y conserva el identificador de la misión elegida durante la ejecución.
4. **`Tienda`** ofrece el catálogo de cosméticos y delega su persistencia al gestor de guardado.

Los Autoloads están registrados en `project.godot`; por eso las escenas y scripts pueden consultar nombres como `GestorMisiones` y `GestorGuardado` sin instanciarlos manualmente.

### Flujo del jugador

1. `PantallaCarga.tscn` reproduce la introducción de diez segundos mientras carga en segundo plano la escena del menú. El porcentaje combina el progreso real de carga de esa escena con el tiempo de la introducción. En los últimos segundos instancia el menú sobre el video y revela sus botones en secuencia; al terminar, congela visualmente un fotograma y conserva el sonido del reproductor en bucle a volumen reducido. La pantalla de carga sigue siendo la escena activa para que el video y el menú compartan una transición continua.
2. El menú principal permite seleccionar una misión, abrir la tienda o salir.
3. La selección de misiones consulta `GestorMisiones`; las misiones bloqueadas aparecen desactivadas.
4. Al escoger una misión disponible, se guarda como misión actual y aparece el panel informativo histórico.
5. El panel carga nombre, fecha, ubicación y descripción de la misión. Al continuar, abre la escena común `Niveles/nivel_1.tscn`.
6. El controlador de combate conecta las señales de tanques y HUD, presenta la paleta correspondiente, refresca la interfaz e inicia el turno del jugador.
7. El jugador puede moverse con A/D, arrastrar la perilla del joystick virtual fijo en la esquina inferior izquierda para ajustar ángulo y potencia, elegir munición disponible desde el selector compacto de la esquina superior derecha y disparar con clic izquierdo fuera del joystick o Espacio. El HUD consume los eventos del arrastre para evitar disparos accidentales. Al soltar, conserva el último apuntado y la trayectoria parcial; el turno del jugador termina al disparar.
8. El proyectil vuela, impacta o termina su recorrido; si el tanque enemigo sigue activo, comienza la respuesta de IA. La IA se reposiciona, dispara y, al resolverse el proyectil, devuelve el turno al jugador.
9. Al destruir la primera defensa, el movimiento pasa a ser ilimitado. Francia inicia su evacuación de 30 segundos. En El Alamein/Berlín se avanza hasta el umbral de la segunda defensa; al llegar, se activa otro combate conservando vida y munición del jugador.
10. Tras superar todas las defensas, entrar vivo en `ZonaEvacuacion` produce victoria. La detección usa intersección física y respaldo geométrico. Francia exige llegar antes del plazo; al vencerlo aparece un refuerzo, se bloquea la victoria y tras dos segundos se dispara un ataque letal. Las demás misiones no tienen plazo.
11. Al finalizar, el controlador solicita a `GestorGuardado` liquidar la partida: recompensa y, al ganar, misión completada y bono. El HUD pone el panel de resultado en primer plano y mantiene el mensaje hasta que se pulse volver a misiones. Si se destruye el tanque del jugador, se muestra la derrota y el mismo botón regresa a la selección de misiones.

### Turnos en una partida

El controlador mantiene el estado de quién puede jugar y si hay un proyectil sin resolver. El HUD expresa ese estado con una etiqueta y desactiva el selector durante la acción enemiga o el vuelo del proyectil. El turno cambia automáticamente después de resolverse el disparo; el combustible se repone cuando vuelve el turno del jugador. Los cambios de vida, combustible, disparo, destrucción y selección de munición se comunican con señales; el HUD presenta el resultado, pero no decide las reglas.

## 3. Componentes globales y persistencia

### [`Autoloads/GameConfig.gd`](Autoloads/GameConfig.gd) — clase `GameConfig`

Servicio global mínimo. Su constante `GRAVEDAD` es el valor compartido por el jugador, la IA, los proyectiles y los fragmentos. Centralizarla evita que las ecuaciones balísticas usen aceleraciones distintas.

### [`Autoloads/GestorGuardado.gd`](Autoloads/GestorGuardado.gd) — clase `GestorGuardado`

Mantiene el guardado JSON versión 3: campaña, inventario, equipamiento, monedas, bonos cobrados y recibos de operaciones. Migra v1/v2 sin perder compras. La bienvenida se entrega una sola vez y los bonos anteriores no se pagan retroactivamente.

- `cargar_progreso()`: valida, migra y recupera respaldo; si ambos archivos son inválidos bloquea escrituras y conserva el original.
- `guardar_progreso()`: escribe temporal, conserva respaldo válido y renombra al destino.
- `comprar_cosmetico(id, operacion)`: descuenta y concede propiedad en una escritura.
- `comprar_paquete(id, operacion)`: acredita monedas de la simulación.
- `liquidar_partida(operacion, mision, victoria, defensas)`: confirma resultado, recompensa y bono juntos. Repetir el recibo no vuelve a pagar.
- `registrar_mision_completada()`: compatibilidad de herramientas; las partidas usan liquidación.
- `registrar_cosmetico_comprado()`: compatibilidad que cobra el precio en monedas.
- `reiniciar_progreso_misiones()`: conserva saldo, inventario, equipamiento, bonos y recibos.
- `equipar_cosmetico()`: requiere propiedad y revierte el equipamiento si no puede guardarlo.

Detalles de API, reglas y arte: [tienda y economía](docs/tienda-economia.md).

### [`Autoloads/GestorMisiones.gd`](Autoloads/GestorMisiones.gd) — clase `GestorMisiones`

Contiene el arreglo constante `MISIONES`, formado por los diccionarios de Francia, El Alamein y Berlín. Cada entrada aporta identificador, nombre, año, lugar, fecha, descripción, resumen histórico, paleta y ruta de escena. En la versión actual las tres rutas señalan a la misma escena de combate.

Funciones:

- `_normalizar_progreso_campana()`: conserva solo una secuencia contigua de misiones completadas y migra los guardados antiguos que almacenaban misiones desbloqueadas.
- `obtener_misiones()`: devuelve copias del catálogo y añade a cada misión un booleano `desbloqueada`; Francia está disponible desde el inicio y cada misión posterior requiere completar la anterior.
- `obtener_mision(id_mision)`: busca y devuelve una copia del registro; registra error si el identificador no existe.
- `obtener_mision_actual()`: busca el identificador almacenado en `id_mision_actual`.
- `seleccionar_mision(id_mision)`: comprueba que la misión existe y esté desbloqueada; entonces actualiza la misión actual.
- `completar_mision_actual()`: valida que la misión actual esté desbloqueada y la registra como completada en `GestorGuardado`. El menú deriva el siguiente desbloqueo de este progreso; completar Berlín no intenta desbloquear una cuarta misión.

### [`Controladores/Tienda.gd`](Controladores/Tienda.gd) — servicio global `Tienda`

Ofrece cinco skins del jugador con precios en monedas y paquetes simulados COP. Delega compras/equipamiento al guardado. El catálogo visual común contiene ENM-01 solo para la IA. No hay cobros reales.

Funciones:

- `obtener_catalogo()`: devuelve copias enriquecidas con los estados `comprado` y `equipado` leídos del progreso.
- `procesar_compra_simulada(id_cosmetico)`: valida el identificador y delega el registro en `GestorGuardado`.
- `equipar_cosmetico(id_cosmetico)`: valida el artículo y delega el equipamiento persistente.
- `comprar_cosmetico(id, operacion)` y `comprar_paquete(id, operacion)`: compras idempotentes.
- `obtener_paquetes()`: cantidades y precios ficticios COP.

## 4. Combate y entidades

### [`Controladores/ControladorCombate.gd`](Controladores/ControladorCombate.gd) — coordinador de combate

Se adjunta al nodo `ControladorCombate` dentro de `nivel_1.tscn`. Sus referencias `@onready` conectan los tanques, los dos gestores de proyectiles, el HUD y el marcador del objetivo. Las variables privadas representan combate finalizado, proyectil en vuelo, turno activo, munición elegida y destrucción del enemigo.

Funciones:

- `_ready()`: conecta señales, obtiene la misión, actualiza el HUD, aplica el tinte guardado, configura la paleta e inicia el turno del jugador.
- `_process(delta)`: actualiza la cámara siguiendo el punto medio de los tanques durante el combate o al jugador durante la retirada; también comprueba la condición de victoria.
- `_disparar_jugador(origen, velocidad)`: valida el estado, turno y munición; durante la retirada rechaza el ataque y conserva el control de movimiento. En combate, termina el turno y pide crear el proyectil del jugador. Si se recibe una selección antigua que ya se consumió, sincroniza la munición disponible y conserva el turno.
- `_lanzar_proyectil(origen, velocidad, emisor, es_turno_jugador, tipo, gestor)`: usa la Factory correspondiente, registra el tipo usado, añade el proyectil al árbol, establece su posición global de origen y lo configura. Si falla la creación o el registro, restablece una situación jugable en vez de dejar el turno bloqueado.
- `_mostrar_efecto_salida(origen, velocidad, tipo)`: instancia el fogonazo procedural después de validar la munición y el ciclo; lo orienta desde el marcador de disparo hacia la velocidad inicial. Se aplica igual a jugador e IA.
- `_al_finalizar_proyectil(es_turno_jugador)`: libera el estado de vuelo y encadena la acción siguiente: turno de IA tras el disparo del jugador, o turno del jugador cuando termina el proyectil enemigo. Si el enemigo ya fue neutralizado, conserva la fase de retirada en vez de reactivar el ciclo de combate.
- `_iniciar_turno_ia()`: cede el turno, actualiza el HUD, espera brevemente, espera el reposicionamiento de la IA y calcula su disparo al punto de colisión del jugador. Selecciona la primera munición disponible de su ciclo.
- `_seleccionar_municion(tipo)`: solo acepta cambios durante el turno del jugador y cuando el tipo está disponible.
- `_actualizar_municion_hud()`: mantiene sincronizados selección/disponibilidad del HUD, multiplicador de munición del tanque y curva de apuntado. Si la selección quedó consumida, cambia a la primera munición disponible. Se invoca también al cambiar munición durante el turno, de modo que la trayectoria se refresca inmediatamente.
- `_al_destruir_jugador()`: finaliza el combate como derrota.
- `_al_destruir_enemigo()`: activa la condición de enemigo neutralizado, cambia el HUD a retirada, deshabilita el selector ofensivo, habilita inmediatamente el movimiento ilimitado y presenta el objetivo; no espera a que terminen los efectos visuales del proyectil.
- `_activar_fase_retirada()`: mantiene habilitado el movimiento del tanque, pero informa al HUD que ya no existe un turno de combate y deja desactivados los controles de ataque.
- `_finalizar_combate(victoria)`: evita resoluciones repetidas, detiene el turno, liquida monedas y progreso de forma conjunta y presenta resultado con recompensa y reintento. La pantalla de victoria o derrota permanece visible hasta que el jugador pulsa el botón para volver a la selección de misiones; así el resultado no desaparece por un cambio de escena automático.
- `_configurar_fondo(paleta)`: muestra exclusivamente la ilustración de mapa asociada a Francia, El Alamein o Berlín, aplica los límites de cámara de 1800 × 1005 y coloca inicialmente la cámara entre los tanques.
- `_actualizar_camara(delta)`: desplaza suavemente la cámara con límites del mapa; el zoom mantiene el área visible menor que el terreno ampliado.
- `_volver_al_menu()`: cambia a la selección de misiones (`MenuMisiones.tscn`) y reporta un error si la transición falla.
- `_activar_turno_jugador(mensaje)`: habilita jugador, repone combustible, actualiza munición, activa el HUD e informa el objetivo inmediato.
- `_recuperar_turno_jugador(mensaje)`: limpia el indicador de proyectil y devuelve el control al jugador cuando la IA no puede continuar.
- `_seleccionar_siguiente_municion_disponible(disponibles)`: conserva la selección si sigue siendo válida; de lo contrario, elige la primera opción del ciclo, garantizando que el jugador no se quede sin una munición seleccionada.

### [`Controladores/GestorProyectiles.gd`](Controladores/GestorProyectiles.gd) — clase `GestorProyectiles`, Factory

Responsable único de instanciar munición. `ESCENAS_PROYECTILES` enlaza cada clave textual con una escena y `MULTIPLICADORES_POTENCIA` define el cambio de velocidad para cada tipo. Cada tanque de la escena recibe su propia instancia de este gestor, por lo que mantiene un ciclo independiente.

Funciones:

- `crear_proyectil(tipo)`: valida el tipo y su disponibilidad, instancia la escena, comprueba el tipo resultante y aplica el multiplicador.
- `obtener_multiplicador_potencia(tipo)`: consulta la tabla de potencia; informa si la clave no está definida.
- `esta_disponible(tipo)`: confirma que el tipo exista y todavía no se haya usado en el ciclo.
- `registrar_uso(tipo)`: añade el tipo al ciclo; una vez usados los cinco, vacía la lista para iniciar un nuevo ciclo.
- `obtener_disponibles()`: devuelve todas las municiones que se pueden seleccionar o disparar en el ciclo actual.

La Factory continúa siendo la única responsable de crear munición. El campo `tipo_visual` de cada escena selecciona geometría, color y rastro animado durante el vuelo; solo modifica presentación.

### [`Scripts/Tanques/VisualTanque.gd`](Scripts/Tanques/VisualTanque.gd) y [`Scripts/Tanques/VisualRodaje.gd`](Scripts/Tanques/VisualRodaje.gd)

`VisualTanque` es el rig visual compartido por el jugador y la IA; queda como hijo independiente del cuerpo físico y no modifica `CharacterBody2D`, hitboxes ni reglas de combate. Sus dos capas se generan desde `Imagenes/TanqueM4Sherman.png`: el casco usa una copia sin el rectángulo del cañón y la capa del cañón contiene únicamente esa pieza. El original permanece intacto y es la referencia de la hitbox.

- `_ready()`: asigna las dos texturas derivadas, calcula el pivote del cañón en coordenadas del arte fuente, compensa la escala y el volteo horizontal de la IA y coloca `PuntoDisparo` en la boca.
- `apuntar_canon(direccion_global)`: orienta el pivote hacia el vector recibido. En el jugador el vector procede del joystick manual; la IA usa su velocidad de disparo calculada. El pivote y el marcador rotan juntos.
- `actualizar_movimiento(delta, desplazamiento_real, en_suelo, normal_suelo)`: transmite el desplazamiento posterior a la física y los límites del mapa. `VisualRodaje` proyecta la distancia sobre la superficie, mueve ruedas/orugas e interpola los apoyos.
- `aplicar_tinte(color)`: aplica el mismo cosmético o tinte al rig completo.

`DatosRodaje` contiene medidas de las seis apariencias. `pieza_rodaje.gdshader` separa visualmente las capas de las fuentes; las ruedas son sprites independientes y las cadenas usan MultiMesh. Se retiró el shader exclusivo del Sherman. Véase [rodaje](docs/rodaje.md) para los recortes, reconstrucción visual, límites y verificación. No cambian las colisiones, la montura ni la boca balística.

La herramienta [`tools/generate_tank_visual_layers.gd`](tools/generate_tank_visual_layers.gd) recrea las dos imágenes derivadas a partir del sprite original. Si cambia el arte fuente o las coordenadas del cañón, se deben revisar `REGION_CANON`, el pivote, la boca y los centros de rueda antes de regenerarlas.

### [`Scripts/Tanques/Tanque.gd`](Scripts/Tanques/Tanque.gd) — clase base `Tanque`

Hereda de `CharacterBody2D` y reúne la salud y los eventos comunes del jugador y la IA.

- Señal `vida_actualizada(actual, maxima)`: notifica cambios de salud al HUD.
- Señal `tanque_destruido`: notifica que la salud llegó a cero.
- `_ready()`: genera la hitbox desde la silueta alfa del arte fuente completo, agrega el tanque al grupo `tanques`, establece la salud inicial y emite su valor.
- `_ajustar_hitbox_al_sprite()`: conserva `CollisionShape2D` rectangular desactivado como referencia para centro y ancho, y crea `CollisionPolygon2D` físicos a partir de `BitMap.opaque_to_polygons()` sobre la textura fuente original. Usa umbral alfa 0.15, simplificación de 2 píxeles y descarta contornos menores de 12 píxeles cuadrados. También transforma cada punto teniendo en cuenta el recorte de la textura, centrado, offset, escala y volteos del sprite; separar el cañón visual no reduce la silueta de colisión.
- `_transformar_puntos_de_silueta(puntos_textura, tamano_textura, origen_textura)`: convierte las coordenadas del rectángulo de la máscara al espacio local del tanque. El origen compensa que los polígonos de `opaque_to_polygons()` se expresan respecto al rectángulo consultado.
- `_calcular_area_poligono(puntos)`: calcula el área con la fórmula del cordón para filtrar contornos demasiado pequeños.
- `recibir_dano(cantidad)`: ignora daño no positivo o aplicado a un tanque ya destruido; actualiza salud y emite el cambio. Al llegar a cero, marca la unidad destruida, desactiva las colisiones físicas e inicia la presentación visual antes de emitir la señal de destrucción, sin esperar a que finalice la animación.
- `recibir_impacto_proyectil(cantidad, posicion_global, direccion_impacto, tipo_proyectil)`: contrato común para el impacto directo y el daño de área. Solicita el VFX correspondiente a la munición y delega una sola aplicación de daño a `recibir_dano()`; el tipo visual no cambia el cálculo de salud.
- `_mostrar_efecto_impacto(posicion_global, direccion_impacto, tipo_proyectil)`: instancia el efecto visual reutilizable en la escena actual y lo coloca en el punto de contacto; no decide el daño.
- `_iniciar_animacion_destruccion()`: detiene la física de la unidad, mantiene el tanque visible como resto, instancia una explosión breve y anima el destello, oscurecimiento, inclinación y caída del sprite mediante tweens no bloqueantes.
- `obtener_punto_impacto_global()`: devuelve la posición global de la forma de colisión, útil para que la IA apunte al cuerpo físico y no al origen visual del tanque.
- `obtener_punto_frontal_global()`: calcula el borde delantero de la colisión. El controlador lo compara con el marcador para activar la evacuación cuando el tanque llega físicamente a la bandera, sin requerir que su centro la sobrepase.

### [`Scripts/Tanques/EfectoExplosionTanque.gd`](Scripts/Tanques/EfectoExplosionTanque.gd) y [`Vistas/Efectos/ExplosionTanque.tscn`](Vistas/Efectos/ExplosionTanque.tscn)

La escena reutilizable dibuja una explosión procedural breve y sus chispas. El script actualiza el progreso con `_process()`, redibuja el efecto y elimina el nodo al terminar su duración; el tanque enemigo y el jugador usan colores distintos. El efecto es decorativo: no pausa el combate ni retrasa las señales de daño, destrucción o cambio de fase.

### [`Scripts/Tanques/EfectoImpactoTanque.gd`](Scripts/Tanques/EfectoImpactoTanque.gd) y [`Vistas/Efectos/ImpactoTanque.tscn`](Vistas/Efectos/ImpactoTanque.tscn)

Efecto procedural breve y reutilizable para impactos de proyectil. Recibe dirección y tipo de munición. El estándar produce un destello de penetración; el pesado una explosión amplia; dispersión un anillo con fragmentos; bombardeo una señal circular intensa; e incendiario una llamarada. Es únicamente presentación: la salud se gestiona en `Tanque`, y el daño periódico incendiario no genera una explosión nueva por cada tick.

### [`Scripts/Proyectiles/EfectoSalidaProyectil.gd`](Scripts/Proyectiles/EfectoSalidaProyectil.gd) y [`Vistas/Proyectiles/EfectoSalidaProyectil.tscn`](Vistas/Proyectiles/EfectoSalidaProyectil.tscn)

VFX reutilizable que `ControladorCombate` crea en el marcador de disparo tras validar la creación y el registro en la Factory. Se orienta hacia la velocidad y desaparece en 0,2 segundos. Sus variantes son fogonazo estrecho para munición estándar, destello con onda para pesado, abanico de chispas para dispersión, bengala radial para bombardeo y llamarada alargada para incendiario. No participa en el movimiento ni aplica daño.

### [`Scripts/Proyectiles/EfectoZonaIncendiada.gd`](Scripts/Proyectiles/EfectoZonaIncendiada.gd) y [`Vistas/Proyectiles/EfectoZonaIncendiada.tscn`](Vistas/Proyectiles/EfectoZonaIncendiada.tscn)

Presentación ambiental para la munición incendiaria: crea un anillo de fuego y llamas animadas en el punto de impacto. Su radio coincide con el área de la munición y su duración con los ticks de daño configurados. El VFX no inflige daño y se crea una sola vez; los ticks periódicos no repiten fogonazos.

### [`Scripts/Tanques/TanqueJugador.gd`](Scripts/Tanques/TanqueJugador.gd) — clase `TanqueJugador`

Extiende el tanque base. Administra combustible, entradas, turno del jugador y previsualización balística. Sus señales informan al controlador de disparos.

- `_ready()`: inicializa combustible y oculta la trayectoria hasta que el jugador tenga el turno.
- `_physics_process(delta)`: aplica gravedad si el tanque está en el aire, lee A/D únicamente durante el turno y con combustible (o durante retirada ilimitada), consume combustible proporcional al movimiento durante el combate, usa `move_and_slide()`, actualiza la animación visual según el desplazamiento horizontal real y recalcula la trayectoria únicamente cuando se puede atacar.
- `_unhandled_input(event)`: solicita disparo con Espacio o clic izquierdo. En retirada ignora el disparo sin desactivar el movimiento del jugador.
- `aplicar_cosmetico(id_cosmetico)`: aplica casco/cañón propios a la geometría común.
- `iniciar_turno()`: repone el combustible y activa los controles.
- `terminar_turno()`: desactiva los controles y oculta la línea de apuntado.
- `refrescar_apuntado()`: recalcula y dibuja inmediatamente la curva si el tanque conserva el turno; se utiliza al cambiar el multiplicador de munición.
- `actualizar_apuntado_joystick(vector)`: conserva el vector normalizado emitido por el HUD y recalcula el apuntado durante el turno.
- `_actualizar_apuntado()`: convierte el ángulo del vector en la dirección del proyectil y su longitud en potencia entre los límites configurados. Aplica el multiplicador de la munición, orienta el cañón y calcula el tiempo de vuelo previsto hasta el suelo.
- `_calcular_tiempo_hasta_suelo(origen, velocidad)`: usa la altura superior de la colisión del suelo para estimar el vuelo de la trayectoria; conserva una altura de referencia si la escena no declara el suelo.
- `_dibujar_trayectoria(origen, velocidad)`: muestrea el tramo inicial (62 %) de la parábola usando la gravedad compartida y transforma sus puntos al espacio local de `LineaTrayectoria`. No altera la velocidad ni la trayectoria real del proyectil.

### [`Scripts/Tanques/TanqueIA.gd`](Scripts/Tanques/TanqueIA.gd) — clase `TanqueIA`

Extiende el tanque base con movimiento automático acotado y una solución sencilla de disparo. Su movimiento se detiene si llega al destino, choca lateralmente o alcanza el límite de tiempo.

- `_physics_process(delta)`: aplica gravedad, ejecuta el movimiento horizontal temporal de reposicionamiento y actualiza la animación visual según el desplazamiento horizontal real.
- `mover_en_turno(posicion_objetivo)`: calcula un destino relativo al jugador, limita el desplazamiento del turno y espera a que el movimiento termine o sea interrumpido.
- `calcular_disparo(posicion_objetivo, multiplicador)`: recalcula iterativamente la potencia y el origen desde la boca según distancia, altura, gravedad y ángulo fijo; orienta el cañón hacia la velocidad final y compensa el multiplicador para que el Factory lo aplique una sola vez.

## 5. Proyectiles

### [`Scripts/Proyectiles/Proyectil.gd`](Scripts/Proyectiles/Proyectil.gd) — clase `Proyectil`

Comportamiento común de las escenas de munición. Hereda de `Area2D`; la configuración de cada escena determina daño, radio, retraso, daño periódico, número de fragmentos y otros parámetros.

- `_ready()`: conecta la detección de cuerpos y configura la silueta visual de acuerdo con `tipo_visual`.
- `configurar(nueva_velocidad, tanque_emisor, dano)`: guarda la velocidad efectiva, el tanque que disparó, actualiza la orientación del proyectil y, opcionalmente, un daño explícito.
- `_process(delta)`: anima el rastro dibujado según el tipo de munición; no cambia el movimiento físico.
- `_physics_process(delta)`: avanza el proyectil con la fórmula de movimiento acelerado por gravedad, orienta el cuerpo hacia su velocidad y consulta con un rayo el segmento recorrido durante el paso; divide munición de dispersión al cumplirse su demora y elimina proyectiles que salen del área.
- `_configurar_visual()`: selecciona geometría y color del cuerpo para cada tipo: punta perforante, carga pesada, cápsula de dispersión, bengala o llama.
- `_draw()`: dibuja un rastro animado diferente por tipo de munición detrás del proyectil en vuelo.
- `_al_entrar_en_cuerpo(cuerpo)` y `_resolver_impacto(cuerpo, posicion_impacto)`: convergen la señal física y el raycast en un solo punto de resolución. El raycast conserva el punto exacto del contacto y las banderas evitan duplicar el impacto.
- `_dividirse()`: oculta el proyectil principal, genera la cantidad indicada de fragmentos en abanico y espera a que todos concluyan.
- `_al_finalizar_fragmento()`: descuenta fragmentos pendientes y termina el proyectil padre cuando no quede ninguno.
- `_impactar(cuerpo, posicion_impacto)`: espera la demora configurada (bombardeo), envía el daño directo de los tanques al contrato `recibir_impacto_proyectil()`, aplica daño de área y ejecuta los ticks incendiarios que correspondan.
- `_crear_efecto_zona_incendiada(posicion_impacto)`: instancia una única animación persistente para mostrar la zona incendiada mientras se aplica el daño periódico.
- `_aplicar_dano_area(objetivo_directo, dano, posicion_impacto, mostrar_efecto)`: busca tanques del grupo `tanques` dentro del radio medido desde el punto de impacto y excluye emisor/objetivo directo para no duplicar daño. Los impactos de área iniciales muestran VFX; los ticks de daño periódico pasan `mostrar_efecto = false`.
- `_finalizar()`: emite `finalizado` una sola vez y elimina el nodo.

### [`Scripts/Proyectiles/FragmentoProyectil.gd`](Scripts/Proyectiles/FragmentoProyectil.gd) — clase `FragmentoProyectil`

Entidad física de cada fragmento generado por la munición de dispersión.

- `_ready()`: añade el fragmento al grupo `fragmentos` y conecta la detección de cuerpos.
- `configurar(origen, nueva_velocidad, tanque_emisor, dano_fragmento)`: inicializa posición, velocidad, emisor y daño.
- `_physics_process(delta)`: integra la gravedad, barre con un raycast el segmento recorrido para evitar atravesar cuerpos entre pasos y elimina el fragmento al exceder el tiempo de vida o salir por abajo del escenario.
- La orientación del fragmento se actualiza con su velocidad y su silueta pequeña se distingue del proyectil portador; cuando golpea, usa la variante de impacto de dispersión.
- `_al_entrar_en_cuerpo(cuerpo)` y `_resolver_impacto(cuerpo, posicion_impacto)`: ignoran al emisor, aplican daño y efecto visual al tanque en el punto de contacto, y finalizan el fragmento.
- `_finalizar()`: emite `finalizado` y elimina el fragmento una sola vez.

### Escenas de munición

Las escenas se ubican en `Vistas/Proyectiles/` y comparten el script `Proyectil.gd`. Definen una forma de detección (`CollisionShape2D`), un dibujo visual sencillo y los parámetros que diferencian cada munición:

| Escena | Comportamiento configurado |
|---|---|
| `ProyectilEstandar.tscn` | Punta estilizada y rastro fino; fogonazo/impacto de penetración; daño y radio base. |
| `ProyectilPesado.tscn` | Cuerpo ancho y rastro denso; salida con onda e impacto expansivo; mayor daño, radio mayor y potencia reducida. |
| `ProyectilDispersion.tscn` | Cuerpo con anillo y rastro de puntos; salida en abanico; se divide en cinco fragmentos que vuelan en direcciones distintas. |
| `ProyectilBombardeo.tscn` | Cuerpo brillante de bengala, rastro luminoso y salida radial; al contactar emite círculos pulsantes que marcan la zona durante la espera antes del daño de área grande. |
| `ProyectilIncendiario.tscn` | Cuerpo y rastro de llama; salida de fuego e impacto incendiario; zona de fuego persistente con daño de área por ticks temporizados. |
| `FragmentoProyectil.tscn` | Escena física ligera reutilizada por la dispersión. |

El valor de potencia de cada munición se centraliza en `GestorProyectiles`; daño y efectos se configuran en sus escenas.

## 6. Interfaz y navegación

### Menú principal

- [`Vistas/UI/MenuPrincipal.tscn`](Vistas/UI/MenuPrincipal.tscn) usa la imagen de menú completa [`Gemini_Generated_Image_c1mwl4c1mwl4c1mw.jpeg`](Gemini_Generated_Image_c1mwl4c1mwl4c1mw.jpeg), que incluye título, subtítulo, placas de misión/tienda/salida y la ilustración del tanque. Tres botones transparentes se alinean con esas placas y conservan sus áreas de clic y foco sin duplicar los textos del arte.
- [`Vistas/UI/MenuPrincipal.gd`](Vistas/UI/MenuPrincipal.gd), clase `MenuPrincipal`, conecta las zonas interactivas. `_ready()` registra eventos; `preparar_para_aparicion()` inicia el fondo y las zonas transparentes; `iniciar_animacion_aparicion()` realiza el fundido escalonado; `_al_terminar_aparicion()` habilita las entradas; `_animar_estado_boton()` amplía y resalta suavemente la placa bajo el cursor; `_iniciar_juego()` abre la selección de misiones; `_abrir_tienda()` abre la tienda; `_salir()` termina el árbol de escenas.

### Selección de misiones

- [`Vistas/UI/MenuMisiones.tscn`](Vistas/UI/MenuMisiones.tscn) utiliza [`Gemini_Generated_Image_eio3aseio3aseio3.jpeg`](Gemini_Generated_Image_eio3aseio3aseio3.jpeg) como fondo de campaña y superpone controles opacos en la posición de las placas dibujadas en la referencia para que los textos antiguos no dupliquen ni falseen el progreso actual. Usa la fuente condensada Oswald en peso 700, licenciada bajo SIL Open Font License y distribuida con [`Vistas/Recursos/Fuentes/OFL-Oswald.txt`](Vistas/Recursos/Fuentes/OFL-Oswald.txt), para aproximar la tipografía del arte. Las placas dinámicas conservan una paleta arena/bronce; los botones de misión bloqueados usan un estilo oscuro y atenuado. La escena también contiene volver, reiniciar campaña y su diálogo de confirmación.
- [`Vistas/UI/MenuMisiones.gd`](Vistas/UI/MenuMisiones.gd), clase `Control`, obtiene el estado de campaña y actualiza cada botón al entrar y después de reiniciar. Muestra `Disponible`, `Completada` o `Bloqueada`; las bloqueadas están deshabilitadas, atenuadas y explican que se debe completar la anterior. `_iniciar_mision(id_mision)` vuelve a validar el desbloqueo en `GestorMisiones` antes de abrir la ficha histórica. `_reiniciar_misiones()` solicita a `GestorGuardado` borrar solo las misiones completadas y actualiza la lista; muestra un estado explícito si el guardado falla. `_regresar()` vuelve al menú principal.

### Ficha histórica

- [`Vistas/UI/CinematicaPanel.tscn`](Vistas/UI/CinematicaPanel.tscn) define un panel, datos de misión y botón Continuar.
- [`Vistas/UI/CinematicaPanel.gd`](Vistas/UI/CinematicaPanel.gd), clase `Control`, rellena la ficha en `_ready()`. `_mostrar_texto()` revela gradualmente el texto; `_continuar()` abre la escena de combate.

### Tienda

- [`Vistas/UI/Tienda.tscn`](Vistas/UI/Tienda.tscn) dispone el catálogo, estado y botón de regreso.
- [`Vistas/UI/Tienda.gd`](Vistas/UI/Tienda.gd), clase `Control`, crea botones de catálogo a partir de `Tienda.obtener_catalogo()`. `_actualizar_catalogo()` regenera la lista y muestra si un artículo está equipado, comprado o disponible. `_seleccionar_cosmetico(id_cosmetico)` cambia la vista previa; la acción confirma la compra con monedas u ofrece equipar; `_regresar()` vuelve al menú.

### Pantalla de carga inicial

- [`Vistas/UI/PantallaCarga.tscn`](Vistas/UI/PantallaCarga.tscn) ocupa el viewport con el video Theora, el título, el progreso, el fotograma estático de transición y la interfaz de carga.
- [`Vistas/UI/PantallaCarga.gd`](Vistas/UI/PantallaCarga.gd) inicia el video y solicita la carga asíncrona de `MenuPrincipal.tscn`. Combina el progreso real de esa escena con los diez segundos de introducción. En el tramo final instancia el menú y baja gradualmente el volumen; cuando terminan las animaciones, copia el fotograma actual sobre el video y oculta el reproductor visual sin detenerlo. El reproductor sigue en bucle a -18 dB para conservar el audio ambiente sin cambiar de escena. Si la carga o captura de imagen falla, presenta el error y habilita reintentar.
- [`Vistas/Recursos/IntroduccionCarga.ogv`](Vistas/Recursos/IntroduccionCarga.ogv) es la copia en Ogg Theora que reproduce nativamente Godot. El archivo MP4 original se conserva en la raíz del proyecto como fuente; no es el recurso que usa el reproductor.

### HUD del combate

- [`Vistas/UI/HUD.tscn`](Vistas/UI/HUD.tscn) agrupa el panel informativo compacto y semitransparente inspirado en la referencia visual, con jerarquía tipográfica y filas uniformes para los datos dinámicos; también contiene el selector compacto de munición arriba a la derecha con opciones desplegables hacia abajo y el panel de resultado.
- [`Vistas/UI/HUD.gd`](Vistas/UI/HUD.gd), clase `HUD`, emite señales para que el controlador procese elecciones y acciones. `_ready()` conecta botones; `actualizar_estado()` cambia el mensaje; `actualizar_turno()` refleja el turno activo y habilita/deshabilita controles; `actualizar_mision()`, `actualizar_vida_jugador()`, `actualizar_combustible()` y `actualizar_vida_enemigo()` refrescan indicadores; `mostrar_aviso_retirada()` actualiza el indicador de combustible e introduce con una animación el mensaje histórico de retirada; `actualizar_municion()` actualiza la selección y disponibilidad; `_actualizar_botones_municion()` actualiza iconos y estados disponible/seleccionada/agotada; `_alternar_menu_municion()` abre/cierra el selector desplegable; `_seleccionar_municion()` emite la petición y cierra el menú; `mostrar_resultado()` presenta victoria o derrota y avisa si falló el guardado.
- [`Vistas/Efectos/ExplosionTanque.tscn`](Vistas/Efectos/ExplosionTanque.tscn) crea el efecto breve que `Tanque.gd` instancia al destruirse; no sustituye el sprite del tanque, que permanece visible como resto durante la caída y el oscurecimiento.

## 7. Escenas del nivel, terreno y fondos

### [`Niveles/nivel_1.tscn`](Niveles/nivel_1.tscn)

Es la escena común de combate. Sus fondos son tres imágenes panorámicas de 2752 × 1536 píxeles, mostradas proporcionalmente a escala 0.654 para cubrir un mundo de 1800 × 1005 unidades. Contiene:

- `MapaFrancia`, `MapaElAlamein` y `MapaBerlin`; el controlador solo muestra el fondo que corresponde a la paleta de la misión.
- Una instancia de `Niveles/suelo.tscn` desactivada como referencia de compatibilidad; el suelo físico real son los bloques de `TerrenoDestructible`, texturizados con las imágenes suministradas.
- `PuntoObjetivo` con una bandera visual.
- `ZonaEvacuacion` (`Area2D`) con una forma rectangular que define el área física de llegada. El controlador confirma la victoria cuando el enemigo está destruido y la hitbox del jugador intersecta esa zona; también comprueba los rectángulos directamente como respaldo si el movimiento cruzó el área entre actualizaciones físicas.
- El aviso `AvisoRetirada` del HUD aparece con desplazamiento, fundido y rebote suave al neutralizar la posición enemiga. La misión de Francia muestra el mensaje de repliegue hacia Dunkerque descrito en el GDD; el aviso desaparece después de unos segundos, pero la instrucción de avanzar permanece en el estado del HUD.
- Instancias `Jugador` y `Enemigo`, ubicadas con espacio para movimiento horizontal y limitadas al terreno.
- Una cámara 2D con zoom adaptativo entre 0,85 y 1,08, límites del mapa y margen inferior para cráteres; durante combate encuadra las cajas de ambos tanques y en retirada sigue al jugador. El HUD permanece en su capa de interfaz.
- `ControladorCombate` con dos hijos `GestorProyectiles`: uno para el jugador y otro para la IA.

La escena base se conserva, pero el controlador aplica los datos tácticos de cada misión: apariciones, posiciones defensivas, relieve con colisión y objetivos. Solo Francia utiliza el enemigo inicial de la escena sin una segunda defensa. El Alamein añade dunas; Berlín, rampas de escombros y ruinas elevadas con paso por debajo.

### [`Niveles/suelo.tscn`](Niveles/suelo.tscn)

Escena con una caja rectangular desactivada que conserva la referencia y=800. No impide excavar por debajo de esa altura. El terreno físico transitable se genera desde el perfil de alturas; el fondo ilustrado permanece como paisaje y no participa en las colisiones.

### Tanques como escenas

- [`Jugador/TanqueJugador.tscn`](Jugador/TanqueJugador.tscn) declara `CharacterBody2D`, sprite Sherman, colisión, marcador del cañón y `Line2D` de trayectoria; adjunta `TanqueJugador.gd`.
- [`Vistas/Tanques/TanqueIA.tscn`](Vistas/Tanques/TanqueIA.tscn) declara el tanque controlado por IA, reutiliza el sprite con orientación/tinte diferente y proporciona su marcador de disparo.
- Las dos escenas contienen `CollisionShape2D` rectangular desactivado como caja de referencia; la colisión física real son los polígonos de la silueta alfa que genera `Tanque.gd`. La textura mide 686 × 364 píxeles y sus límites visibles ocupan 498 × 286. La generación se adapta a escala y volteo horizontal de cada instancia. La caja de referencia sigue siendo usada por los métodos que necesitan centro y anchura para apuntado, IA y evacuación, pero no participa en los impactos.
- La silueta poligonal evita que el rectángulo completo cubra los espacios transparentes. Es una aproximación suavizada configurable, no una colisión pixel-perfect: el umbral alfa y la simplificación pueden omitir detalles muy pequeños. `tests/test_core.gd` comprueba la caja de referencia, que los polígonos cubren un píxel opaco y que al menos un píxel transparente queda fuera de ellos, en ambas orientaciones.

## 8. Pruebas y documentación del proyecto

### [`tests/test_core.gd`](tests/test_core.gd)

Es una prueba automatizada headless basada en `SceneTree`. `_initialize()` inicia la secuencia diferida y `_ejecutar_pruebas()` ejecuta los grupos de pruebas y termina con código de error si hay fallos.

- `_probar_factory_y_ciclo()`: comprueba que la Factory crea las cinco municiones y que el ciclo se reinicia después de usarlas todas.
- `_probar_navegacion()`: verifica menú → selección → ficha → combate.
- `_probar_escena_de_combate()`: comprueba que las tres imágenes se cargan y se alternan por misión, el tamaño del terreno, el zoom y límites de la cámara; también verifica el estado inicial, el joystick fijo, el arrastre limitado sin disparo, la conservación de la puntería, los cambios de ángulo/potencia y la geometría balística para los cinco tipos, movimiento y consumo de combustible, reposicionamiento de IA, fragmentación, posición de salida, ecuación de vuelo del proyectil, impacto, daño y creación del efecto reutilizable. También comprueba la selección automática de munición, la destrucción no bloqueante (resto visible, física detenida y nodo de explosión), el aviso animado, el movimiento sin consumo de combustible tras derrotar al enemigo, la zona de evacuación, el mensaje y resumen de victoria, la permanencia del panel y el regreso a la selección de misiones. `_verificar_hitbox_coincide_con_sprite()` comprueba dimensiones de referencia y cobertura de píxeles opacos y transparentes por la geometría física.
- `_probar_catalogo_y_misiones()`: verifica la disponibilidad inicial de Francia, los bloqueos de El Alamein y Berlín, la progresión al completar cada misión y la migración de guardados anteriores. También comprueba que la vista de campaña muestre estados completados/disponibles/bloqueados, atenúe los bloqueados, rechace su inicio y conserve cosméticos al reiniciar la campaña.
- `_verificar(condicion, mensaje)`: cuenta e informa verificaciones fallidas.

La prueba principal no sustituye una sesión visual manual. `test_campana.gd` añade recorridos físicos y persistencia JSON desde otro proceso; `test_partidas.gd` gana las tres misiones mediante disparos reales. El preset Windows x64 QA también ejecuta estas partidas sobre recursos exportados.

### [`tests/test_pantalla_carga.gd`](tests/test_pantalla_carga.gd)

Instancia la pantalla inicial y verifica que, al completar la introducción y cargar los recursos, la escena activa cambie al menú principal. Se ejecuta headless; no valida la calidad visual ni el audio.

### Documentos de apoyo

- [`README.md`](README.md): introducción, requisitos, ejecución, controles y prueba rápida.
- [`instrucciones.md`](instrucciones.md): convenciones y flujo recomendado de trabajo.
- [`docs/arquitectura.md`](docs/arquitectura.md): criterios arquitectónicos y responsabilidades.
- [`docs/plan-desarrollo.md`](docs/plan-desarrollo.md): etapas, prioridades y criterio de cierre.
- [`docs/requisitos-y-alcance.md`](docs/requisitos-y-alcance.md): estado, recortes y criterios de aceptación.

### Recursos visuales

- `Imagenes/TanqueM4Sherman.png`: sprite Sherman y referencia física compartida; las otras skins tienen atlas propios.
- `Imagenes/Fondos/MapaFrancia1940.jpeg`, `MapaElAlamein1942.jpeg` y `MapaBerlin1945.jpeg`: fondos panorámicos de las tres misiones.
- [`Imagenes/UI/ProyectilesMenu.jpg`](Imagenes/UI/ProyectilesMenu.jpg): lámina de munición de la que `HUD.tscn` recorta los cinco iconos mostrados en el menú desplegable.
- [`Imagenes/UI/ReferenciaMenuProyectiles.jpg`](Imagenes/UI/ReferenciaMenuProyectiles.jpg): referencia visual proporcionada para la composición del selector. El botón de fin de turno de la referencia se omitió; el disparo ya avanza automáticamente la secuencia de turnos.
- [`Imagenes/UI/ReferenciaHUDGeneral.jpg`](Imagenes/UI/ReferenciaHUDGeneral.jpg): referencia visual de jerarquía tipográfica y paneles para turno, misión, vida y combustible.
- `icon.svg`: icono configurado del proyecto.
- Los archivos `.import` asociados guardan metadatos de importación de Godot; `.godot/` contiene datos generados/locales y no es documentación fuente del juego.

## 9. Configuración de entradas

Las acciones se configuran en la sección `[input]` de `project.godot`:

- `Derecha`: D y flecha derecha.
- `Izquierda`: A y flecha izquierda.
- `Disparo`: Espacio. El script del jugador también acepta clic izquierdo de ratón; el HUD consume el clic que comienza el arrastre del joystick.

El nombre de estas acciones distingue mayúsculas/minúsculas; al cambiar un control, actualizar tanto `project.godot` como esta explicación y el README.

## 10. Cómo modificar el proyecto sin romper el flujo

- Para cambiar daño, radio, duración o fragmentos, editar la escena de la munición correspondiente en `Vistas/Proyectiles/`.
- Para cambiar velocidad efectiva de un tipo, editar `MULTIPLICADORES_POTENCIA` en `Controladores/GestorProyectiles.gd`; no duplicar ese dato en otra Factory.
- Para ajustar vida y colisiones compartidas, revisar `Scripts/Tanques/Tanque.gd` y las formas de referencia en ambas escenas de tanque. La colisión física se genera desde la máscara alfa; el umbral, la simplificación y el área mínima se configuran en `Tanque.gd`. Ejecutar `tests/test_core.gd` para comprobar cobertura opaca y exclusión de transparencia.
- Para ajustar el aspecto del golpe sin mezclarlo con las reglas de vida, editar `Scripts/Tanques/EfectoImpactoTanque.gd` y `Vistas/Efectos/ImpactoTanque.tscn`; `Tanque.recibir_impacto_proyectil()` es el punto común de contacto para proyectiles principales, fragmentos y daño de área.
- Para ajustar movimiento o apuntado del jugador, trabajar en `Scripts/Tanques/TanqueJugador.gd`; el joystick visual y su captura de ratón pertenecen a `Vistas/UI/HUD.tscn` y `HUD.gd`. Mantener la fórmula de preview coherente con la integración de `Scripts/Proyectiles/Proyectil.gd`.
- Para cambiar ritmo, acciones o condiciones de victoria, revisar `Controladores/ControladorCombate.gd`.
- Para añadir misiones, actualizar `MISIONES` en `Autoloads/GestorMisiones.gd`, el diccionario de botones en `MenuMisiones.gd` y la selección de fondos del controlador; hoy las misiones reutilizan el mismo nivel.
- Para cambiar progreso o formato del archivo, usar `Autoloads/GestorGuardado.gd`; no escribir el JSON desde la UI.
- Para cambiar colores y textos del HUD, editar `HUD.tscn` y `HUD.gd`; dejar que el controlador le informe los estados por métodos y señales.
- Tras modificar scripts/escenas, validar con Godot 4.7.2 y ejecutar la prueba rápida descrita en `instrucciones.md`.

## 11. Convención de comentarios de código

Los comentarios deben ayudar a entender el propósito, las reglas de juego y los cálculos no obvios. Al añadir o cambiar código, documentar especialmente las funciones nuevas, contratos entre escenas, señales, casos límite y fórmulas; evitar comentarios repetitivos que solo traduzcan la instrucción inmediata, para que las explicaciones importantes sigan siendo fáciles de encontrar.

## 12. Límites conocidos de esta versión

- Las tres misiones comparten escena base y controlador, pero tienen posiciones, objetivos y geometría propios. La revisión visual y balance de los cinco combates siguen pendientes.
- Las skins tienen arte propio y geometría física compartida para no dar ventajas.
- La IA tiene una rutina básica, una reposición acotada y un ángulo de disparo fijo; no es una simulación táctica avanzada.
- Los fondos son ilustraciones; el relieve físico y las ruinas se dibujan mediante polígonos superpuestos. Faltan SFX de combate.
- La victoria requiere terminar las defensas de la misión y alcanzar vivo el objetivo; Francia exige además llegar antes del plazo.
- La build Windows x64 y su ZIP están generados; la build QA gana las tres misiones con cero fallos. Siguen pendientes revisión visual, balance humano y pruebas en Windows 10/11 limpio. No se incluye instalador.
