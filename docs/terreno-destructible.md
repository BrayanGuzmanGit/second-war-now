# Terreno destructible

Implementado el 13 de noviembre de 2026 con las seis imágenes suministradas por el usuario. No se modifican los JPEG originales ni los fondos de las misiones.

## Modelo y límites

`Modelos/PerfilTerreno.gd` almacena una altura cada 4 unidades a lo largo de 1800 unidades. Parte del suelo a y=800 y combina las dunas/escombros de `DatosCampana`. La base está en y=1005. Solo se retira material: no hay túneles, voladizos ni reconstrucción de tierra.

La profundidad acumulada máxima es 80 unidades y la pendiente máxima 32°. Dos pasadas calculan una envolvente de pendiente acotada; nunca restauran el perfil anterior. La última franja de 160 unidades permanece firme. Los futuros enemigos conservan una plataforma hasta aparecer; entonces se libera esa protección.

Los cráteres duran toda la misión y desaparecen al reiniciarla. No se altera el formato JSON ni se guardan alturas de una partida.

| Munición | Anchura nominal | Profundidad |
|---|---:|---:|
| Estándar | 160 | 20 |
| Pesado | 240 | 45 |
| Bombardeo | 300 | 32 |
| Cada fragmento | 64 | 8 |
| Incendiario | 120 | 6 |

Son máximos nominales: pendiente, acumulación, soporte protegido y distancia entre explosión/suelo pueden reducir la excavación. Son independientes del daño y no cambian con la escala de daño de IA.

## Vista, colisiones y recursos

`Vistas/Niveles/TerrenoDestructible.gd` divide el perfil en bloques de 128 unidades. Cada bloque tiene un `StaticBody2D` con polígono sólido y un dibujo construido desde los mismos puntos. Se actualizan únicamente los bloques afectados, incluidos ambos lados de una unión. La publicación se difiere fuera del callback físico y actualiza dibujo, textura de alturas y colisión en el mismo punto seguro.

La plataforma rectangular de `Niveles/suelo.tscn` queda desactivada como referencia de compatibilidad; no bloquea el fondo de los cráteres. Se retiraron las dos ruinas elevadas de Berlín, incluido su dibujo y colisión, porque parecían suelo flotante e interceptaban los disparos. Se conservan las rampas de escombros del terreno.

El shader `terreno_texturizado.gdshader` consume los originales:

| Misión | Interior | Superficie |
|---|---|---|
| Francia | `francia interior.jpeg` | `francia_superficie.jpeg` |
| El Alamein | `alamein_interior.jpeg` | `Alamein_superficie.jpeg` |
| Berlín | `Berlin_interior.jpeg` | `Berlin_superficie.jpeg` |

Los interiores miden 2048 × 2048 y las superficies 5856 × 704. Todos son JPEG opacos. La falsa transparencia de las superficies se evita midiendo por columna el final de los píxeles claros y comenzando el muestreo bajo ellos; el damero no se dibuja. Francia utiliza solo la región inferior de su interior porque la parte superior contiene blanco y césped.

Las texturas interiores usan repetición reflejada para evitar juntas. El borde se mezcla con el subsuelo a lo largo de 26 unidades. Hierba y asfalto desaparecen gradualmente cuando se retira la superficie, sin reaparecer sobre el fondo del cráter. Una pared interior oscurecida, sin colisión, cubre el suelo intacto que ya está pintado en el fondo original.

## Bombardeo progresivo

1. La bengala marca el área durante 1,4 segundos sin excavar.
2. Se aplica una sola vez el daño normal de bombardeo.
3. El proyectil calcula una única superficie objetivo y ejecuta una animación de 0,9 segundos.
4. Un reloj físico comparte el progreso `smoothstep` con el efecto y la interpolación del perfil.
5. Al llegar a 1,0 se publica el perfil final antes de emitir `finalizado`.

No se añade un cráter completo por fotograma. Repetir un mismo progreso es idempotente. Otras explosiones pueden retirar material adicional sin que la interpolación posterior lo restaure. `EfectoBombardeoTerreno.gd` solo dibuja polvo, partículas y la onda expansiva; no controla tiempos ni salud.

El portador de dispersión no crea un hueco extra: los fragmentos reciben el terreno del proyectil y excavan individualmente. Los ticks incendiarios no excavan. Los proyectiles solo reciben el terreno mediante el controlador; la Factory sigue siendo única.

## Tanques y campaña

Ambos cuerpos usan adherencia de 16 unidades y pendiente admisible de 40° para transitar un perfil limitado a 32°. No hay daño por caída ni rotación física libre. La IA distingue una pendiente válida de una pared. Los enemigos aparecen tomando la altura actual y su silueta inferior.

El controlador mantiene pendiente la acción del proyectil durante la publicación de geometría y el asentamiento: tres pasos físicos estables, máximo dos segundos. La retirada permanece inmediata y los 30 segundos de Francia no se pausan. No se activa la siguiente defensa mientras sigue pendiente el disparo.

La curva se recalcula desde el cañón usando raycasts contra la escena actual, conservando su tramo parcial. La cámara agrega margen inferior cuando el suelo baja y ajusta el zoom entre 0,85 y 1,08 según las cajas de ambos tanques para evitar recortarlos en combates amplios.

## API

- `obtener_altura(x)` devuelve la superficie actual.
- `solicitar_impacto(posicion, tipo, es_fragmento=false)` aplica la excavación instantánea.
- `iniciar_deformacion_progresiva(posicion, tipo, duracion=0.9)` prepara el objetivo y devuelve un ID; el llamante controla el reloj.
- `actualizar_deformacion(id, progreso)` avanza ese objetivo sin sumar daño ni profundidad repetida.
- `hay_deformaciones()` incluye operaciones activas y geometría pendiente.
- Señales `terreno_actualizado` y `deformacion_finalizada(id)` notifican publicaciones.

## Verificación

`tests/test_terreno.gd` comprueba acumulación, límites, monotonía, protección/liberación de posiciones, cráteres intermedios, colisión final, daño único, ticks de fuego, caída de ambos tanques, recorrido, cancelación y reinicio. Respalda/restaura el progreso del usuario.

`tests/previsualizar_terreno.gd` usa el renderer real para generar capturas en `.godot/qa-terreno/`: antes/después de las tres misiones y bombardeo al 25/50/75 %. Las imágenes originales permanecen intactas.

La build `Windows x64 QA` admite `-- terreno` para ejecutar las pruebas de terreno; sin argumentos juega las tres misiones con tiros reales. Las pruebas de QA no forman parte de la distribución normal.
