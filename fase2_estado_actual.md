# Fase 2 – Estado Actual del Proyecto: second-war-now

> **Estado:** ✅ Completo · Lista para Fase 3 (Documentación).

---

## 1. Inventario Completo de Archivos Existentes

```
second-war-now/
├── .editorconfig               (charset = utf-8)
├── .gitattributes              (EOL normalizado a LF)
├── .gitignore                  (excluye .godot/ y /android/)
├── .godot/                     (generado por el motor — ignorado en git ✅)
├── icon.svg                    (ícono del proyecto)
├── icon.svg.import
├── project.godot               (configuración del proyecto)
│
├── Imagenes/
│   ├── Fondo1Mapa1.jpg         (152 KB — fondo del nivel 1)
│   ├── Fondo1Mapa1.jpg.import
│   ├── SueloMapa1.jpg          (17 KB — textura del suelo)
│   ├── SueloMapa1.jpg.import
│   ├── TanqueM4Sherman.png     (212 KB — sprite del tanque jugador)
│   └── TanqueM4Sherman.png.import
│
├── Jugador/
│   ├── MovimientoTanque.gd     (18 líneas — script de movimiento)
│   └── TanqueJugador.tscn      (escena del tanque jugador)
│
└── Niveles/
    ├── nivel_1.tscn            (escena del nivel 1 — escena principal)
    └── suelo.tscn              (escena reutilizable del suelo)
```

**Resumen numérico:**
- Scripts GDScript: **1**
- Escenas `.tscn`: **3**
- Imágenes: **3**
- Clases registradas en Godot: **1** (`moverPersonaje`)
- Autoloads configurados: **0**
- Sistemas de juego implementados: **0**

---

## 2. Análisis Archivo por Archivo

### `project.godot`
```
config/name = "SecondWarNow"
run/main_scene = uid://cqpsn2scylvk6   → apunta a suelo.tscn ⚠️
renderer = GL Compatibility (OpenGL)
physics/3d = Jolt Physics ⚠️
window/stretch = canvas_items + expand ✅
inputs: Izquierda, Derecha, Disparo ✅
```

**Problemas detectados:**
- `main_scene` apunta a `suelo.tscn` (la escena del suelo), **no** a `nivel_1.tscn` ni a ningún menú principal. Al correr el juego se abre el suelo solo, sin el tanque.
- `3d/physics_engine = Jolt Physics` está configurado, pero el juego es **2D**. Es un residuo que no afecta pero ensucia la config.
- No hay ningún Autoload registrado.

---

### `Jugador/MovimientoTanque.gd`
```gdscript
class_name moverPersonaje
extends CharacterBody2D

@export var SPEED = 200.0

func _physics_process(delta):
    if not is_on_floor():
        velocity += get_gravity() * delta
    var direction := Input.get_axis("Izquierda", "Derecha")
    if direction:
        velocity.x = direction * SPEED
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)
    move_and_slide()
```

**Lo que hace bien:**
- Usa `CharacterBody2D` + `move_and_slide()` ✅ (correcto para Godot 4).
- Aplica gravedad del motor cuando no está en el suelo ✅.
- Responde a los inputs configurados (`Izquierda`/`Derecha`) ✅.
- Usa `@export` para exponer velocidad desde el editor ✅.

**Problemas detectados:**
- **Nombre de clase** `moverPersonaje` no sigue convención PascalCase ni refleja que es un tanque. Debería ser `TanqueJugador`.
- **No hay barra de combustible:** el movimiento es ilimitado, sin restricción por turno.
- **No hay sistema de turnos:** el script procesa input en cada frame, no por turno.
- **No hay lógica de disparo:** el input `Disparo` está configurado en `project.godot` pero no se usa aquí.
- **Gravedad tomada del motor** (`get_gravity()`) en vez de `GameConfig.GRAVEDAD`. Inconsistente con la decisión de arquitectura.
- El script mezcla responsabilidades que en MVC corresponden a **Controlador** (lógica de movimiento) y **Modelo** (estado del tanque).
- No hay HP, no hay señales, no hereda de ninguna clase base `Tanque`.

---

### `Jugador/TanqueJugador.tscn`
```
Nodo raíz: CharacterBody2D (Jugador) + script MovimientoTanque.gd
├── Sprite2D (scale 0.5, 0.5 — TanqueM4Sherman.png)
├── CollisionShape2D — CapsuleShape2D (r=34, h=230) ⚠️
└── CollisionShape2D2 — RectangleShape2D (108×40)
```

**Lo que hace bien:**
- Estructura básica funcional para `CharacterBody2D` ✅.
- Sprite con escala correcta ✅.
- Tiene colisión ✅.

