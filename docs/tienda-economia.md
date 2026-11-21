# Tienda, economía y apariencias

Implementación local en Godot 4.7.2. No hay pasarela, cobros ni datos bancarios.

## Presentación del arsenal

La tienda reutiliza el papel, el marco de bronce y la fuente Oswald del selector. Al entrar se abre la ficha del tanque equipado. Las flechas recorren los modelos, Tab cambia el foco y Enter activa el control seleccionado. Escape cancela el diálogo de compra. El saldo se ve en ambas pestañas y volver de Monedas conserva la ficha seleccionada.

Las notas del catálogo resumen el contexto histórico de cada vehículo. La conducción y el combate utilizan las estadísticas comunes del juego.

| Modelo | Referencia histórica |
|---|---|
| M4 Sherman | [The Tank Museum, el debut del Sherman en El Alamein](https://tankmuseum.org/article/80th-anniversary-of-lend-lease) |
| Cromwell Mk VIII | [The Tank Museum, el papel del Cromwell en el avance aliado](https://tankmuseum.org/tank-nuts/tank-collection/cromwell) |
| T-34-85 | [The Tank Museum, la torreta de tres plazas](https://tankmuseum.org/article/two-new-additions/) |
| Churchill Mk IV | [The Tank Museum, el Churchill como tanque de infantería](https://tankmuseum.org/tank-nuts/tank-collection/churchill-iv) |
| KV-2 | [Museo Histórico de Janyméi, colección de vehículos blindados](https://hikm.ru/exposition/archive-exhibitions/729-kollekcija-maketov-bronirovannyh-boevyh-mashin-glebova-ivana-nikolaevicha.html) |

## Reglas de economía
- Bienvenida: 100 monedas, persistidas al crear o migrar el guardado.
- Victoria: Francia 100, El Alamein 150, Berlín 200; repetir mantiene la base.
- Primera victoria: +50 por misión, una sola vez aunque se reinicie campaña.
- Derrota: 25 por defensa destruida; cero si no se destruye ninguna. El refuerzo de Francia no cuenta.
- Victoria no suma monedas por defensas. Abandonar no liquida.
- Reiniciar campaña conserva monedas, inventario, equipamiento, recibos y bonos cobrados.
- Precios: Sherman 0; Cromwell 300; T-34-85 700; Churchill 600; KV-2 900.
- Paquetes simulados: 300/COP $3.000, 800/COP $7.000, 1600/COP $12.000. Precios ficticios.

## Responsabilidades e interfaces
- ReglasEconomia: datos y cálculo puro de recompensa.
- CatalogoApariencias: texturas, monturas, nombres, bandos y uso jugador/enemigo; cache compartida.
- Tienda: catálogo del jugador, paquetes, compra y equipamiento.
- GestorGuardado: obtener_saldo(), saldo_actualizado, nuevo_id_operacion(), comprar_cosmetico(id, operacion), comprar_paquete(id, operacion), liquidar_partida(operacion, mision, victoria, defensas).
- Las transacciones retornan ok, codigo, importe, saldo; la liquidación añade base, bono y defensas.
- Los identificadores se mantienen durante reintentos. Cada recibo guarda la firma de la operación; repetirlo devuelve el resultado previo, reutilizarlo para otra compra se rechaza.
- ControladorCombate cuenta defensas y liquida exclusivamente al llegar a RESULTADO; conserva el ID para reintentar desde HUD. Una victoria confirma progreso, bono y monedas conjuntamente.
- El HUD muestra el desglose y no anuncia ingresos si falla la persistencia. Volver sin guardar abandona esa recompensa pendiente.
- La tienda confirma costes y paquetes; bloquea entradas durante la operación y ofrece equipar después de comprar.

## Persistencia versión 3
Se mantienen misiones_completadas, cosmeticos_comprados y cosmetico_equipado. Se añaden monedas (entero no negativo), bonos_cobrados y operaciones_aplicadas (diccionario de recibos).
La migración v1/v2 conserva compras y progreso, da 100 monedas una sola vez y consume los bonos de misiones anteriores sin pagos retroactivos.
La escritura usa save_data.json.tmp, copia el anterior válido a .bak y renombra el temporal sobre el destino. Los fallos revierten la transacción en memoria.
Si el principal falla, se recupera .bak y se preserva el principal corrupto en .corrupto. Sin copia válida, se informa y bloquean escrituras; no se sobrescribe silenciosamente.
El sistema no incluye servidor ni protección contra edición manual del JSON.

## Arte y enemigo
Se conserva el Sherman existente. Cuatro skins del jugador y ENM-01 se prepararon desde las imágenes del usuario mediante la herramienta integrada imagegen, sin reemplazar los originales.
Atlas definitivos: Imagenes/Apariencias/TNQ-02.png, TNQ-03.png, TNQ-04.png, TNQ-06.png y ENM-01.png.
Cada atlas tiene casco/torreta sin tubo arriba y cañón aislado abajo, con transparencia. AtlasTexture selecciona regiones sin reescribir el PNG; se ignora alfa residual inferior a 0,25 para calcular el encuadre.
La configuración adapta el arte a la montura, apoyo y boca comunes. Se mantiene la colisión del Sherman y el marcador balístico. Las seis apariencias usan ahora el [rodaje compartido](rodaje.md), con ruedas, eslabones y suspensión independientes; las miniaturas de tienda siguen siendo estáticas.
ENM-01 usa el Pz.Kpfw. VI identificado en la imagen suministrada, mirando hacia el jugador; no se vende ni equipa en el inventario. Aparece en los tres mapas, segundas defensas y refuerzos, y conserva su arte en los restos.

### Prompt de preparación utilizado
Modo: herramienta integrada imagegen, edición de una referencia por llamada y fondo transparente.
Prompt común: crear atlas cuadrado transparente; conservar identidad, colores, insignias y estilo del tanque de referencia; casco, orugas y torreta completos mirando a la derecha en la mitad superior, retirando solo el tubo del cañón y reconstruyendo detrás; tubo aislado horizontal en la mitad inferior, raíz a la izquierda y boca a la derecha; separar las piezas con margen transparente; quitar fondo, línea de suelo, bordes y artefactos periféricos; no añadir textos, objetos ni sombras. La resolución solicitada fue 1024×1024; la herramienta entregó atlas de 1254×1254 que se integran a su resolución real.
Referencias por llamada: Tanque CROMWELL MK VIII.png → TNQ-02; TANQUE T-34-85.png → TNQ-03; Tanque CHURCHILL MK IV.png → TNQ-04; Tanque KV-2.png → TNQ-06; ENM-01.jpeg → ENM-01.

## Verificación
test_economia.gd cubre bienvenida, migración, recuperación/bloqueo de corrupción, saldo insuficiente/exacto, duplicados, firma incorrecta, reintentos de escritura, compra/equipamiento, UI, todas las recompensas, reset, geometría común, enemigo y resultados.
test_partidas.gd juega cinco partidas con movimiento y disparos reales, una por skin, incluyendo los tres escenarios.
Las suites usan archivos qa_suite_<pid>.json aislados y los eliminan al terminar; verificar_guardado.gd lee el archivo explícito desde otro proceso.
Las capturas del renderer OpenGL se guardan en .godot/qa-economia cuando test_economia recibe el argumento capturas.
La build QA admite los argumentos economia y terreno; sin ellos ejecuta partidas completas.
