# Fase 1 – Comprensión: Second War Now *(Cerrada — todas las decisiones tomadas)*

> **Estado:** ✅ Completa · Sin dudas abiertas · Lista para Fase 2.

---

## 1. Resumen del Juego

| Campo | Valor |
|---|---|
| **Nombre** | Second War Now |
| **Género** | Estrategia + Disparos 2D por turnos |
| **Inspiración** | Angry Birds (tiro parabólico) + Tank Stars (combate blindados) |
| **Plataforma** | PC – Windows 10/11 (64-bit) |
| **Controles** | Teclado (A/D) + Ratón (ángulo, potencia, disparo) |
| **Motor** | Godot 4.7.2 – GDScript – 2D |
| **Propósito** | Educativo (física + historia WWII) + Académico + Entretenimiento |
| **Público** | 12–25+ años; jugadores casuales/estrategia; interés en historia |
| **Monetización** | Free-to-Play simulado; cosméticos (tanques históricos) |

### Campaña narrativa (3 misiones lineales)

| # | Misión | Año | Bando | Tipo |
|---|---|---|---|---|
| 1 | Batalla de Francia | 1940 | Aliados | Defensiva / Repliegue → Dunkerque |
| 2 | 2ª Batalla de El Alamein | 1942 | Aliados | Ofensiva por desierto de Egipto |
| 3 | Batalla de Berlín | 1945 | Aliados (Ejército Rojo) | Ofensiva urbana (máxima dificultad) |

---

## 2. Mecánicas Clave

### 2.1 Sistema de Turnos
- **Turno jugador:** Mover tanque (combustible) → Seleccionar proyectil → Apuntar (mouse) → Disparar → Fin de turno.
- **Turno IA:** La IA responde automáticamente con su tanque.
- `ControladorCombate.cambiarTurno()` coordina el ciclo completo.

### 2.2 Física de Proyectiles
- Trayectoria **parabólica real**: `Proyectil.calcularTrayectoriaParabolica(posInicio, angulo, potencia, gravedad)` devuelve `Array<Vector2>`.
- El cursor del mouse define ángulo y potencia en tiempo real.
- El terreno de cada mapa afecta la trayectoria (colinas, dunas, ruinas).

### 2.3 Sistema de Proyectiles (5 tipos — ciclo de rotación obligatorio)

| Clase | Alcance | Daño | Área | Comportamiento especial |
|---|---|---|---|---|
| `ProyectilEstandar` | Alto | Moderado | Reducida | Munición perforante básica |
| `ProyectilPesado` | Corto | Alto | Moderada | Mayor masa → más parábola |
| `ProyectilDispersion` | Corto | Moderado | Grande | Se divide en proyectiles menores al disparar |
| `ProyectilBombardeo` | Largo | Alto | Grande | Bengala → ataque aéreo tras segundos |
| `ProyectilIncendiario` | Alto | Moderado (DoT) | Grande | Fuego persistente, daño por segundos |

> **Regla de ciclo:** Para reusar un proyectil, el jugador debe usar todos los demás primero. `GestorProyectiles.reiniciarCicloMunicion()` restablece el ciclo.

### 2.4 Tanques Disponibles (cosméticos)

| Código | Nombre | Bando | Precio | Gratis |
|---|---|---|---|---|
| TNQ-01 | M4 Sherman | EE.UU. | $0 | ✅ |
| TNQ-02 | Cromwell Mk VIII | Gran Bretaña | $3 | ❌ |
| TNQ-03 | T-34-85 | URSS | $7 | ❌ |
| TNQ-04 | Churchill Mk IV | Gran Bretaña | $6 | ❌ |
| TNQ-06 | KV-2 | URSS | $9 | ❌ |

---

## 3. Escenarios / Mapas

| Mapa | `tipoEntorno` | Paleta visual | Desafío de física |
|---|---|---|---|
| Francia | `"Rural Francia"` | Verdes, tierras húmedas, cielo primavera | Colinas suaves → tiros de corta/media/larga distancia |
| El Alamein | `"Desierto Alamein"` | Amarillos cálidos, arena, naranja atardecer | Dunas pronunciadas → parábolas altas |
| Berlín | `"Urbano Berlin"` | Gris ceniza, ladrillo, negro humo | Calles y barricadas → tiros precisos entre obstáculos |

