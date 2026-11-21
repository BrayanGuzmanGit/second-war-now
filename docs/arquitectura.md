# Arquitectura

## Enfoque

El proyecto usa MVC en español, adaptado al árbol de escenas de Godot:

- **Modelos:** datos de misión, mapa, tanque, proyectil, cosmético y guardado; no dependen de nodos de presentación.
- **Vistas:** escenas `.tscn`, HUD, menús, cinemáticas y nodos físicos; exponen señales y muestran estados.
- **Controladores:** reciben eventos de la vista, aplican reglas y coordinan modelos, entidades y escenas.
- **Scripts de entidades:** comportamiento ligado a nodos como `CharacterBody2D` o `Area2D`.
- **Autoloads:** servicios globales mínimos, comenzando por `GameConfig`.

## Responsabilidades de referencia

- `ControladorCombate`: turno actual, secuencia de disparo, consecuencias, victoria/derrota y transición de resultados.
- `GestorMisiones`: catálogo, bloqueo/desbloqueo y selección de misión.
- `GestorGuardado`: serialización JSON del progreso. Los errores de lectura/escritura deben comunicarse; no confirmar una operación fallida.
- `GestorProyectiles`: Factory de escenas de proyectil, validación de disponibilidad, registro de uso y reinicio del ciclo cuando todos se hayan usado.
- `Tienda`: compra de skins con monedas, paquetes simulados y equipamiento.
- `ReglasEconomia`: precios y recompensas independientes de nodos.
- `CatalogoApariencias`: arte compartido por jugador e IA; ENM-01 queda fuera del inventario.
- `GestorGuardado`: JSON v3, monedas, recibos y recuperación. Véase [tienda-economia.md](tienda-economia.md).
- `GameConfig`: constantes comunes como `GRAVEDAD`.

## Factory de proyectiles

`GestorProyectiles` es la única responsabilidad de creación para los cinco tipos. Cada tipo se instancia desde una `PackedScene`; una selección no disponible o desconocida debe rechazarse explícitamente sin consumir el turno ni presentar una falsa confirmación. El ciclo solo se reinicia después de usar todas las municiones disponibles. No se requiere una clase `ProjectileFactory` separada.

## Comunicación y escenas

Usar señales para informar cambios del tanque, impactos, selección de munición y movimiento del joystick virtual. El HUD captura el arrastre en una base fija, limita el recorrido y emite el vector normalizado; el controlador conecta esa señal con el tanque jugador. El tanque convierte su dirección en ángulo y la distancia recorrida en potencia, alinea el cañón y dibuja una previsualización parcial. La vista consume el clic que inicia el arrastre para que no se convierta en disparo; al soltar mantiene el último vector. Los clics ajenos al control y Espacio conservan la acción de disparar. El controlador de combate coordina la lógica y avanza automáticamente al turno de la IA al resolverse el disparo; el HUD presenta los estados sin decidir resultados de combate. Las escenas de misión contienen el terreno y los puntos de aparición, y cargan los datos de misión correspondientes.

### Hitboxes e impactos

`Tanque.gd` mantiene dos responsabilidades separadas: una `CollisionShape2D` rectangular desactivada como referencia de centro/ancho para sistemas existentes, y varias `CollisionPolygon2D` generadas desde la máscara alfa como colisión física. La generación aplica un umbral de opacidad y simplifica los contornos para equilibrar precisión y coste. Las escenas de tanque solo aportan la caja de referencia inicial; las geometrías de jugador e IA se producen con el mismo código compartido y respetan orientación, escala y offset del sprite.

El proyectil y sus fragmentos detectan el punto de contacto mediante un raycast del segmento recorrido y llaman `Tanque.recibir_impacto_proyectil()`. El tanque presenta el efecto visual y delega la salud en `recibir_dano()`. El VFX no aplica daño, el daño de área usa el mismo contrato para cada tanque alcanzado y los ticks incendiarios solo aplican daño sin crear efectos repetidos. La animación de destrucción desactiva tanto formas como polígonos.

