# Second War Now

Juego educativo 2D de artillería y estrategia por turnos, ambientado en tres episodios inspirados en la Segunda Guerra Mundial.

## Ejecutar

Abrir `project.godot` con Godot 4.7.2 (Compatibility) y pulsar F5. Requiere Windows x64, teclado y ratón. La introducción de diez segundos conduce al menú, selección de misión y ficha histórica.

Para compartir el proyecto por GitHub, subir la carpeta `second-war-now` con `project.godot`, escenas, scripts, imágenes, audio y videos `.ogv`. Tras clonar el repositorio, importar `project.godot` desde el administrador de proyectos de Godot 4.7.2, esperar a que termine la importación y ejecutar con F5. La carpeta `.godot/` se regenera en cada equipo.

Para entregar el juego a alguien que no usa Godot, instalar las plantillas de exportación de Godot 4.7.2 y exportar con el preset **Windows x64**. Compartir `SecondWarNow.exe` y `SecondWarNow.pck` juntos, preferiblemente dentro de un ZIP que el destinatario extraiga antes de abrir el ejecutable. `builds/` está excluida de Git. La carpeta `user://` de guardado y preferencias se crea al ejecutar el juego en cada equipo.

## Campaña

Cada defensa recuerda el último tiro. Si permaneces en el mismo sitio, el enemigo ajusta la puntería. Si cambias de posición, pierde parte de esa referencia. Observa su cañón cuando te cubras: puede probar un arco más alto, moverse si mejora el tiro o emplear munición de área. Cada enemigo comparte las reglas del ciclo de cinco proyectiles del jugador.


El resultado de cada misión presenta un informe en pergamino con el escenario, monedas desglosadas y saldo. **Hechos y significado** explica el episodio y sus consecuencias; **Para recordar** ofrece cronología, pregunta con explicación y fuentes. Detalles en [resultados educativos](docs/resultados-mision.md).

Las partidas incluyen motor, cadenas por superficie, engranajes del cañón, impactos y avisos. **Menú / Pausa**, Escape o F8 detienen la misión y permiten continuar, ajustar Efectos/Avisos/Videos o abandonar con confirmación. Las preferencias persisten. Detalles en [menú de pausa](docs/menu-pausa.md) y [audio de partidas](docs/audio-partidas.md).

El informe previo a cada misión reutiliza el pergamino y los marcos del selector: paisaje a la izquierda, historia y objetivos a la derecha. Permite revelar el texto, repetir la introducción, volver al selector o comenzar directamente. Detalles en [informes de misión](docs/informes-mision.md).

Tres introducciones y tres videos de victoria acompañan la campaña. Se pueden omitir con Escape, Enter, Espacio o el botón en pantalla. Después aparecen las fichas históricas o los resultados. La victoria de Berlín da paso al resumen, recompensas y epílogo de campaña. Véase [videos de misión](docs/videos-misiones.md).

- Francia: destruye al enemigo inicial y evacúa a Dunkerque en 30 segundos. Al vencer el plazo, un refuerzo corta la retirada y realiza un ataque letal anunciado.
- El Alamein: rompe dos posiciones defensivas sucesivas entre dunas y alcanza la salida.
- Berlín: supera una posición urbana y una defensa final entre escombros/ruinas; llega al objetivo para ver el epílogo.

Completar una misión desbloquea la siguiente. El progreso y los cosméticos se guardan automáticamente en JSON. El botón de reinicio conserva monedas, cosméticos y bonos ya cobrados.

Entre combates y al dirigirse al objetivo final, el movimiento no consume combustible y los disparos están desactivados. El segundo combate conserva vida y munición usada, y restablece el combustible por turno.

El suelo, las dunas y los escombros se deforman con los disparos. Los cráteres son transitables, se acumulan durante la misión y no causan daño por caída. El bombardeo excava progresivamente durante su animación de 0,9 segundos, después de la señalización. Las seis texturas suministradas se integran con los fondos originales mediante el shader, sin modificar los JPEG. Detalles en [terreno destructible](docs/terreno-destructible.md).

## Controles

El selector de municiones tiene clics de apertura/cierre y cinco sonidos metálicos
de selección, controlados por Efectos. Solo suenan cambios aceptados del jugador.
Detalles en [sonidos del selector](docs/sonidos-selector.md).

- A/D o flechas: desplazamiento.
- Joystick fijo inferior izquierdo: arrastrar para controlar ángulo y potencia. Soltar mantiene la puntería.
- Espacio o clic fuera del joystick: disparar durante el turno.
- Selector superior derecho: elegir entre cinco municiones. Debes usar todas para repetir una.
- Resultado: permanece visible hasta pulsar «Volver a misiones».

La trayectoria muestra solo el tramo inicial del disparo. La IA se mueve y responde automáticamente. La tienda permite comprar skins con monedas ganadas jugando y adquirir paquetes simulados con precios ficticios COP, sin cobros. El enemigo usa su propia apariencia. Las apariencias no afectan estadísticas.

## Pruebas

Los seis tanques comparten ruedas y orugas sincronizadas con el desplazamiento real, suspensión de hasta dos píxeles e interpolación visual. Conservan conducción, disparo y guardado v3. Configuración y límites en [rodaje](docs/rodaje.md).

Desde la carpeta del proyecto, usando el ejecutable console de Godot 4.7.2:

```powershell
& 'C:\ruta\Godot_console.exe' --headless --path . --script res://tests/test_core.gd
& 'C:\ruta\Godot_console.exe' --headless --path . --script res://tests/test_pantalla_carga.gd
& 'C:\ruta\Godot_console.exe' --headless --path . --script res://tests/test_campana.gd
& 'C:\ruta\Godot_console.exe' --headless --path . --script res://tests/test_partidas.gd
& 'C:\ruta\Godot_console.exe' --headless --path . --script res://tests/test_terreno.gd
& 'C:\ruta\Godot_console.exe' --headless --path . --script res://tests/test_rodaje.gd
```

Las suites usan guardados aislados y campaña verifica lectura desde otro proceso. Ejecutar también `--script res://tests/test_economia.gd`. Consultar [tienda y monedas](docs/tienda-economia.md).

## Arquitectura y entrega

La versión Windows actualizada está en `builds/windows/` (mantener EXE y PCK juntos) y en `builds/SecondWarNow-CampanaCompleta-Windows-x64.zip`. La build separada de QA verifica cinco partidas usando recursos exportados; admite `-- terreno`, `-- economia`, `-- rodaje`, `-- videos`, `-- informe` y `-- audio` para suites específicas.

MVC adaptado a Godot, nombres en español y `GestorProyectiles` como única Factory. La escena común usa datos tácticos propios por misión y geometría con colisiones generada desde esos datos.

Consultar [estado.md](estado.md), [explicacion.md](explicacion.md), [docs/requisitos-y-alcance.md](docs/requisitos-y-alcance.md), [docs/plan-desarrollo.md](docs/plan-desarrollo.md) y [docs/entrega-windows.md](docs/entrega-windows.md). Antes de modificar código, leer [instrucciones.md](instrucciones.md).

La revisión visual/manual, el balance de las partidas completas y la certificación en Windows 10/11 limpio siguen pendientes.