---

## 4. Requerimientos

| ID | Nombre | Prioridad |
|---|---|---|
| F01 | Combate por turnos con IA | Obligatorio |
| F02 | Gestión del tanque (movimiento, ángulo, potencia, combustible) | Obligatorio |
| F03 | Sistema de proyectiles (5 tipos, ciclo rotativo) | Obligatorio |
| F04 | Tienda de cosméticos simulada | Obligatorio |
| F05 | Gestión de misiones (selección + bloqueo progresivo) | Obligatorio |
| F06 | Cinemáticas históricas intro/cierre por misión | Obligatorio |
| NF01 | Controles ratón + teclado | Obligatorio |
| NF02 | Motor Godot 4.7.2 – 2D | Obligatorio |
| NF03 | Compatibilidad Windows 10/11 64-bit | Obligatorio |
| NF04 | Guardado automático en JSON (cosméticos + misiones) | Obligatorio |

---

## 5. Stack Tecnológico

| Herramienta | Uso |
|---|---|
| **Godot 4.7.2** | Motor principal (2D, física, UI, señales, GDScript) |
| **GDScript** | Único lenguaje de programación |
| **GitHub** | Control de versiones + backups |
| **GIMP** | Arte/sprites 2D |
| **IA generativa** (Gemini / GPT / Claude) | Generación de imágenes base |
| **Audacity** | Edición de audio y efectos de sonido |
| **Astha** | Diagramas UML (licencia universitaria) |

---

## 6. Diagrama de Clases Completo

> Incluye ajustes aprobados: `GestorMisiones.aplicarProgreso()` añadido, `GameConfig` añadido como Autoload global.

### 6.1 Jerarquía general

```
GameConfig [Autoload]           ← Constantes globales (GRAVEDAD, etc.)

Juego [Singleton]
├── GestorGuardado              [Composición 1:1]
├── GestorMisiones              [Asociación 1:1]
│   └── Mision                 [Agregación 1:1..*]
│       ├── Mapa               [Composición 1:1]
│       ├── CinematicaHistorica [Composición 1:1..2]
│       └── ControladorCombate [Asociación 1:1]
│           ├── TanqueJugador  [Asociación 1:1]
│           ├── TanqueIA       [Asociación 1:1..*]
│           └── GestorProyectiles [Asociación 1:1]
│               └── Proyectil  [Agregación 1:5]
│                   ├── ProyectilEstandar
│                   ├── ProyectilPesado
│                   ├── ProyectilDispersion
│                   ├── ProyectilBombardeo
│                   └── ProyectilIncendiario
└── Tienda                      [Asociación 1:1]
    └── TanqueCosmetico         [Agregación 1:1..*]

Tanque [Abstracta]
├── TanqueJugador
└── TanqueIA
```

---

### 6.2 Clases detalladas

#### `GameConfig` — Autoload global *(clase añadida — decisión del equipo)*
| | |
|---|---|
| **Atributos** | `const GRAVEDAD: float = 980.0` *(valor inicial, fácil de modificar para balance)* |
| **Nota** | Autoload registrado en Project Settings. Disponible en cualquier script con `GameConfig.GRAVEDAD`. Basta con cambiar el valor aquí para afectar toda la física del juego. |

---

#### `Juego` — Singleton / Main Manager
| | |
|---|---|
| **Atributos** | `- estadoActual: String` |
| **Métodos** | `+ iniciarJuego(): void` · `+ salir(): void` |
| **Relaciones** | Composición 1:1 → `GestorGuardado` · Asociación 1:1 → `GestorMisiones` · Asociación 1:1 → `Tienda` |

---

#### `GestorGuardado`
| | |
|---|---|
| **Atributos** | `- rutaArchivoJSON: String = "user://save_data.json"` |
| **Métodos** | `+ cargarProgreso(): SaveData` · `+ guardarProgreso(datos: SaveData): bool` · `+ registrarMisionDesbloqueada(idMision: String): void` · `+ registrarCosmeticoComprado(idCosmetico: String): void` |

---