La Factory conserva la creación de proyectiles. Cada escena declara un `tipo_visual`, que configura el cuerpo y rastro animado durante el vuelo. `ControladorCombate` crea además un efecto de salida procedural en el marcador de disparo, orientado hacia la velocidad inicial; el tanque recibe el identificador de munición para que el efecto de impacto también tenga una animación distinta. Estos nodos son presentación independiente y no alteran reglas de turno, velocidad, colisión ni daño.

La munición incendiaria crea una zona visual persistente durante la secuencia de daño en el tiempo; su radio/duración se leen de la configuración de esa munición. El fuego se limita a representar el efecto: el proyectil sigue siendo responsable de programar los ticks y `Tanque` de modificar la salud.

## Estado de implementación

### Terreno destructible

`PerfilTerreno` es el modelo numérico sin nodos: calcula alturas y excavaciones limitadas, con interpolación idempotente para el bombardeo. `TerrenoDestructible` publica dibujo/colisiones por bloques y texturas de alturas para el shader. `EscenarioCampana` instancia el terreno y conserva las ruinas no deformables. La plataforma rectangular antigua queda desactivada como referencia.

El controlador inyecta el terreno en los proyectiles y estos lo transmiten a sus fragmentos. El bombardeo calcula un objetivo una sola vez y comparte un progreso de 0,9 segundos con el VFX, después de su espera de 1,4 segundos. Solo el proyectil controla el reloj y el daño. El controlador espera la publicación física y el asentamiento antes de avanzar turnos. Ver [terreno-destructible.md](terreno-destructible.md).

La campaña aprobada se configura en `Modelos/DatosCampana.gd`: apariciones, objetivos, activación de segunda defensa, plazo, escala de daño de IA y geometrías. `Vistas/Niveles/EscenarioCampana.gd` genera dibujo y colisión desde esos datos. El controlador coordina fases explícitas COMBATE, AVANCE, EVACUACION, REFUERZOS y RESULTADO. Cada callback de disparo lleva una secuencia para impedir que un efecto antiguo reactive turnos posteriores. La activación de segunda posición espera a que termine el disparo previo, conserva vida/ciclo del jugador y crea un ciclo independiente para el nuevo enemigo.

El plazo de Francia se actualiza con delta de la escena (sin Timer huérfano). Primero se evalúa llegada; al vencer, la fase REFUERZOS impide victoria. Tras dos segundos la Factory crea un proyectil animado hasta el jugador; esta secuencia letal representa un fracaso ya decidido y no usa la balística normal. RESULTADO invalida callbacks anteriores y detiene la cuenta atrás. El guardado v3 liquida resultado y monedas conjuntamente.

Ya existen `GameConfig`, `GestorGuardado`, `GestorMisiones`, `Tienda`, la Factory de proyectiles, entidades de tanque/proyectil y vistas de pantalla de carga inicial, menú, ficha histórica, tienda y HUD. La pantalla de carga reproduce una introducción Ogg Theora y solicita asíncronamente la escena del menú. Los modelos de datos siguen representados por recursos/diccionarios sencillos; no todos los módulos del diseño objetivo están separados todavía. Consulta el estado funcional en [requisitos-y-alcance.md](requisitos-y-alcance.md).

Para el recorrido completo de escenas y la explicación de archivos, clases y funciones, consulta [explicacion.md](../explicacion.md).

## Rodaje visual

`DatosRodaje` configura las seis apariencias y `CatalogoApariencias` expone su configuración. `VisualTanque` conserva el montaje balístico y crea un `VisualRodaje` independiente por unidad. Jugador/IA transmiten desplazamiento posterior a física y límites; las ruedas, el MultiMesh de eslabones y los apoyos interpolados se actualizan exclusivamente en presentación. `Tanque` congela este componente al destruirse; el controlador lo reinicia al colocar una unidad. El guardado v3 y la tienda no requieren cambios. Detalles en [rodaje](rodaje.md).
