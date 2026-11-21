# Informes de resultado y cierre educativo

Actualizado el 15 de noviembre de 2026. El panel posterior al video reutiliza el papel limpio, marco de bronce, tonos arena y fuente Oswald del selector y del informe previo. Los videos mantienen su contenido y audio.

## Lectura y composición

Panel de 1120 × 620 sobre el viewport de 1280 × 720, escalado con la configuración `canvas_items/keep` del proyecto. Imagen del escenario y logro de la partida a la izquierda; ficha de monedas con importe, recompensa base, bono de primera victoria y saldo real. La columna derecha ofrece:

- **Hechos y significado:** qué ocurrió, importancia estratégica y consecuencias humanas; epílogo al completar Berlín.
- **Para recordar:** idea clave, tres hitos, pregunta con explicación revelable, límites de la representación jugable y enlaces a fuentes.

El texto se desplaza con rueda o flechas al enfocar la lectura. Tab recorre las pestañas, texto, explicación, reintento cuando corresponde y regreso a misiones. Revelar la explicación desplaza la lectura hasta la pregunta. Las teclas mantenidas al omitir el video y los eventos repetidos de activación no cierran el informe accidentalmente.

Los enlaces solo abren el navegador al pulsarlos. La lectura es local y no requiere conexión. El resultado permanece visible hasta elegir **Volver a misiones**. La derrota comparte el marco y conserva el rótulo de misión fallida y su contexto particular.

## Contenido histórico

- **Francia:** rescate de unos 338.000 soldados durante Dynamo (26 de mayo–4 de junio de 1940), conservación de fuerzas dentro de una derrota militar y pérdidas de la retirada. Evacuar no equivale a ganar la campaña de Francia.
- **El Alamein:** coordinación multinacional, minas, logística y valor estratégico de Egipto/Suez. Se corrige en el catálogo la fecha final de la segunda batalla al **4 de noviembre de 1942**. La campaña del norte de África continuó hasta mayo de 1943.
- **Berlín:** rendición de la ciudad el 2 de mayo, rendición alemana del 7/8 de mayo y fin mundial tras la rendición formal japonesa del 2 de septiembre. Se distinguen los tres acontecimientos y se recuerda el sufrimiento civil.

Textos originales de síntesis; no se pretende que los tanques, combates o plazos del juego reproduzcan literalmente esos episodios. Las monedas son una recompensa del juego, no una medida del valor histórico o de las pérdidas humanas.

### Fuentes consultadas

- [English Heritage: Operación Dynamo](https://www.english-heritage.org.uk/visit/places/dover-castle/history-and-stories/operation-dynamo-things-you-need-to-know/).
- [RAF Museum: papel de la RAF en Dunkerque](https://www.rafmuseum.org.uk/blog/the-rafs-role-in-the-evacuation-of-dunkirk/).
- [National Army Museum: segunda batalla de El Alamein](https://www.nam.ac.uk/explore/battle-alamein).
- [National Army Museum: campaña del norte de África](https://www.nam.ac.uk/explore/struggle-north-africa-1940-43).
- [USHMM: fechas clave de 1945, en español](https://encyclopedia.ushmm.org/content/es/article/1945-key-dates).
- [National Archives: rendición alemana](https://www.archives.gov/milestone-documents/surrender-of-germany).
- [Australian War Memorial: rendición y conmemoración](https://www.awm.gov.au/wartime/87/article-five).

## Integración

`Modelos/CierresHistoricos.gd` centraliza el contenido, expuesto por `GestorMisiones.obtener_mision()` como `cierre_educativo`. `PanelResultado.gd` construye la interfaz y recibe la liquidación de `HUD`. Se mantiene el flujo del controlador: liquidación, video de victoria y resultado. El primer foco pertenece al informe, sin diferidos que intenten enfocar controles fuera del árbol.

La interfaz consume los importes devueltos por `GestorGuardado`; no calcula ni concede premios. Un error muestra **PENDIENTE**, saldo conservado y reintento. Volver a liquidar no duplica importes ni reinicia la pestaña/posición de lectura. Se conserva el guardado v3.

`EstiloInforme` sigue usando recortes del recurso original, sin textos ni candados impresos. La medición de etiquetas se realiza después de asignarles el ancho, para evitar áreas de control sobredimensionadas.

## Verificación reproducible

`tests/test_resultados.gd` comprueba las tres misiones, importes iniciales, epílogo, cambio de pestañas, explicación, desplazamiento, Tab, límites del panel, fallo/reintento, liquidación repetida, derrota y regreso al selector. Ejecutar con Godot `--headless --path . --script tests/test_resultados.gd`. La variante gráfica añade `-- capturas`; genera `.godot/qa-resultados/` en 960 × 540, 1280 × 720, 1920 × 1080 y ventana 1280 × 800 (con bandas por conservar proporción).

El preset Windows QA admite `-- resultados`. Las capturas son del renderer OpenGL real. Esta comprobación valida presentación y flujo; no sustituye una evaluación pedagógica con estudiantes.