#### `GestorMisiones`
| | |
|---|---|
| **Atributos** | `- misionesDisponibles: Array<Mision>` · `- misionActual: Mision` |
| **Métodos** | `+ obtenerMisiones(): Array<Mision>` · `+ seleccionarMision(idMision: String): void` · `+ cargarSiguienteMision(): void` · `+ aplicarProgreso(datos: SaveData): void` *(añadido — aplica estaDesbloqueada a cada Mision tras cargar el JSON)* |
| **Relaciones** | Agregación 1:1..* → `Mision` |

---

#### `Mision`
| | |
|---|---|
| **Atributos** | `+ idMision: String` · `+ nombre: String` · `+ anio: int` · `+ ubicacion: String` · `+ descripcionHistorica: String` · `+ estaDesbloqueada: bool` |
| **Métodos** | `+ verificarCondicionVictoria(): bool` · `+ verificarCondicionDerrota(): bool` |
| **Relaciones** | Composición 1:1 → `Mapa` · Composición 1:1..2 → `CinematicaHistorica` · Asociación 1:1 → `ControladorCombate` |

---

#### `Mapa`
| | |
|---|---|
| **Atributos** | `+ idMapa: String` · `+ nombreEscenario: String` · `+ tipoEntorno: String` · `+ limitesTerreno: Rect2` |
| **Métodos** | `+ obtenerColisionTerreno(posicion: Vector2): bool` · `+ obtenerPuntoSpawnJugador(): Vector2` · `+ obtenerPuntosSpawnEnemigos(): Array<Vector2>` |
| **Nota** | `obtenerColisionTerreno()` detecta solo colisión con el suelo. La colisión proyectil → tanque se gestiona con `Area2D` en los nodos de Godot (fuera del modelo de clases). |

---

#### `CinematicaHistorica`
| | |
|---|---|
| **Atributos** | `+ idCinematica: String` · `+ textoContexto: String` · `+ rutaRecursoVisual: String` · `+ esIntroduccion: bool` |
| **Métodos** | `+ reproducir(): void` · `+ finalizar(): void` |
| **Implementación acordada** | Panel UI con imagen de fondo + texto histórico con efecto **typewriter**. Botón "Continuar". Diseñada de forma modular para poder mejorar la presentación si hay tiempo. |

---

#### `ControladorCombate`
| | |
|---|---|
| **Atributos** | `- turnoActual: String` ("JUGADOR" \| "IA") · `- estadoCombate: String` ("EN_PROGRESO" \| "VICTORIA" \| "DERROTA") |
| **Métodos** | `+ iniciarCombate(): void` · `+ cambiarTurno(): void` · `+ evaluarConsecuenciasDisparo(proyectil: Proyectil): void` · `+ procesarTurnoIA(): void` · `+ finalizarCombate(resultado: String): void` |
| **Relaciones** | Asociación 1:1 → `TanqueJugador` · Asociación 1:1..* → `TanqueIA` · Asociación 1:1 → `GestorProyectiles` |
| **Nota pantalla resultados** | Al llamar `finalizarCombate()`, el controlador instancia y muestra la sub-escena de resultados (victoria/derrota) desde la Vista. No hay clase separada para la pantalla; el controlador la gestiona. |

---

#### `Tanque` — Clase Abstracta
| | |
|---|---|
| **Atributos** | `# idTanque: String` · `# nombreModelo: String` · `# vidaMaxima: float` · `# vidaActual: float` · `# combustibleMaximo: float` · `# combustibleActual: float` · `# posicion: Vector2` · `# anguloCanon: float` · `# potenciaDisparo: float` · `# skinEquipada: TanqueCosmetico` |
| **Métodos** | `+ mover(direccion: int): void` · `+ ajustarAngulo(nuevoAngulo: float): void` · `+ ajustarPotencia(nuevaPotencia: float): void` · `+ recibirDano(cantidad: float): void` · `+ reabastecerCombustible(): void` · `+ estaDestruido(): bool` · `+ disparar(proyectil: Proyectil): void` |
| **HP acordado** | Todos los tanques parten de `vidaMaxima = 100.0`. La dificultad sube por cantidad de enemigos por misión. El HP de cada enemigo instanciado es fácil de sobrescribir al crearlo en la escena. |