**Problemas detectados:**
- La `CapsuleShape2D` (r=34, h=230, rotada 90°) tiene dimensiones sospechosas para un tanque 2D lateral. Probablemente produce colisiones incorrectas.
- Hay **dos formas de colisión** que se superponen sin justificación clara.
- La escena no tiene: `Area2D` para detección de impactos de proyectil, nodo de cañón/punto de disparo, nodo de barra de vida/HUD, ni señales exportadas.
- No tiene grupo asignado (`add_to_group("tanque_jugador")`), lo que dificulta la detección de colisiones más adelante.

---

### `Niveles/suelo.tscn`
```
Nodo raíz: StaticBody2D (Suelo)
├── Sprite2D (scale 0.8, 0.799 — SueloMapa1.jpg)
└── CollisionShape2D — RectangleShape2D (658×78) [one_way_collision = true]
```

**Lo que hace bien:**
- `StaticBody2D` correcto para suelo ✅.
- `one_way_collision = true` permite que el tanque aterrice desde arriba ✅.
- Es una escena reutilizable (instanciada dos veces en nivel_1) ✅.

**Problemas menores:**
- La escala del sprite (0.8, 0.799) está desalineada respecto a la forma de colisión. Podría causar pequeños desajustes visuales.
- El nombre `suelo.tscn` es genérico; en la estructura MVC irá a `Vistas/Niveles/Suelo.tscn`.

---

### `Niveles/nivel_1.tscn`
```
Nodo raíz: Node2D (Nivel1)
├── Fondo1Mapa1: Sprite2D (scale 0.837, 0.967 — fondo)
├── Suelo (instancia suelo.tscn) — posición (276, 618)
├── Suelo2 (instancia suelo.tscn) — posición (925, 618)
└── Jugador (instancia TanqueJugador.tscn) — posición (174, 530)
```

**Lo que hace bien:**
- Composición modular con instancias de escenas ✅.
- Fondo y suelo presentes ✅.
- El tanque tiene posición de spawn inicial ✅.

**Problemas detectados:**
- El nivel no tiene: enemigos, lógica de misión, condiciones de victoria/derrota, sistema de turnos, HUD, ni cinemática de introducción.
- No hay `Camera2D` — si el tanque se mueve, no hay seguimiento de cámara.
- Los dos suelos están en posiciones fijas (276 y 925), creando un hueco en el medio del nivel.
- No es la escena principal del proyecto (ese bug está en `project.godot`).

---

### Imágenes

| Archivo | Tamaño | Estado |
|---|---|---|
| `TanqueM4Sherman.png` | 212 KB | ✅ Usable — sprite del tanque TNQ-01 |
| `Fondo1Mapa1.jpg` | 152 KB | ✅ Usable — fondo Nivel 1 (Francia rural) |
| `SueloMapa1.jpg` | 17 KB | ✅ Usable — textura de suelo |

Las tres imágenes están importadas por Godot (archivos `.import` presentes). Son reutilizables.

---

### Configuración Git
- `.gitignore` correcto: excluye `.godot/` ✅
- `.gitattributes` normaliza EOL a LF ✅
- **No hay commits registrados** (no se puede verificar desde aquí, pero el repo no tiene historial visible).

---

## 3. Brecha: Existente vs. Requerido

### Clases del Diagrama vs. lo que existe

| Clase del Diagrama | Existe | Estado |
|---|---|---|
| `GameConfig` (Autoload) | ❌ | Crear desde cero |
| `Juego` (Singleton) | ❌ | Crear desde cero |
| `GestorGuardado` | ❌ | Crear desde cero |
| `GestorMisiones` | ❌ | Crear desde cero |
| `Mision` | ❌ | Crear desde cero |
| `Mapa` | ❌ | Crear desde cero |
| `CinematicaHistorica` | ❌ | Crear desde cero |
| `ControladorCombate` | ❌ | Crear desde cero |
| `Tanque` (abstracta) | ❌ | Crear desde cero |
| `TanqueJugador` | ⚠️ | Existe parcialmente — requiere refactorización profunda |
| `TanqueIA` | ❌ | Crear desde cero |
| `GestorProyectiles` | ❌ | Crear desde cero |
| `Proyectil` (abstracta) | ❌ | Crear desde cero |
| 5 subclases Proyectil | ❌ | Crear desde cero |
| `Tienda` | ❌ | Crear desde cero |
| `TanqueCosmetico` | ❌ | Crear desde cero |

**Resultado:** 1 clase parcialmente existente (necesita refactorización), 15 clases por crear.

---

### Escenas vs. lo que existe

