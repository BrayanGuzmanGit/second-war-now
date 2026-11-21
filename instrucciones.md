# Instrucciones de desarrollo

## Requisitos de trabajo

- Usar Godot Engine 4.7.2 y GDScript para el juego 2D.
- Mantener nombres de dominio, carpetas y escenas en español; usar PascalCase para clases y `snake_case` para métodos y variables, respetando las convenciones de GDScript y los nombres ya establecidos de recursos.
- Respetar MVC: modelos para datos/reglas independientes de la escena, vistas para escenas/UI y controladores para coordinar reglas y vistas.
- `GameConfig` contiene constantes globales; no replicar el valor de gravedad.
- `GestorProyectiles` crea las escenas de munición y aplica el ciclo de disponibilidad. No añadir otra Factory paralela.
- Las compras son simuladas; nunca se debe integrar una pasarela de pago.
- Mantener el juego accesible con teclado y ratón (A/D, joystick virtual y clic o espacio para disparar; cambio de turno automático), con señales y mensajes claros para errores de recursos o guardado.
- La escena de arranque es `Vistas/UI/PantallaCarga.tscn`; el reproductor nativo de Godot utiliza `Vistas/Recursos/IntroduccionCarga.ogv` (Ogg Theora), no el MP4 fuente. La introducción carga `MenuPrincipal.tscn` en segundo plano y presenta el arte de menú `Gemini_Generated_Image_c1mwl4c1mwl4c1mw.jpeg` con zonas de interacción invisibles sobre sus placas; conserva un fotograma estático y deja el video reproduciendo su audio a volumen bajo.
- El arte del menú principal ya incluye los textos, la tienda y el tanque ilustrado. Las zonas de los botones deben seguir alineadas con las placas sin añadir títulos superpuestos. Para la tipografía condensada dinámica de la campaña se usa Oswald (SIL Open Font License), incluida con su licencia en `Vistas/Recursos/Fuentes/`.
- Mantener la interfaz principal en azul oscuro, dorado y texto claro, en coherencia con el HUD. Las placas de los botones conservan sus tonos arena/bronce, acordes con la estética militar de mediados del siglo XX definida en el GDD.
- En el selector de campaña, usar `Gemini_Generated_Image_eio3aseio3aseio3.jpeg` como fondo y mantener los botones de misión como controles dinámicos opacos: el arte tiene texto y candados impresos que no deben sustituir el progreso real. Reflejar `Disponible`, `Completada` o `Bloqueada`; las bloqueadas deben estar deshabilitadas y atenuadas. Verificar los tres estados al modificar la interfaz.
- Al añadir o modificar código, documentar con comentarios explicativos el propósito de las funciones, reglas y cálculos no obvios; evitar comentarios redundantes que repitan literalmente lo que ya expresa el código.
- Consultar [explicacion.md](explicacion.md) para entender las responsabilidades actuales de archivos, clases, funciones y escenas antes de cambiar el flujo del juego.

## Flujo recomendado

1. Revisar [docs/requisitos-y-alcance.md](docs/requisitos-y-alcance.md) y los criterios de aceptación antes de implementar.
2. Mantener cambios de escena y sus rutas de recursos juntos; después de mover recursos, verificar cada referencia `res://`.
3. Probar cada cambio en Godot 4.7.2, incluyendo el recorrido de una partida cuando afecte el combate.
   Para la verificación rápida, ejecutar `godot --headless --path . --script res://tests/test_core.gd`.
   Para verificar la transición de inicio, ejecutar `godot --headless --path . --script res://tests/test_pantalla_carga.gd`.
4. Actualizar README y documentación de arquitectura/requisitos si el comportamiento o estructura cambia.
5. No incluir `.godot/` ni otros archivos generados en los cambios.

## Estructura prevista

- `Autoloads/`: configuración global.
- `Modelos/`: datos puros y reglas sin dependencia de nodos.
- `Controladores/`: coordinación de combate, misiones, guardado, proyectiles y tienda.
- `Scripts/`: comportamiento de entidades que heredan de nodos.
- `Vistas/`: escenas y presentación de UI.
- `Datos/`: configuración estática de campaña, si se requiere como recurso externo.
- `Imagenes/` y `Audio/`: recursos de presentación.

La estructura evoluciona junto con el proyecto. No trasladar archivos sin actualizar sus recursos y probar las escenas que los instancian.
