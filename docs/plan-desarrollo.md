# Plan de desarrollo y cierre

## Reglas aprobadas e implementadas

1. Francia: un enemigo, resistencia satisfecha al destruirlo y evacuación de 30 segundos. Vencido el plazo, anuncio de refuerzos y ataque letal tras dos segundos. Llegar en la misma actualización tiene precedencia.
2. El Alamein: dos defensas sucesivas, dunas, avance entre combates y salida final.
3. Berlín: dos defensas sucesivas, escombros/barricadas, ruinas que bloquean tiros y epílogo.
4. Tienda: monedas por partida, paquetes simulados COP y skins persistentes sin ventaja mecánica. Apariencia enemiga propia. Véase [tienda-economia.md](tienda-economia.md).

Se reutilizan controlador, Factory y escena base. Los datos tácticos por misión definen apariciones, relieve, activaciones y objetivos. No se cura al jugador ni se reinicia su ciclo de munición entre posiciones.

## Verificación automatizada

El terreno destructible ya está implementado con las seis imágenes suministradas. El bombardeo comparte una animación/excavación de 0,9 segundos tras su señalización de 1,4 segundos. Se añadieron pruebas de límites, caída/movimiento, daño único y cancelación, además de capturas del renderer real. Detalles en [terreno-destructible.md](terreno-destructible.md).

Las suites de combate, inicio y campaña comprueban transiciones, impactos, recorridos físicos, prioridades temporales y guardado entre procesos. Consultar comandos en README. Las destrucciones preparadas en la suite de campaña no sustituyen partidas humanas.

## Trabajo de cierre

1. Revisar en ventana las tres misiones: HUD sin solapamientos, joystick, trayectoria, relieves, avisos, cuenta atrás y resultado.
2. Completar los cinco combates con el joystick, sin manipular vida/posición; ajustar daño y dificultad solo a partir de fallos reproducibles.
3. Probar victoria y derrota de Francia y ambos escenarios de dos posiciones desde la build Windows.
4. Verificar redimensionado con aspecto fijo, cerrar/reabrir y confirmar avance/cosméticos.
5. Probar la build en Windows 10 y 11 limpio, documentar versión, hardware e incidencias.
6. Añadir SFX y mejorar sprites si el ciclo y la exportación están estables. Usar recursos con licencia identificada.

## Criterio de cierre

Campaña completa recorrida en una build Windows x64 sin bloqueos, con resultados y progreso correcto tras reinicio. Mantener cualquier validación pendiente explícita en estado.md y docs/entrega-windows.md.