| Escena necesaria | Existe | Estado |
|---|---|---|
| `MenuPrincipal.tscn` | ❌ | Crear desde cero |
| `MenuMisiones.tscn` | ❌ | Crear desde cero |
| `Nivel1_Francia.tscn` | ⚠️ | `nivel_1.tscn` — base usable, requiere refactorización |
| `Nivel2_Alamein.tscn` | ❌ | Crear desde cero |
| `Nivel3_Berlin.tscn` | ❌ | Crear desde cero |
| `TanqueJugador.tscn` | ⚠️ | Existe — requiere refactorización |
| `TanqueIA.tscn` | ❌ | Crear desde cero |
| 5 escenas Proyectiles | ❌ | Crear desde cero |
| `HUD.tscn` | ❌ | Crear desde cero |
| `CinematicaPanel.tscn` | ❌ | Crear desde cero |
| `PantallaResultados.tscn` | ❌ | Crear desde cero |
| `Tienda.tscn` | ❌ | Crear desde cero |
| `Suelo.tscn` | ⚠️ | `suelo.tscn` — usable, solo mover y renombrar |

---

## 4. Qué se Puede Reutilizar (sin cambios o cambios menores)

| Elemento | Reutilizable como | Acción necesaria |
|---|---|---|
| `TanqueM4Sherman.png` | Sprite del TNQ-01 en `TanqueJugador.tscn` | Mover a `Imagenes/Tanques/` |
| `Fondo1Mapa1.jpg` | Fondo de `Nivel1_Francia.tscn` | Mover a `Imagenes/Fondos/` |
| `SueloMapa1.jpg` | Textura de suelo Nivel 1 | Mover a `Imagenes/Fondos/` |
| `suelo.tscn` | Base de `Suelo.tscn` | Mover a `Vistas/Niveles/`, renombrar |
| `nivel_1.tscn` | Base de `Nivel1_Francia.tscn` | Mover, renombrar y ampliar |
| `.gitignore` / `.gitattributes` | Configuración Git | Están correctos, no tocar |
| Inputs del `project.godot` | `Izquierda`, `Derecha`, `Disparo` | Válidos — agregar más inputs que faltan |
| `window/stretch` del `project.godot` | Configuración de resolución | Correcto, mantener |

---

## 5. Qué Hay que Refactorizar

### RF-01 — `MovimientoTanque.gd` → `TanqueJugador.gd`

**Qué cambiar y por qué:**

| Problema actual | Cambio requerido |
|---|---|
| `class_name moverPersonaje` | Renombrar a `TanqueJugador`, heredar de `Tanque` |
| Movimiento en cada frame | Movimiento restringido por turno + barra de combustible |
| Gravedad del motor (`get_gravity()`) | Usar `GameConfig.GRAVEDAD` (decisión de arquitectura) |
| No hay HP ni estado | Añadir `vidaActual`, `combustibleActual`, señales de daño |
| No hay lógica de disparo | Añadir `seleccionarMunicion()`, `disparar()` |
| No hay señales | Emitir señales al controlador (`turno_terminado`, `tanque_destruido`) |
| Mezcla lógica + presentación | Separar: script de controlador vs. script de vista |

### RF-02 — `TanqueJugador.tscn`

| Problema actual | Cambio requerido |
|---|---|
| Dos `CollisionShape2D` sin justificación | Revisar y dejar solo la forma correcta para un tanque lateral |
| Sin `Area2D` | Añadir `Area2D` para detección de impactos de proyectiles |
| Sin punto de disparo | Añadir nodo `Marker2D` como punto de origen del cañón |
| Sin `Camera2D` | Añadir `Camera2D` con seguimiento suave |
| Sin grupo asignado | Añadir grupo `"tanque_jugador"` |

### RF-03 — `nivel_1.tscn`

| Problema actual | Cambio requerido |
|---|---|
| Dos suelos en posiciones fijas con hueco | Rediseñar layout del terreno |
| Sin enemigos | Añadir puntos de spawn para `TanqueIA` |
| Sin cámara | Añadir `Camera2D` |
| Sin HUD | Instanciar `HUD.tscn` como hijo de CanvasLayer |
| Sin `ControladorCombate` | Añadir nodo del controlador como hijo del nivel |
| Sin cinemática de inicio | Instanciar `CinematicaPanel.tscn` |

### RF-04 — `project.godot`

| Problema actual | Cambio requerido |
|---|---|
| `main_scene` apunta a `suelo.tscn` | Cambiar a `MenuPrincipal.tscn` (o `Nivel1_Francia.tscn` temporalmente) |
| Motor de física 3D (Jolt) configurado | Eliminar/ignorar (no afecta 2D pero ensucia la config) |
| Sin Autoloads | Registrar `GameConfig`, `GestorGuardado`, `GestorMisiones`, `Tienda` |
| Faltan inputs | Añadir: `ui_aceptar`, `cambiar_municion`, `pausar` según diseño |

---

## 6. Qué Falta Crear (desde cero)