---

#### `TanqueJugador` — hereda de `Tanque`
| | |
|---|---|
| **Atributos** | `- teclasMovimiento: Dictionary` |
| **Métodos** | `+ procesarEntradaTecladoRaton(): void` · `+ seleccionarMunicion(idProyectil: String): void` |

---

#### `TanqueIA` — hereda de `Tanque`
| | |
|---|---|
| **Atributos** | `- nivelDificultad: int` |
| **Métodos** | `+ calcularDisparoEstrategico(posicionObjetivo: Vector2): Dictionary` · `+ ejecutarAccionTurno(): void` |

---

#### `GestorProyectiles` *(actúa como Factory)*
| | |
|---|---|
| **Atributos** | `- proyectilesDisponibles: Array<Proyectil>` · `- historialUsoProyectiles: Array<Proyectil>` |
| **Métodos** | `+ seleccionarProyectil(tipo: String): Proyectil` *(método factory)* · `+ validarDisponibilidad(proyectil: Proyectil): bool` · `+ registrarUso(proyectil: Proyectil): void` · `+ reiniciarCicloMunicion(): void` |
| **Relaciones** | Agregación 1:5 → `Proyectil` |

---

#### `Proyectil` — Clase Abstracta
| | |
|---|---|
| **Atributos** | `# idProyectil: String` · `# nombre: String` · `# danoBase: float` · `# alcanceDisparo: float` · `# radioExplosion: float` · `# masa: float` · `# fueUtilizadoEnCiclo: bool` |
| **Métodos** | `+ calcularTrayectoriaParabolica(posInicio: Vector2, angulo: float, potencia: float, gravedad: float): Array<Vector2>` · `+ alImpactar(posicionImpacto: Vector2): void` |
| **Nota** | `gravedad` se obtiene de `GameConfig.GRAVEDAD`. La detección de colisión con tanques enemigos usa `Area2D` de Godot en el nodo del proyectil (no en el modelo de clases). |

---

#### Subclases de `Proyectil`
| Subclase | Características |
|---|---|
| `ProyectilEstandar` | Alcance alto, daño moderado, radio reducido |
| `ProyectilPesado` | Mayor masa, alcance corto, daño e impacto altos |
| `ProyectilDispersion` | Se divide en proyectiles menores al disparar |
| `ProyectilBombardeo` | Dispara bengala → ataque aéreo tras segundos |
| `ProyectilIncendiario` | Ráfaga de fuego + daño por segundo (DoT) |

---

#### `Tienda`
| | |
|---|---|
| **Atributos** | `- catalogoCosmeticos: Array<TanqueCosmetico>` |
| **Métodos** | `+ obtenerCatalogo(): Array<TanqueCosmetico>` · `+ procesarCompraSimulada(cosmetico: TanqueCosmetico): bool` · `+ equiparCosmetico(cosmetico: TanqueCosmetico, tanque: Tanque): void` |
| **Relaciones** | Agregación 1:1..* → `TanqueCosmetico` |

---

#### `TanqueCosmetico`
| | |
|---|---|
| **Atributos** | `+ idCosmetico: String` · `+ nombreTanqueHistorico: String` · `+ bandoPais: String` · `+ precioSugerido: float` · `+ esGratuito: bool` · `+ estaComprado: bool` · `+ rutaTextura2D: String` |

---

## 7. Patrón Factory: Implementación en Godot 4

`GestorProyectiles` actúa como Factory. `seleccionarProyectil(tipo)` es el punto de creación; cada proyectil es una `PackedScene`.

```gdscript
# Controladores/GestorProyectiles.gd
const _ESCENAS := {
    "estandar":   preload("res://Vistas/Proyectiles/ProyectilEstandar.tscn"),
    "pesado":     preload("res://Vistas/Proyectiles/ProyectilPesado.tscn"),
    "dispersion": preload("res://Vistas/Proyectiles/ProyectilDispersion.tscn"),
    "bombardeo":  preload("res://Vistas/Proyectiles/ProyectilBombardeo.tscn"),
    "incendiario":preload("res://Vistas/Proyectiles/ProyectilIncendiario.tscn"),
}

func seleccionarProyectil(tipo: String) -> Proyectil:
    var p: Proyectil = _ESCENAS[tipo].instantiate()
    if not validarDisponibilidad(p):
        return null
    return p
```

> **Razón:** El diagrama de clases ya le asigna a `GestorProyectiles` la responsabilidad de seleccionar, validar y registrar proyectiles. Crear una clase `ProjectileFactory` separada duplicaría esa responsabilidad. El patrón está aplicado dentro de `GestorProyectiles`.

---

## 8. Diagramas de Secuencia

### DS-1: Gestión de Misión

```
Jugador → gestorGuardado → datos:SaveData → gestorMisiones → mision → cinematica → controlador

1. Jugador solicita consultar misiones
2. gestorGuardado.cargarProgreso() → datos:SaveData
3. gestorMisiones.aplicarProgreso(datos)   ← NUEVO: aplica estaDesbloqueada a cada Mision
4. Jugador → gestorMisiones.obtenerMisiones() → Array<Mision>
5. Jugador → gestorMisiones.seleccionarMision(idMision)
6. GestorMisiones comprueba mision.estaDesbloqueada

   alt [mision.estaDesbloqueada == true]
     ref: Reproducción cinemática histórica (intro)
     ref: Iniciar combate
     mision.verificarCondicionVictoria()
     mision.verificarCondicionDerrota()

     alt [victoria]
       gestorMisiones.cargarSiguienteMision()
       gestorGuardado.registrarMisionDesbloqueada(idMision)
       gestorGuardado.guardarProgreso(datos)
         alt [true]  → guardado OK
         alt [false] → error, no confirmar guardado

     alt [derrota]
       No se desbloquea siguiente misión
       ControladorCombate llama sub-escena de resultado FALLIDO

   alt [mision.estaDesbloqueada == false]
     Flujo termina — misión bloqueada
```

---

### DS-2: Reproducción de Cinemática Histórica

```
Jugador → gestorMisiones → mision → cinematica → controlador

   alt [esIntroduccion == true]
     cinematica.reproducir()
     [Jugador ve panel con imagen + texto typewriter — pulsa "Continuar"]
     cinematica.finalizar()
     controlador.iniciarCombate()

   alt [esIntroduccion == false]   ← cierre post-victoria
     cinematica.reproducir()
     [Jugador ve resumen histórico post-misión]
     cinematica.finalizar()
     [NO se llama iniciarCombate() — flujo termina aquí]
```

---

### DS-3: Iniciar Combate

```
Jugador → controlador → mision → tanqueJugador → gestorProyectiles → tanqueIA

1. controlador.iniciarCombate()
2. estadoCombate = "EN_PROGRESO", turnoActual = "JUGADOR"

   loop [estadoCombate == "EN_PROGRESO"]

     [Turno Jugador]
     ref: Gestión tanque
     ref: Gestión proyectiles
     tanqueJugador.disparar(proyectil)
     controlador.evaluarConsecuenciasDisparo(proyectil)
       → Area2D detecta colisión → tanqueIA.recibirDano(cantidad)
     mision.verificarCondicionVictoria()
     mision.verificarCondicionDerrota()

     alt [victoria]
       controlador.finalizarCombate("VICTORIA")
       → muestra sub-escena de resultado VICTORIA
     alt [derrota]
       controlador.finalizarCombate("DERROTA")
       → muestra sub-escena de resultado DERROTA
     alt [combate continúa]
       controlador.cambiarTurno()   ← turnoActual = "IA"
       controlador.procesarTurnoIA()
       tanqueIA.calcularDisparoEstrategico(posObjetivo)
       tanqueIA.ejecutarAccionTurno()
       tanqueIA.disparar(proyectil)
       controlador.evaluarConsecuenciasDisparo(proyectil)
       [Verificar condiciones → cambiarTurno() → vuelve al jugador]
```

---

### DS-4: Gestión de Tanque