### Autoloads / Singletons
- `Autoloads/GameConfig.gd` — Constantes globales (GRAVEDAD, etc.)

### Controladores
- `Controladores/GestorGuardado.gd`
- `Controladores/GestorMisiones.gd`
- `Controladores/ControladorCombate.gd`
- `Controladores/GestorProyectiles.gd` (Factory)
- `Controladores/Tienda.gd`

### Modelos
- `Modelos/DatosMision.gd`
- `Modelos/DatosMapa.gd`
- `Modelos/DatosTanque.gd`
- `Modelos/DatosProyectil.gd`
- `Modelos/DatosCosmetico.gd`
- `Modelos/SaveData.gd`

### Scripts de entidades
- `Scripts/Tanques/Tanque.gd` (abstracta)
- `Scripts/Tanques/TanqueIA.gd`
- `Scripts/Proyectiles/Proyectil.gd` (abstracta)
- `Scripts/Proyectiles/ProyectilEstandar.gd`
- `Scripts/Proyectiles/ProyectilPesado.gd`
- `Scripts/Proyectiles/ProyectilDispersion.gd`
- `Scripts/Proyectiles/ProyectilBombardeo.gd`
- `Scripts/Proyectiles/ProyectilIncendiario.gd`

### Escenas de Vista — Tanques
- `Vistas/Tanques/TanqueIA.tscn`

### Escenas de Vista — Proyectiles (5)
- `Vistas/Proyectiles/ProyectilEstandar.tscn`
- `Vistas/Proyectiles/ProyectilPesado.tscn`
- `Vistas/Proyectiles/ProyectilDispersion.tscn`
- `Vistas/Proyectiles/ProyectilBombardeo.tscn`
- `Vistas/Proyectiles/ProyectilIncendiario.tscn`

### Escenas de Vista — UI
- `Vistas/UI/MenuPrincipal.tscn`
- `Vistas/UI/MenuMisiones.tscn`
- `Vistas/UI/HUD.tscn` (barra vida, combustible, selector munición, turnos)
- `Vistas/UI/CinematicaPanel.tscn` (imagen + typewriter + botón Continuar)
- `Vistas/UI/PantallaResultados.tscn` (victoria / derrota)
- `Vistas/UI/Tienda.tscn`

### Escenas de Vista — Niveles
- `Vistas/Niveles/Nivel2_Alamein.tscn`
- `Vistas/Niveles/Nivel3_Berlin.tscn`

### Datos / Assets
- `Datos/misiones_config.json` (definición estática de las 3 misiones)
- Sprites de 4 tanques cosméticos adicionales (arte)
- Sprites de 5 tipos de proyectiles (arte)
- Fondos de Nivel 2 (desierto) y Nivel 3 (urbano) (arte)
- Audio: música (3 pistas) + SFX (11 efectos)

---

## 7. Diagnóstico General

| Categoría | Completado | Pendiente |
|---|---|---|
| Configuración del proyecto | 40% | Autoloads, escena principal, inputs completos |
| Arquitectura MVC | 0% | Todo por crear |
| Mecánica de movimiento | 20% | Sin turnos, sin combustible, sin señales |
| Sistema de disparo | 0% | Todo por crear |
| Sistema de proyectiles | 0% | Todo por crear |
| IA enemiga | 0% | Todo por crear |
| Sistema de turnos | 0% | Todo por crear |
| UI / HUD | 0% | Todo por crear |
| Cinemáticas | 0% | Todo por crear |
| Guardado / progresión | 0% | Todo por crear |
| Tienda | 0% | Todo por crear |
| Arte (sprites/fondos) | 30% | Faltan 4 tanques, 5 proyectiles, 2 fondos |
| Audio | 0% | Todo por integrar |
| **Total estimado** | **~8%** | **~92%** |

---

## 8. Conclusión

El proyecto tiene una **base funcional mínima**: un tanque que se mueve con gravedad y colisión sobre un suelo, con un fondo. No hay ningún sistema de juego implementado.

**Lo positivo:** Las decisiones técnicas iniciales son correctas (Godot 4, `CharacterBody2D`, inputs configurados, escenas modulares). No hay deuda técnica grave — solo código incompleto.

**El reto real:** El 92% restante implica construir todos los sistemas de juego desde cero, respetando la arquitectura MVC y el diagrama de clases. La prioridad absoluta para que el juego sea jugable es:

1. Arquitectura base (MVC, Autoloads, clases abstractas)
2. Sistema de turnos + movimiento con combustible
3. Física de proyectil + Factory
4. IA básica
5. Condiciones de victoria/derrota
6. UI/HUD mínimo
7. Guardado
8. Cinemáticas + Tienda + arte/audio restante

---

*Fase 2 completada. Lista para Fase 3 – Documentación.*