```
Jugador → tanqueJugador → controlador

   tanqueJugador.procesarEntradaTecladoRaton()

   alt [Rama A — Movimiento]
     alt [combustibleActual > 0]
       mover(-1) / mover(+1)  → actualiza posicion, reduce combustible
     alt [combustibleActual <= 0]
       movimiento bloqueado por este turno

   alt [Rama B — Ajuste del cañón]
     ajustarAngulo(nuevoAngulo)     ← mouse move
     ajustarPotencia(nuevaPotencia) ← distancia cursor al tanque

   alt [Rama C — Disparo]
     seleccionarMunicion(idProyectil)
     ref: Gestión proyectiles
     [si proyectil válido] → disparar(proyectil)
     controlador.evaluarConsecuenciasDisparo(proyectil)
     controlador.cambiarTurno()

   alt [Rama D — Inicio turno siguiente jugador]
     reabastecerCombustible()
```

---

### DS-5: Gestión de Proyectiles

```
Jugador → tanqueJugador → gestorProyectiles → proyectil:Proyectil → controlador → tanqueIA

   tanqueJugador.seleccionarMunicion(idProyectil)
   gestorProyectiles.seleccionarProyectil(tipo)    ← Factory
   gestorProyectiles.validarDisponibilidad(proyectil)

   alt [disponible == true]
     retorna instancia Proyectil
     tanqueJugador.disparar(proyectil)
     proyectil.calcularTrayectoriaParabolica(pos, angulo, potencia, GameConfig.GRAVEDAD)
       → Array<Vector2>
     [Area2D detecta posicionImpacto]
     proyectil.alImpactar(posicionImpacto)
     controlador.evaluarConsecuenciasDisparo(proyectil)
       → tanqueIA.recibirDano(cantidad)
     gestorProyectiles.registrarUso(proyectil)
     opt [todos usados en ciclo]
       gestorProyectiles.reiniciarCicloMunicion()

   alt [disponible == false]
     rechaza selección, no dispara
     [Jugador selecciona otro tipo disponible]
```

---

### DS-6: Comprar Cosméticos

```
Jugador → tienda → cosmetico:TanqueCosmetico → gestorGuardado → datos:SaveData → tanqueJugador

   tienda.obtenerCatalogo() → Array<TanqueCosmetico>
   [Jugador selecciona cosmético]

   alt [cosmetico.estaComprado == true]
     opt [jugador desea equiparlo]
       tienda.equiparCosmetico(cosmetico, tanqueJugador)

   alt [cosmetico.estaComprado == false]
     Jugador confirma adquisición
     tienda.procesarCompraSimulada(cosmetico)  ← sin pasarela real de pagos

     alt [procesarCompraSimulada == true]
       cosmetico.estaComprado = true
       gestorGuardado.registrarCosmeticoComprado(idCosmetico)
       gestorGuardado.guardarProgreso(datos)
         alt [true]  → persistido correctamente
           opt [equipar ahora]
             tienda.equiparCosmetico(cosmetico, tanqueJugador)
         alt [false] → error: no confirmar como guardado
     alt [procesarCompraSimulada == false]
       compra no realizada, estaComprado no cambia
```

---

## 9. Gaps Técnicos: Estado Final

| # | Gap | Decisión tomada |
|---|---|---|
| **G1** | `cargarProgreso()` no aplicaba `estaDesbloqueada` | ✅ **Resuelto:** Añadir `GestorMisiones.aplicarProgreso(datos: SaveData): void` al modelo |
| **G2** | Detección colisión proyectil → tanque no modelada | ✅ **Resuelto:** Se gestiona con `Area2D` de Godot en el nodo del proyectil (fuera del diagrama de clases) |
| **G3** | Fuente del valor `gravedad` no definida | ✅ **Resuelto:** `GameConfig.gd` Autoload con `const GRAVEDAD: float = 980.0`, fácil de modificar para balance |
| **G4** | Pantalla de resultados sin clase propia | ✅ **Resuelto:** Sub-escena de UI instanciada y gestionada por `ControladorCombate.finalizarCombate()` |

---

## 10. Decisiones de Arquitectura del Equipo

| Tema | Decisión |
|---|---|
| **HP de tanques** | Todos parten de 100 HP. La dificultad varía por cantidad de enemigos por misión. El HP de cada enemigo instanciado es fácil de sobrescribir en la escena de nivel. |
| **Colisión proyectil → tanque** | `Area2D` en los nodos de Godot (Vista). No está en el diagrama de clases. |
| **Gravedad** | `GameConfig.gd` Autoload global. Valor inicial 980.0 px/s². Un solo lugar para cambiar al hacer balance. |
| **Cinemáticas** | Panel sencillo: imagen de fondo + texto typewriter + botón "Continuar". Estructurada de forma modular para mejorar si hay tiempo. |
| **Idioma del código** | **Español** en nombres de clases, métodos y carpetas (consistente con el GDD y el equipo). |
| **Patrón arquitectónico** | **MVC en español**, aplicado a la estructura de carpetas del proyecto Godot. |

---

## 11. Estructura de Carpetas — MVC en Español

```
res://
│
├── Modelos/                    ← M: Datos puros (GDScript sin nodos)
│   ├── DatosMision.gd          (idMision, nombre, anio, estaDesbloqueada...)
│   ├── DatosMapa.gd            (tipoEntorno, limitesTerreno...)
│   ├── DatosTanque.gd          (vidaMaxima, combustibleMaximo...)
│   ├── DatosProyectil.gd       (danoBase, alcanceDisparo, radioExplosion...)
│   └── DatosCosmetico.gd       (idCosmetico, precioSugerido, estaComprado...)
│
├── Vistas/                     ← V: Escenas (.tscn) y scripts de presentación
│   ├── Niveles/
│   │   ├── Nivel1_Francia.tscn
│   │   ├── Nivel2_Alamein.tscn
│   │   └── Nivel3_Berlin.tscn
│   ├── UI/
│   │   ├── MenuPrincipal.tscn
│   │   ├── MenuMisiones.tscn
│   │   ├── HUD.tscn            (barra vida, combustible, selector munición)
│   │   ├── CinematicaPanel.tscn
│   │   ├── PantallaResultados.tscn
│   │   └── Tienda.tscn
│   ├── Tanques/
│   │   ├── TanqueJugador.tscn
│   │   └── TanqueIA.tscn
│   └── Proyectiles/
│       ├── ProyectilEstandar.tscn
│       ├── ProyectilPesado.tscn
│       ├── ProyectilDispersion.tscn
│       ├── ProyectilBombardeo.tscn
│       └── ProyectilIncendiario.tscn
│
├── Controladores/              ← C: Lógica de negocio (GDScript)
│   ├── ControladorCombate.gd
│   ├── GestorMisiones.gd
│   ├── GestorGuardado.gd
│   ├── GestorProyectiles.gd   ← actúa como Factory
│   └── Tienda.gd
│
├── Scripts/                    ← Scripts de entidades (herencia de nodos)
│   ├── Tanques/
│   │   ├── Tanque.gd           (clase abstracta base)
│   │   ├── TanqueJugador.gd
│   │   └── TanqueIA.gd
│   └── Proyectiles/
│       ├── Proyectil.gd        (clase abstracta base)
│       ├── ProyectilEstandar.gd
│       ├── ProyectilPesado.gd
│       ├── ProyectilDispersion.gd
│       ├── ProyectilBombardeo.gd
│       └── ProyectilIncendiario.gd
│
├── Autoloads/                  ← Singletons registrados en Project Settings
│   └── GameConfig.gd           (GRAVEDAD, otras constantes globales)
│
├── Imagenes/                   ← Assets de arte (mantiene nombre actual)
│   ├── Tanques/
│   ├── Fondos/
│   ├── UI/
│   └── Efectos/
│
└── Audio/                      ← Assets de audio
    ├── Musica/
    └── SFX/
```

> **Cómo funciona el MVC en Godot:**
> - **Modelos** son clases GDScript puras (o `Resource`) sin herencia de nodo. Guardan y exponen datos.
> - **Vistas** son escenas `.tscn` con sus scripts de presentación. Solo muestran datos; no tienen lógica de negocio.
> - **Controladores** son scripts que reciben señales de la Vista, operan sobre los Modelos, y actualizan la Vista mediante señales o llamadas directas.
> - `ControladorCombate` es el pivote central: recibe inputs del juego, coordina tanques, proyectiles y condiciones de misión.

---

*Fase 1 cerrada. Todas las decisiones tomadas. Lista para iniciar Fase 2 – Estado actual del proyecto.*
