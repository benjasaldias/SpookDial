# Plan 1: Escena del escritorio con el arte — Plan de implementación

> **Para agentes:** SUB-SKILL REQUERIDO: usar `superpowers:subagent-driven-development` (recomendado) o `superpowers:executing-plans` para implementar este plan tarea por tarea. Los pasos usan casillas (`- [ ]`) para el seguimiento.

**Objetivo:** que al ejecutar el juego se vea el escritorio armado con el arte de Benja, igual a la maqueta. Además, que responda:

- los diales se mueven con un valor;
- las entradas del PC cambian de estado y abren el panel del chat;
- los objetos clickeables se resaltan;
- la pared tiene un parallax leve.

**Arquitectura:**

- Una escena principal, `scenes/desk/desk.tscn`, con dos planos:
  - `WallPlane`, que se mueve con el mouse;
  - `DeskPlane`, fijo.
- Componentes pequeños, cada uno con un script propio:
  - `DialGauge`;
  - `ChatEntry`;
  - `ChatPanel`;
  - `ClickableSprite`;
  - `ParallaxRig`.
- La matemática va aparte, en scripts puros con pruebas: ángulo del dial, desplazamiento del parallax y opacidad por píxel.

**Stack:**

- Godot 4.7.2 (GDScript con tipado estático).
- Aseprite Wizard 9.8.0.
- Las pruebas usan un ejecutor propio sin addons y corren sin interfaz con `~/tools/godot-wsl.sh`.

**Diseño de referencia:** `spook_dial_design.md` §6–7 y §16; inventario y posiciones en `docs/06` §3.

---

## Antes de empezar

- [ ] **Godot cerrado.** Todos los comandos con `godot-wsl.sh` necesitan que Benja tenga el editor cerrado: si dos Godot escriben `.godot/` a la vez, se corrompe la caché. Para las revisiones visuales, Benja lo abre al final de cada tarea indicada.
- [ ] **Importación sana.** Desde la carpeta del proyecto:

  ```bash
  grep -l "^valid=false" art/sprites/*.import | wc -l
  ```

  Esperado: `0`. Las importaciones exitosas no escriben `valid`; solo las fallidas escriben `valid=false`. Para reimportar una fallida, ver `CLAUDE.md` > Entorno técnico.
- [ ] **Git funciona:** `git status` lista archivos sin errores.

Todos los comandos de este plan se ejecutan desde `/mnt/c/Users/benja/OneDrive/Documents/spook-dial`.

**Commits:** cada tarea termina en un commit, pero Claude **pregunta a Benja antes de cada uno**. Al empezar la sesión, Benja puede autorizar de una vez todos los commits del plan (`CLAUDE.md`, regla 11). El push a GitHub solo se hace con autorización.

---

## Mapa de archivos

| Archivo | Responsabilidad |
| --- | --- |
| `test/test_case.gd` | Base de las pruebas: `check()` y `check_eq()` |
| `test/run_tests.gd` | Ejecuta todos los `test/test_*.gd` y sale con código 1 si alguno falla |
| `test/test_*.gd` | Pruebas de cada tarea |
| `project.godot` | Pantalla 1280×720, filtro Nearest, escena principal y color de fondo |
| `art/sprites/*.aseprite.import` | Excluir las capas `Entry` del PC; importar el panel del chat como textura |
| `scripts/desk/dial_math.gd` | Valor (0..1) → ángulo de la aguja |
| `scripts/desk/parallax_math.gd` | Posición del mouse → desplazamiento entero de un plano |
| `scripts/desk/pixel_hit.gd` | Si un punto cae sobre un píxel visible |
| `shaders/outline.gdshader` | Contorno interior para el resaltado |
| `scripts/desk/clickable_sprite.gd` | Resaltado al pasar el mouse y señal `clicked` |
| `scenes/desk/dial_gauge.tscn`, `scripts/desk/dial_gauge.gd` | Cara del dial y aguja que gira |
| `scenes/ui/chat_entry.tscn`, `scripts/ui/chat_entry.gd` | Entrada de un amigo en el PC: nombre, estado y temporizador |
| `scenes/ui/chat_panel.tscn`, `scripts/ui/chat_panel.gd` | Panel lateral del chat, por ahora solo abrir y cerrar |
| `scripts/desk/parallax_rig.gd` | Mueve los planos según el mouse |
| `scenes/desk/desk.tscn`, `scripts/desk/desk.gd` | La escena completa y sus conexiones |
| `tools/compare_png.py` | Compara una captura con la maqueta (herramienta de desarrollo) |

---

### Tarea 1: Ejecutor de pruebas

**Archivos:**

- Crear: `test/test_case.gd`, `test/run_tests.gd`, `test/test_runner_selfcheck.gd`

- [ ] **Paso 1: Escribir la base de las pruebas**

`test/test_case.gd`:

```gdscript
extends RefCounted
## Base mínima para las pruebas. Cada método test_* usa check()/check_eq()
## y termina con `return true` (si una prueba se cae a la mitad, devuelve null y cuenta como falla).

var errors: Array[String] = []


func reset_errors() -> void:
	errors.clear()


func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)


func check_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		errors.append("%s: esperado <%s>, obtenido <%s>" % [message, str(expected), str(actual)])
```

- [ ] **Paso 2: Escribir el ejecutor**

`test/run_tests.gd`:

```gdscript
extends SceneTree
## Ejecuta todos los res://test/test_*.gd. Sale con código 1 si alguna prueba falla.
## Uso: ~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd

const TEST_DIR := "res://test"

var _passed := 0
var _failed := 0


func _initialize() -> void:
	var files := Array(DirAccess.get_files_at(TEST_DIR))
	files.sort()
	for file_name: String in files:
		if file_name.begins_with("test_") and file_name.ends_with(".gd") and file_name != "test_case.gd":
			_run_suite(TEST_DIR.path_join(file_name))
	print("\n%d pruebas OK, %d fallidas" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _run_suite(path: String) -> void:
	var script: GDScript = load(path)
	var suite: Object = script.new()
	for method: Dictionary in script.get_script_method_list():
		var method_name: String = method["name"]
		if not method_name.begins_with("test_"):
			continue
		suite.call("reset_errors")
		var finished: Variant = suite.call(method_name)
		var errors: Array = suite.get("errors")
		if finished != true:
			errors.append("la prueba no terminó (revisa SCRIPT ERROR más arriba)")
		if errors.is_empty():
			_passed += 1
			print("OK     %s :: %s" % [path.get_file(), method_name])
		else:
			_failed += 1
			print("FALLA  %s :: %s" % [path.get_file(), method_name])
			for error: String in errors:
				print("         - " + error)
```

- [ ] **Paso 3: Escribir una prueba del propio ejecutor**

`test/test_runner_selfcheck.gd`:

```gdscript
extends "res://test/test_case.gd"


func test_check_eq_registra_diferencias() -> bool:
	var probe: RefCounted = load("res://test/test_case.gd").new()
	probe.check_eq(1, 2, "uno contra dos")
	probe.check_eq(3, 3, "tres contra tres")
	check_eq(probe.errors.size(), 1, "errores registrados")
	return true
```

- [ ] **Paso 4: Ejecutar**

Comando: `~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd`

Esperado: termina con `1 pruebas OK, 0 fallidas` y código de salida 0 (`echo $?` → `0`).

- [ ] **Paso 5: Commit**

```bash
git add test/
git commit -m "Ejecutor de pruebas sin addons" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Tarea 2: Configuración de pantalla y texturas

**Archivos:**

- Crear: `test/test_project_settings.gd`
- Modificar: `project.godot` (secciones `[application]`, `[display]` y `[rendering]`)

- [ ] **Paso 1: Escribir la prueba**

`test/test_project_settings.gd`:

```gdscript
extends "res://test/test_case.gd"


func test_pantalla_1280x720_con_aspecto_fijo() -> bool:
	check_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 1280, "ancho")
	check_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 720, "alto")
	check_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items", "stretch mode")
	check_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "keep", "aspect")
	return true


func test_texturas_nearest_y_snap_a_pixel() -> bool:
	check_eq(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter"), 0, "filtro Nearest")
	check_eq(ProjectSettings.get_setting("rendering/2d/snap/snap_2d_transforms_to_pixel"), true, "snap a píxel")
	return true


func test_escena_principal_es_el_escritorio() -> bool:
	check_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/desk/desk.tscn", "escena principal")
	return true
```

- [ ] **Paso 2: Ejecutar y ver que falla**

Comando: `~/tools/godot-wsl.sh --headless --path "$PWD" -s res://test/run_tests.gd`

Esperado: 3 FALLA en `test_project_settings.gd`, por ejemplo `ancho: esperado <1280>, obtenido <1152>` y `aspect: esperado <keep>, obtenido <expand>`.

- [ ] **Paso 3: Modificar `project.godot`**

1. En `[application]`, agregar:

   ```ini
   run/main_scene="res://scenes/desk/desk.tscn"
   ```

2. Reemplazar la sección `[display]` completa por:

   ```ini
   [display]

   window/size/viewport_width=1280
   window/size/viewport_height=720
   window/stretch/mode="canvas_items"
   window/stretch/aspect="keep"
   ```

3. En `[rendering]`, agregar:

   ```ini
   textures/canvas_textures/default_texture_filter=0
   2d/snap/snap_2d_transforms_to_pixel=true
   environment/defaults/default_clear_color=Color(0.012, 0.024, 0.043, 1)
   ```

El color de fondo es el más oscuro de la pared: si el parallax deja ver 2 o 3 px de borde, no se nota.

- [ ] **Paso 4: Ejecutar y ver que pasa**

Mismo comando. Esperado: `4 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add project.godot test/test_project_settings.gd
git commit -m "Pantalla 1280x720, filtro Nearest y escena principal" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Tarea 3: Importación del arte

Dos archivos se importan distinto que el resto:

- `pc_sprite` debe excluir sus capas `Entry1` a `Entry3`, porque las entradas son escenas aparte;
- `screen_sprite` debe ser una textura, para usarlo en la interfaz.

**Archivos:**

- Crear: `test/test_art_imports.gd`
- Modificar: `art/sprites/pc_sprite.aseprite.import`, `art/sprites/screen_sprite.aseprite.import`

- [ ] **Paso 1: Escribir la prueba**

`test/test_art_imports.gd`:

```gdscript
extends "res://test/test_case.gd"

const SPRITES := "res://art/sprites/"


func test_sprites_importados_como_spriteframes() -> bool:
	for sprite_name in ["background", "exterior", "curtains", "window", "enemy", "glasspane", "dial",
			"arrow", "desk", "cables", "mixer", "phone", "pc", "entry", "microphone", "notebook"]:
		var resource := load(SPRITES + sprite_name + "_sprite.aseprite")
		check(resource is SpriteFrames, sprite_name + " debería importarse como SpriteFrames")
	return true


func test_pc_sin_capas_de_entradas() -> bool:
	var frames: SpriteFrames = load(SPRITES + "pc_sprite.aseprite")
	var image := frames.get_frame_texture(&"default", 0).get_image()
	# (150, 30) está dentro de Entry1: con la capa sería azul (37, 47, 153); sin ella, pantalla negra.
	check(image.get_pixel(150, 30).b < 0.4, "la zona de Entry1 no debería ser azul")
	return true


func test_panel_como_textura() -> bool:
	var panel: Variant = load(SPRITES + "screen_sprite.aseprite")
	check(panel is Texture2D, "screen_sprite debería ser Texture2D")
	if panel is Texture2D:
		check_eq(panel.get_size(), Vector2(449, 696), "tamaño del panel")
	return true
```

- [ ] **Paso 2: Ejecutar y ver que falla**

Esperado: FALLA en `test_pc_sin_capas_de_entradas` y en `test_panel_como_textura`.

- [ ] **Paso 3: Editar los `.import`**

1. En `art/sprites/pc_sprite.aseprite.import`, cambiar la línea del patrón por:

   ```ini
   layer/exclude_layers_pattern="^Entry"
   ```

2. En `art/sprites/screen_sprite.aseprite.import`:
   - cambiar `importer=` por `importer="aseprite_wizard.plugin.static-texture"`;
   - cambiar `type=` por `type="PortableCompressedTexture2D"`;
   - borrar la línea `valid=` si existe;
   - reemplazar todo `[params]` por:

   ```ini
   [params]

   layer/exclude_layers_pattern=""
   layer/only_visible_layers=false
   layer/split_layers=false
   first_frame_only=true
   sheet/sheet_type="packed"
   sheet/sheet_columns=12
   sheet/scale=1
   ```

3. Forzar la reimportación de esos dos archivos. Hay que borrar el `.md5` **y** el `.res` generados: con solo el `.md5`, Godot no reimporta (comprobado el 26-10-2026).

   ```bash
   rm -f .godot/imported/pc_sprite.aseprite-* .godot/imported/screen_sprite.aseprite-*
   ~/tools/godot-wsl.sh --headless --path "$PWD" --import
   ```

- [ ] **Paso 4: Ejecutar las pruebas y ver que pasan**

Esperado: `7 pruebas OK, 0 fallidas`, y ningún `.import` con `valid=false`.

**Si en vez de eso el `.import` vuelve a su estado anterior**, Godot no aceptó el cambio de importador por archivo. Plan B, que hace Benja en Godot con las instrucciones de `docs/04`:

- seleccionar el archivo;
- en la pestaña **Import**, elegir *Import As* = **Aseprite Texture**;
- poner el patrón;
- presionar **Reimport**.

- [ ] **Paso 5: Commit**

```bash
git add art/sprites/*.import test/test_art_imports.gd
git commit -m "Importación: PC sin entradas y panel como textura" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Tarea 4: Matemática del dial

**Archivos:**

- Crear: `test/test_dial_math.gd`, `scripts/desk/dial_math.gd`

- [ ] **Paso 1: Escribir la prueba**

`test/test_dial_math.gd`:

```gdscript
extends "res://test/test_case.gd"

const DialMath := preload("res://scripts/desk/dial_math.gd")


func test_valor_cero_y_uno_dan_los_extremos() -> bool:
	check_eq(DialMath.value_to_degrees(0.0, -120.0, 120.0), -120.0, "valor 0")
	check_eq(DialMath.value_to_degrees(1.0, -120.0, 120.0), 120.0, "valor 1")
	return true


func test_valor_medio_apunta_arriba() -> bool:
	check_eq(DialMath.value_to_degrees(0.5, -120.0, 120.0), 0.0, "valor 0,5")
	return true


func test_valores_fuera_de_rango_se_limitan() -> bool:
	check_eq(DialMath.value_to_degrees(-0.3, -120.0, 120.0), -120.0, "bajo 0")
	check_eq(DialMath.value_to_degrees(1.7, -120.0, 120.0), 120.0, "sobre 1")
	return true
```

- [ ] **Paso 2: Ejecutar y ver que falla**

Esperado: error de carga, porque `dial_math.gd` no existe; el ejecutor marca la suite con FALLA.

- [ ] **Paso 3: Implementar**

`scripts/desk/dial_math.gd`:

```gdscript
extends RefCounted
## Conversión pura del valor de un medidor (0..1) al ángulo de la aguja.


static func value_to_degrees(value: float, min_degrees: float, max_degrees: float) -> float:
	return lerpf(min_degrees, max_degrees, clampf(value, 0.0, 1.0))
```

- [ ] **Paso 4: Ejecutar y ver que pasa**

Esperado: `10 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/desk/dial_math.gd test/test_dial_math.gd
git commit -m "Matemática del dial" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Tarea 5: Matemática del parallax

**Archivos:**

- Crear: `test/test_parallax_math.gd`, `scripts/desk/parallax_math.gd`

- [ ] **Paso 1: Escribir la prueba**

`test/test_parallax_math.gd`:

```gdscript
extends "res://test/test_case.gd"

const ParallaxMath := preload("res://scripts/desk/parallax_math.gd")
const SCREEN := Vector2(1280, 720)
const MAX := Vector2(3, 2)


func test_mouse_al_centro_no_mueve() -> bool:
	check_eq(ParallaxMath.offset_for(Vector2(640, 360), SCREEN, MAX), Vector2i.ZERO, "centro")
	return true


func test_bordes_dan_el_maximo_en_la_direccion_del_mouse() -> bool:
	check_eq(ParallaxMath.offset_for(Vector2(1280, 360), SCREEN, MAX), Vector2i(3, 0), "borde derecho")
	check_eq(ParallaxMath.offset_for(Vector2(0, 0), SCREEN, MAX), Vector2i(-3, -2), "esquina superior izquierda")
	return true


func test_fuera_de_la_pantalla_se_limita() -> bool:
	check_eq(ParallaxMath.offset_for(Vector2(2000, -50), SCREEN, MAX), Vector2i(3, -2), "fuera")
	return true


func test_resultado_redondeado_a_pixel_entero() -> bool:
	check_eq(ParallaxMath.offset_for(Vector2(960, 360), SCREEN, MAX), Vector2i(2, 0), "a 3/4 del ancho: 1,5 → 2")
	return true
```

- [ ] **Paso 2: Ejecutar y ver que falla**

Esperado: FALLA (`parallax_math.gd` no existe).

- [ ] **Paso 3: Implementar**

`scripts/desk/parallax_math.gd`:

```gdscript
extends RefCounted
## Desplazamiento entero de un plano según el mouse.
## Mouse al centro: (0, 0). Mouse en un borde: ±max_offset, en la misma dirección que el mouse.


static func offset_for(mouse_position: Vector2, viewport_size: Vector2, max_offset: Vector2) -> Vector2i:
	var half := viewport_size * 0.5
	var normalized := ((mouse_position - half) / half).clamp(Vector2(-1, -1), Vector2(1, 1))
	return Vector2i((normalized * max_offset).round())
```

- [ ] **Paso 4: Ejecutar y ver que pasa**

Esperado: `14 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/desk/parallax_math.gd test/test_parallax_math.gd
git commit -m "Matemática del parallax" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Tarea 6: Opacidad por píxel

**Archivos:**

- Crear: `test/test_pixel_hit.gd`, `scripts/desk/pixel_hit.gd`

- [ ] **Paso 1: Escribir la prueba**

`test/test_pixel_hit.gd`:

```gdscript
extends "res://test/test_case.gd"

const PixelHit := preload("res://scripts/desk/pixel_hit.gd")


func _bitmap_with_one_pixel() -> BitMap:
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.set_pixel(1, 1, Color.WHITE)
	return PixelHit.bitmap_from_texture(ImageTexture.create_from_image(image))


func test_pixel_opaco_y_transparente() -> bool:
	var bitmap := _bitmap_with_one_pixel()
	check(PixelHit.is_opaque(bitmap, Vector2(1.5, 1.2)), "(1,1) es opaco")
	check(not PixelHit.is_opaque(bitmap, Vector2(2, 2)), "(2,2) es transparente")
	return true


func test_fuera_de_la_imagen_no_es_opaco() -> bool:
	var bitmap := _bitmap_with_one_pixel()
	check(not PixelHit.is_opaque(bitmap, Vector2(-1, 0)), "x negativa")
	check(not PixelHit.is_opaque(bitmap, Vector2(10, 10)), "más allá del borde")
	return true


func test_esquinas_reales_del_celular() -> bool:
	var frames: SpriteFrames = load("res://art/sprites/phone_sprite.aseprite")
	var bitmap := PixelHit.bitmap_from_texture(frames.get_frame_texture(&"default", 0))
	check(not PixelHit.is_opaque(bitmap, Vector2(0, 0)), "la esquina (0,0) del celular es transparente")
	check(PixelHit.is_opaque(bitmap, Vector2(43, 27)), "el centro del celular es opaco")
	return true
```

- [ ] **Paso 2: Ejecutar y ver que falla**

Esperado: FALLA (`pixel_hit.gd` no existe).

- [ ] **Paso 3: Implementar**

`scripts/desk/pixel_hit.gd`:

```gdscript
extends RefCounted
## Prueba si un punto local cae sobre un píxel visible de una textura.


static func bitmap_from_texture(texture: Texture2D) -> BitMap:
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(texture.get_image(), 0.1)
	return bitmap


static func is_opaque(bitmap: BitMap, local_position: Vector2) -> bool:
	var point := Vector2i(local_position.floor())
	var size := bitmap.get_size()
	if point.x < 0 or point.y < 0 or point.x >= size.x or point.y >= size.y:
		return false
	return bitmap.get_bitv(point)
```

- [ ] **Paso 4: Ejecutar y ver que pasa**

Esperado: `17 pruebas OK, 0 fallidas`.

- [ ] **Paso 5: Commit**

```bash
git add scripts/desk/pixel_hit.gd test/test_pixel_hit.gd
git commit -m "Detección de opacidad por píxel" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Tarea 7: Shader de contorno y ClickableSprite

**Archivos:**

- Crear: `shaders/outline.gdshader`, `scripts/desk/clickable_sprite.gd`, `test/test_clickable_sprite.gd`

- [ ] **Paso 1: Escribir la prueba**

`test/test_clickable_sprite.gd`:

```gdscript
extends "res://test/test_case.gd"

const CLICKABLE := preload("res://scripts/desk/clickable_sprite.gd")


func _make_phone() -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.set_script(CLICKABLE)
	sprite.sprite_frames = load("res://art/sprites/phone_sprite.aseprite")
	sprite.centered = false
	(Engine.get_main_loop() as SceneTree).root.add_child(sprite)
	return sprite


func test_usa_el_shader_de_contorno_apagado() -> bool:
	var phone := _make_phone()
	var material := phone.material as ShaderMaterial
	check(material != null, "tiene ShaderMaterial")
	if material:
		check_eq(material.get_shader_parameter("enabled"), false, "contorno apagado al inicio")
	phone.free()
	return true


func test_resaltado_enciende_el_contorno() -> bool:
	var phone := _make_phone()
	phone.hovered = true
	check_eq((phone.material as ShaderMaterial).get_shader_parameter("enabled"), true, "contorno encendido")
	phone.free()
	return true


func test_clic_con_resaltado_emite_clicked() -> bool:
	var phone := _make_phone()
	var received := [false]
	phone.clicked.connect(func() -> void: received[0] = true)
	phone.hovered = true
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	phone._unhandled_input(click)
	check(received[0], "emitió clicked")
	phone.free()
	return true
```

- [ ] **Paso 2: Ejecutar y ver que falla**

Esperado: FALLA (`clickable_sprite.gd` no existe).

- [ ] **Paso 3: Implementar el shader**

`shaders/outline.gdshader`:

```glsl
shader_type canvas_item;
// Contorno interior de 1 píxel para resaltar objetos clickeables.
// Pensado para sprites de un solo frame: su textura es exactamente el sprite (UV de 0 a 1).

uniform bool enabled = false;
uniform vec4 outline_color : source_color = vec4(1.0, 0.95, 0.7, 1.0);

float alpha_at(sampler2D tex, vec2 uv) {
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		return 0.0;
	}
	return texture(tex, uv).a;
}

void fragment() {
	if (enabled && COLOR.a > 0.0) {
		vec2 px = TEXTURE_PIXEL_SIZE;
		float neighbors = alpha_at(TEXTURE, UV + vec2(px.x, 0.0))
			* alpha_at(TEXTURE, UV - vec2(px.x, 0.0))
			* alpha_at(TEXTURE, UV + vec2(0.0, px.y))
			* alpha_at(TEXTURE, UV - vec2(0.0, px.y));
		if (neighbors == 0.0) {
			COLOR = outline_color;
		}
	}
}
```

- [ ] **Paso 4: Implementar ClickableSprite**

`scripts/desk/clickable_sprite.gd`:

```gdscript
extends AnimatedSprite2D
## Objeto del escritorio que se resalta al pasar el mouse y emite `clicked`.
## Para sprites de un solo frame con centered = false.

signal clicked

const PixelHit := preload("res://scripts/desk/pixel_hit.gd")
const OUTLINE_SHADER := preload("res://shaders/outline.gdshader")

var hovered := false:
	set(value):
		if value == hovered:
			return
		hovered = value
		(material as ShaderMaterial).set_shader_parameter("enabled", value)

var _bitmap: BitMap


func _ready() -> void:
	var outline := ShaderMaterial.new()
	outline.shader = OUTLINE_SHADER
	outline.set_shader_parameter("enabled", false)
	material = outline
	_bitmap = PixelHit.bitmap_from_texture(sprite_frames.get_frame_texture(animation, 0))


func _process(_delta: float) -> void:
	hovered = is_visible_in_tree() and PixelHit.is_opaque(_bitmap, get_local_mouse_position() - offset)


func _unhandled_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if hovered and mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()
		get_viewport().set_input_as_handled()
```

- [ ] **Paso 5: Ejecutar y ver que pasa**

Esperado: `20 pruebas OK, 0 fallidas`.

- [ ] **Paso 6: Commit**

```bash
git add shaders/outline.gdshader scripts/desk/clickable_sprite.gd test/test_clickable_sprite.gd
git commit -m "Objetos clickeables con contorno" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Tarea 8: DialGauge

**Archivos:**

- Crear: `scripts/desk/dial_gauge.gd`, `scenes/desk/dial_gauge.tscn`, `test/test_dial_gauge.gd`

- [ ] **Paso 1: Escribir la prueba**

`test/test_dial_gauge.gd`:

```gdscript
extends "res://test/test_case.gd"

const DIAL := preload("res://scenes/desk/dial_gauge.tscn")


func _make_dial() -> Node2D:
	var dial := DIAL.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(dial)
	return dial


func test_la_aguja_sigue_al_valor() -> bool:
	var dial := _make_dial()
	var needle := dial.get_node("Needle") as AnimatedSprite2D
	dial.value = 0.0
	check(is_equal_approx(needle.rotation_degrees, -120.0), "valor 0: %s" % needle.rotation_degrees)
	dial.value = 1.0
	check(is_equal_approx(needle.rotation_degrees, 120.0), "valor 1: %s" % needle.rotation_degrees)
	dial.free()
	return true


func test_color_de_la_aguja() -> bool:
	var dial := _make_dial()
	dial.needle_color = &"red"
	check_eq((dial.get_node("Needle") as AnimatedSprite2D).animation, &"red", "animación roja")
	dial.free()
	return true


func test_eje_de_giro_en_la_base_de_la_aguja() -> bool:
	var dial := _make_dial()
	var needle := dial.get_node("Needle") as AnimatedSprite2D
	check_eq(needle.position, Vector2(56, 56), "eje en el centro del dial")
	check_eq(needle.offset, Vector2(-7, -43), "píxel (7,43) del archivo sobre el eje")
	dial.free()
	return true
```

- [ ] **Paso 2: Ejecutar y ver que falla**

Esperado: FALLA (la escena no existe).

- [ ] **Paso 3: Implementar el script**

`scripts/desk/dial_gauge.gd`:

```gdscript
@tool
extends Node2D
## Dial de la pared: cara fija y aguja que gira según `value` (0..1).
## El eje de la aguja es el centro del dial: (56, 56) dentro de dial_sprite.

const DialMath := preload("res://scripts/desk/dial_math.gd")

@export_range(0.0, 1.0) var value := 1.0:
	set(new_value):
		value = clampf(new_value, 0.0, 1.0)
		_update_needle()
@export var needle_color: StringName = &"green":
	set(new_color):
		needle_color = new_color
		_update_needle()
@export var min_degrees := -120.0
@export var max_degrees := 120.0

@onready var _needle: AnimatedSprite2D = $Needle


func _ready() -> void:
	_update_needle()


func _update_needle() -> void:
	if not is_node_ready():
		return
	_needle.animation = needle_color
	_needle.rotation_degrees = DialMath.value_to_degrees(value, min_degrees, max_degrees)
```

- [ ] **Paso 4: Crear la escena**

`scenes/desk/dial_gauge.tscn`:

```ini
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/desk/dial_gauge.gd" id="dial_script"]
[ext_resource type="SpriteFrames" path="res://art/sprites/dial_sprite.aseprite" id="face"]
[ext_resource type="SpriteFrames" path="res://art/sprites/arrow_sprite.aseprite" id="needle"]

[node name="DialGauge" type="Node2D"]
script = ExtResource("dial_script")

[node name="Face" type="AnimatedSprite2D" parent="."]
sprite_frames = ExtResource("face")
centered = false

[node name="Needle" type="AnimatedSprite2D" parent="."]
position = Vector2(56, 56)
sprite_frames = ExtResource("needle")
animation = &"green"
centered = false
offset = Vector2(-7, -43)
```

- [ ] **Paso 5: Ejecutar y ver que pasa**

Esperado: `23 pruebas OK, 0 fallidas`.

- [ ] **Paso 6: Commit**

```bash
git add scripts/desk/dial_gauge.gd scenes/desk/dial_gauge.tscn test/test_dial_gauge.gd
git commit -m "Dial con aguja que sigue un valor" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Tarea 9: ChatEntry

**Archivos:**

- Crear: `scripts/ui/chat_entry.gd`, `scenes/ui/chat_entry.tscn`, `test/test_chat_entry.gd`

- [ ] **Paso 1: Escribir la prueba**

`test/test_chat_entry.gd`:

```gdscript
extends "res://test/test_case.gd"

const ENTRY := preload("res://scenes/ui/chat_entry.tscn")
const ChatEntry := preload("res://scripts/ui/chat_entry.gd")


func _make_entry() -> Node2D:
	var entry := ENTRY.instantiate()
	entry.display_name = "León"
	(Engine.get_main_loop() as SceneTree).root.add_child(entry)
	return entry


func test_nombre_y_estado_inicial() -> bool:
	var entry := _make_entry()
	check_eq((entry.get_node("NameLabel") as Label).text, "León", "nombre")
	check_eq((entry.get_node("Background") as AnimatedSprite2D).animation, &"idle", "animación inicial")
	check(not (entry.get_node("TimerLabel") as Label).visible, "sin temporizador al inicio")
	entry.free()
	return true


func test_estados() -> bool:
	var entry := _make_entry()
	var background := entry.get_node("Background") as AnimatedSprite2D
	entry.set_state(ChatEntry.State.WARNING)
	check_eq(background.animation, &"warning", "alerta")
	entry.set_state(ChatEntry.State.DISCONNECTED)
	check_eq(background.animation, &"idle", "desconectado usa idle")
	check_eq(background.modulate, Color(0.45, 0.45, 0.5), "desconectado en gris")
	entry.free()
	return true


func test_temporizador() -> bool:
	var entry := _make_entry()
	var timer := entry.get_node("TimerLabel") as Label
	entry.set_seconds_left(12)
	check(timer.visible, "visible con segundos")
	check_eq(timer.text, "12", "texto")
	entry.set_seconds_left(-1)
	check(not timer.visible, "oculto con -1")
	entry.free()
	return true
```

- [ ] **Paso 2: Ejecutar y ver que falla**

Esperado: FALLA (la escena no existe).

- [ ] **Paso 3: Implementar el script**

`scripts/ui/chat_entry.gd`:

```gdscript
extends Node2D
## Entrada de un amigo en la pantalla del PC (243×26).
## El arte pone el fondo; Godot pone el nombre, el estado y el temporizador.

signal pressed

enum State { IDLE, WARNING, DISCONNECTED, SELECTED }

const SIZE := Vector2(243, 26)
const STATE_MODULATE := {
	State.IDLE: Color(1, 1, 1),
	State.WARNING: Color(1, 1, 1),
	State.DISCONNECTED: Color(0.45, 0.45, 0.5),
	State.SELECTED: Color(1.3, 1.3, 1.3),
}

@export var display_name := "":
	set(value):
		display_name = value
		if is_node_ready():
			_name_label.text = value

var state: State = State.IDLE

@onready var _background: AnimatedSprite2D = $Background
@onready var _name_label: Label = $NameLabel
@onready var _timer_label: Label = $TimerLabel


func _ready() -> void:
	_name_label.text = display_name
	set_state(State.IDLE)
	set_seconds_left(-1)


func set_state(new_state: State) -> void:
	state = new_state
	_background.play(&"warning" if new_state == State.WARNING else &"idle")
	_background.modulate = STATE_MODULATE[new_state]


## Muestra los segundos restantes. Con un valor negativo, oculta el temporizador.
func set_seconds_left(seconds: int) -> void:
	_timer_label.visible = seconds >= 0
	_timer_label.text = str(seconds)


func _unhandled_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT \
			and Rect2(Vector2.ZERO, SIZE).has_point(get_local_mouse_position()):
		pressed.emit()
		get_viewport().set_input_as_handled()
```

- [ ] **Paso 4: Crear la escena**

`scenes/ui/chat_entry.tscn`:

```ini
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/ui/chat_entry.gd" id="entry_script"]
[ext_resource type="SpriteFrames" path="res://art/sprites/entry_sprite.aseprite" id="entry_frames"]

[node name="ChatEntry" type="Node2D"]
script = ExtResource("entry_script")

[node name="Background" type="AnimatedSprite2D" parent="."]
sprite_frames = ExtResource("entry_frames")
animation = &"idle"
centered = false

[node name="NameLabel" type="Label" parent="."]
offset_left = 6.0
offset_top = 3.0
offset_right = 180.0
offset_bottom = 23.0
theme_override_font_sizes/font_size = 12
text = "AMIGO"

[node name="TimerLabel" type="Label" parent="."]
offset_left = 186.0
offset_top = 3.0
offset_right = 224.0
offset_bottom = 23.0
theme_override_font_sizes/font_size = 12
horizontal_alignment = 2
```

El temporizador termina en x = 224 para no tapar el ícono ⚠ que el arte tiene a la derecha.

- [ ] **Paso 5: Ejecutar y ver que pasa**

Esperado: `26 pruebas OK, 0 fallidas`.

- [ ] **Paso 6: Commit**

```bash
git add scripts/ui/chat_entry.gd scenes/ui/chat_entry.tscn test/test_chat_entry.gd
git commit -m "Entradas del PC con estados y temporizador" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Tarea 10: ChatPanel provisional

**Archivos:**

- Crear: `scripts/ui/chat_panel.gd`, `scenes/ui/chat_panel.tscn`, `test/test_chat_panel.gd`

- [ ] **Paso 1: Escribir la prueba**

`test/test_chat_panel.gd`:

```gdscript
extends "res://test/test_case.gd"

const PANEL := preload("res://scenes/ui/chat_panel.tscn")


func _make_panel() -> Control:
	var panel := PANEL.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(panel)
	return panel


func test_empieza_oculto_y_se_abre_con_el_nombre() -> bool:
	var panel := _make_panel()
	check(not panel.visible, "oculto al inicio")
	panel.open_for("Gonzalo")
	check(panel.visible, "visible tras abrir")
	check_eq((panel.get_node("Panel/Title") as Label).text, "Gonzalo", "título")
	panel.free()
	return true


func test_esc_lo_cierra() -> bool:
	var panel := _make_panel()
	panel.open_for("Gonzalo")
	var escape := InputEventAction.new()
	escape.action = &"ui_cancel"
	escape.pressed = true
	panel._unhandled_input(escape)
	check(not panel.visible, "oculto tras Esc")
	panel.free()
	return true
```

- [ ] **Paso 2: Ejecutar y ver que falla**

Esperado: FALLA (la escena no existe).

- [ ] **Paso 3: Implementar el script**

`scripts/ui/chat_panel.gd`:

```gdscript
extends Control
## Panel lateral del chat. En el Plan 1 solo se abre con el nombre del amigo y se cierra.
## Los mensajes, las preguntas y las respuestas llegan en el Plan 3.

@onready var _title: Label = $Panel/Title


func _ready() -> void:
	hide()


func open_for(friend_name: String) -> void:
	_title.text = friend_name
	show()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var mouse := event as InputEventMouseButton
	var right_click := mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_RIGHT
	if event.is_action_pressed(&"ui_cancel") or right_click:
		hide()
		get_viewport().set_input_as_handled()
```

- [ ] **Paso 4: Crear la escena**

`scenes/ui/chat_panel.tscn`:

```ini
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/ui/chat_panel.gd" id="panel_script"]
[ext_resource type="Texture2D" path="res://art/sprites/screen_sprite.aseprite" id="panel_texture"]

[node name="ChatPanel" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
script = ExtResource("panel_script")

[node name="Panel" type="TextureRect" parent="."]
layout_mode = 0
offset_left = 11.0
offset_top = 11.0
offset_right = 460.0
offset_bottom = 707.0
texture = ExtResource("panel_texture")

[node name="Title" type="Label" parent="Panel"]
layout_mode = 0
offset_left = 24.0
offset_top = 20.0
offset_right = 424.0
offset_bottom = 44.0
theme_override_font_sizes/font_size = 16
```

`mouse_filter = 2` deja pasar los clics fuera del panel; el `TextureRect` los bloquea sobre el panel.

- [ ] **Paso 5: Ejecutar y ver que pasa**

Esperado: `28 pruebas OK, 0 fallidas`.

- [ ] **Paso 6: Commit**

```bash
git add scripts/ui/chat_panel.gd scenes/ui/chat_panel.tscn test/test_chat_panel.gd
git commit -m "Panel del chat provisional" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Tarea 11: Escena del escritorio y parallax

**Archivos:**

- Crear: `scripts/desk/parallax_rig.gd`, `scripts/desk/desk.gd`, `scenes/desk/desk.tscn`, `test/test_desk_scene.gd`

- [ ] **Paso 1: Escribir la prueba**

`test/test_desk_scene.gd`:

```gdscript
extends "res://test/test_case.gd"

const DESK := preload("res://scenes/desk/desk.tscn")
const ChatEntry := preload("res://scripts/ui/chat_entry.gd")

const POSITIONS := {
	"WallPlane/Background": Vector2(0, 0),
	"WallPlane/Window": Vector2(266, 114),
	"WallPlane/ExteriorClip/Exterior": Vector2(0, 0),
	"WallPlane/Enemy": Vector2(300, 172),
	"WallPlane/GlassPane": Vector2(273, 121),
	"WallPlane/Curtains": Vector2(219, 92),
	"WallPlane/DialConnection": Vector2(840, 89),
	"WallPlane/DialSanity": Vector2(840, 219),
	"WallPlane/DialTrust": Vector2(840, 348),
	"DeskPlane/DeskSurface": Vector2(0, 505),
	"DeskPlane/Notebook": Vector2(1017, 562),
	"DeskPlane/Microphone": Vector2(830, 571),
	"DeskPlane/Phone": Vector2(357, 618),
	"DeskPlane/Mixer": Vector2(130, 565),
	"DeskPlane/Cables": Vector2(241, 504),
	"DeskPlane/PC": Vector2(479, 433),
	"DeskPlane/Entries/EntryLeon": Vector2(518, 454),
	"DeskPlane/Entries/EntryGonzalo": Vector2(518, 494),
	"DeskPlane/Entries/EntryAgustin": Vector2(518, 534),
}


func _make_desk() -> Node2D:
	var desk := DESK.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(desk)
	return desk


func test_cada_objeto_en_su_posicion() -> bool:
	var desk := _make_desk()
	for path: String in POSITIONS:
		check_eq((desk.get_node(path) as Node2D).position, POSITIONS[path], path)
	desk.free()
	return true


func test_todo_el_arte_cargado() -> bool:
	var desk := _make_desk()
	for sprite in desk.find_children("*", "AnimatedSprite2D", true, false):
		check((sprite as AnimatedSprite2D).sprite_frames != null, "sin arte: %s" % desk.get_path_to(sprite))
	desk.free()
	return true


func test_clic_en_una_entrada_abre_el_chat() -> bool:
	var desk := _make_desk()
	var leon := desk.get_node("DeskPlane/Entries/EntryLeon")
	var gonzalo := desk.get_node("DeskPlane/Entries/EntryGonzalo")
	leon.pressed.emit()
	check((desk.get_node("UI/ChatPanel") as Control).visible, "panel visible")
	check_eq(leon.state, ChatEntry.State.SELECTED, "León seleccionado")
	check_eq(gonzalo.state, ChatEntry.State.IDLE, "Gonzalo sin seleccionar")
	desk.free()
	return true


func test_cerrar_el_chat_deselecciona() -> bool:
	var desk := _make_desk()
	var leon := desk.get_node("DeskPlane/Entries/EntryLeon")
	leon.pressed.emit()
	(desk.get_node("UI/ChatPanel") as Control).hide()
	check_eq(leon.state, ChatEntry.State.IDLE, "León vuelve a idle")
	desk.free()
	return true
```

- [ ] **Paso 2: Ejecutar y ver que falla**

Esperado: FALLA (la escena no existe).

- [ ] **Paso 3: Implementar el parallax**

`scripts/desk/parallax_rig.gd`:

```gdscript
extends Node
## Mueve planos de la escena según el mouse. Cada plano tiene su desplazamiento máximo en píxeles.
## Con el argumento de línea de comandos `-- --no-parallax` queda desactivado (para capturas).

const ParallaxMath := preload("res://scripts/desk/parallax_math.gd")

@export var enabled := true
@export var planes: Array[NodePath] = []
@export var max_offsets: Array[Vector2] = []

var _base_positions: Array[Vector2] = []


func _ready() -> void:
	if OS.get_cmdline_user_args().has("--no-parallax"):
		enabled = false
	for path in planes:
		_base_positions.append((get_node(path) as Node2D).position)


func _process(_delta: float) -> void:
	var viewport := get_viewport()
	var mouse := viewport.get_mouse_position()
	var size := viewport.get_visible_rect().size
	for i in planes.size():
		var offset := Vector2i.ZERO
		if enabled:
			offset = ParallaxMath.offset_for(mouse, size, max_offsets[i])
		(get_node(planes[i]) as Node2D).position = _base_positions[i] + Vector2(offset)
```

- [ ] **Paso 4: Implementar el script de la escena**

`scripts/desk/desk.gd`:

```gdscript
extends Node2D
## Escena principal del escritorio (Plan 1): las entradas del PC abren el panel del chat,
## y los clics en el cuaderno, el celular y el mixer solo se registran (sus paneles llegan en los planes 4 y 6).

const ChatEntry := preload("res://scripts/ui/chat_entry.gd")

@onready var _entries: Array[Node] = $DeskPlane/Entries.get_children()
@onready var _chat_panel: Control = $UI/ChatPanel


func _ready() -> void:
	for entry in _entries:
		entry.pressed.connect(_on_entry_pressed.bind(entry))
	_chat_panel.visibility_changed.connect(_on_chat_visibility_changed)
	for clickable_name in ["Notebook", "Phone", "Mixer"]:
		var clickable := get_node("DeskPlane/" + clickable_name)
		clickable.clicked.connect(func() -> void: print("Clic en ", clickable_name))


func _on_entry_pressed(entry: Node) -> void:
	for other in _entries:
		other.set_state(ChatEntry.State.SELECTED if other == entry else ChatEntry.State.IDLE)
	_chat_panel.open_for(entry.display_name)


func _on_chat_visibility_changed() -> void:
	if not _chat_panel.visible:
		for entry in _entries:
			entry.set_state(ChatEntry.State.IDLE)
```

- [ ] **Paso 5: Crear la escena**

`scenes/desk/desk.tscn`. El orden de los nodos repite el orden de capas del maestro, para que todo se dibuje igual.

```ini
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/desk/desk.gd" id="desk_script"]
[ext_resource type="Script" path="res://scripts/desk/parallax_rig.gd" id="parallax_script"]
[ext_resource type="Script" path="res://scripts/desk/clickable_sprite.gd" id="clickable_script"]
[ext_resource type="SpriteFrames" path="res://art/sprites/background_sprite.aseprite" id="background"]
[ext_resource type="SpriteFrames" path="res://art/sprites/window_sprite.aseprite" id="window"]
[ext_resource type="SpriteFrames" path="res://art/sprites/exterior_sprite.aseprite" id="exterior"]
[ext_resource type="SpriteFrames" path="res://art/sprites/enemy_sprite.aseprite" id="enemy"]
[ext_resource type="SpriteFrames" path="res://art/sprites/glasspane_sprite.aseprite" id="glasspane"]
[ext_resource type="SpriteFrames" path="res://art/sprites/curtains_sprite.aseprite" id="curtains"]
[ext_resource type="PackedScene" path="res://scenes/desk/dial_gauge.tscn" id="dial"]
[ext_resource type="SpriteFrames" path="res://art/sprites/desk_sprite.aseprite" id="desk_surface"]
[ext_resource type="SpriteFrames" path="res://art/sprites/notebook_sprite.aseprite" id="notebook"]
[ext_resource type="SpriteFrames" path="res://art/sprites/microphone_sprite.aseprite" id="microphone"]
[ext_resource type="SpriteFrames" path="res://art/sprites/phone_sprite.aseprite" id="phone"]
[ext_resource type="SpriteFrames" path="res://art/sprites/mixer_sprite.aseprite" id="mixer"]
[ext_resource type="SpriteFrames" path="res://art/sprites/cables_sprite.aseprite" id="cables"]
[ext_resource type="SpriteFrames" path="res://art/sprites/pc_sprite.aseprite" id="pc"]
[ext_resource type="PackedScene" path="res://scenes/ui/chat_entry.tscn" id="entry"]
[ext_resource type="PackedScene" path="res://scenes/ui/chat_panel.tscn" id="chat_panel"]

[node name="Desk" type="Node2D"]
script = ExtResource("desk_script")

[node name="WallPlane" type="Node2D" parent="."]

[node name="Background" type="AnimatedSprite2D" parent="WallPlane"]
sprite_frames = ExtResource("background")
centered = false

[node name="Window" type="AnimatedSprite2D" parent="WallPlane"]
position = Vector2(266, 114)
sprite_frames = ExtResource("window")
centered = false

[node name="ExteriorClip" type="Control" parent="WallPlane"]
clip_contents = true
layout_mode = 3
offset_left = 273.0
offset_top = 121.0
offset_right = 524.0
offset_bottom = 418.0
mouse_filter = 2

[node name="Exterior" type="AnimatedSprite2D" parent="WallPlane/ExteriorClip"]
sprite_frames = ExtResource("exterior")
centered = false

[node name="Enemy" type="AnimatedSprite2D" parent="WallPlane"]
position = Vector2(300, 172)
sprite_frames = ExtResource("enemy")
centered = false

[node name="GlassPane" type="AnimatedSprite2D" parent="WallPlane"]
position = Vector2(273, 121)
sprite_frames = ExtResource("glasspane")
centered = false

[node name="Curtains" type="AnimatedSprite2D" parent="WallPlane"]
position = Vector2(219, 92)
sprite_frames = ExtResource("curtains")
centered = false

[node name="DialConnection" parent="WallPlane" instance=ExtResource("dial")]
position = Vector2(840, 89)
needle_color = &"green"

[node name="DialSanity" parent="WallPlane" instance=ExtResource("dial")]
position = Vector2(840, 219)
needle_color = &"red"

[node name="DialTrust" parent="WallPlane" instance=ExtResource("dial")]
position = Vector2(840, 348)
needle_color = &"yellow"

[node name="DeskPlane" type="Node2D" parent="."]

[node name="DeskSurface" type="AnimatedSprite2D" parent="DeskPlane"]
position = Vector2(0, 505)
sprite_frames = ExtResource("desk_surface")
centered = false

[node name="Notebook" type="AnimatedSprite2D" parent="DeskPlane"]
position = Vector2(1017, 562)
sprite_frames = ExtResource("notebook")
centered = false
script = ExtResource("clickable_script")

[node name="Microphone" type="AnimatedSprite2D" parent="DeskPlane"]
position = Vector2(830, 571)
sprite_frames = ExtResource("microphone")
centered = false

[node name="Phone" type="AnimatedSprite2D" parent="DeskPlane"]
position = Vector2(357, 618)
sprite_frames = ExtResource("phone")
centered = false
script = ExtResource("clickable_script")

[node name="Mixer" type="AnimatedSprite2D" parent="DeskPlane"]
position = Vector2(130, 565)
sprite_frames = ExtResource("mixer")
centered = false
script = ExtResource("clickable_script")

[node name="Cables" type="AnimatedSprite2D" parent="DeskPlane"]
position = Vector2(241, 504)
sprite_frames = ExtResource("cables")
centered = false

[node name="PC" type="AnimatedSprite2D" parent="DeskPlane"]
position = Vector2(479, 433)
sprite_frames = ExtResource("pc")
centered = false

[node name="Entries" type="Node2D" parent="DeskPlane"]

[node name="EntryLeon" parent="DeskPlane/Entries" instance=ExtResource("entry")]
position = Vector2(518, 454)
display_name = "León"

[node name="EntryGonzalo" parent="DeskPlane/Entries" instance=ExtResource("entry")]
position = Vector2(518, 494)
display_name = "Gonzalo"

[node name="EntryAgustin" parent="DeskPlane/Entries" instance=ExtResource("entry")]
position = Vector2(518, 534)
display_name = "Agustín"

[node name="ParallaxRig" type="Node" parent="."]
script = ExtResource("parallax_script")
planes = Array[NodePath]([NodePath("../WallPlane"), NodePath("../WallPlane/ExteriorClip/Exterior")])
max_offsets = Array[Vector2]([Vector2(3, 2), Vector2(2, 1)])

[node name="UI" type="CanvasLayer" parent="."]

[node name="ChatPanel" parent="UI" instance=ExtResource("chat_panel")]
```

**Sobre el parallax:**

- La pared se mueve ±3 px en x y ±2 px en y (`background_sprite` mide 1280×720, sin margen). El borde que queda a la vista se tapa con el color de fondo de la Tarea 2.
- El exterior va dentro de `ExteriorClip`, un `Control` del tamaño exacto del vidrio que recorta lo que se sale. Además de moverse con la pared, se mueve ±2 px en x y ±1 px en y.
- Como `exterior_sprite` mide exactamente lo mismo que el vidrio, al moverse deja ver en un borde de 1 a 2 px el exterior que `window_sprite` tiene pintado debajo. Si se nota, se resuelve agrandando `exterior_sprite` 8 px por lado y centrándolo con `position = Vector2(-8, -8)`; entonces el máximo puede subir a `Vector2(6, 4)`.

- [ ] **Paso 6: Ejecutar y ver que pasa**

Esperado: `32 pruebas OK, 0 fallidas`.

- [ ] **Paso 7: Commit**

```bash
git add scripts/desk/parallax_rig.gd scripts/desk/desk.gd scenes/desk/desk.tscn test/test_desk_scene.gd
git commit -m "Escena del escritorio con el arte y parallax de la pared" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Tarea 12: Comparación visual con la maqueta

**Archivos:**

- Crear: `tools/compare_png.py`, `tools/.gdignore` (vacío)

- [ ] **Paso 1: Escribir la herramienta**

`tools/compare_png.py`:

```python
"""Compara dos PNG del mismo tamaño y guarda un mapa de diferencias.

Uso: python3 -I tools/compare_png.py captura.png maqueta.png diferencias.png
Imprime el porcentaje de píxeles iguales (tolerancia de 8 por canal).
"""
import struct
import sys
import zlib


def read_png(path):
    data = open(path, "rb").read()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", path
    pos, idat = 8, b""
    while pos < len(data):
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        kind, body = data[pos + 4:pos + 8], data[pos + 8:pos + 8 + length]
        pos += 12 + length
        if kind == b"IHDR":
            width, height, depth, color = struct.unpack(">IIBB", body[:10])
            assert depth == 8 and color in (2, 6), "solo PNG RGB/RGBA de 8 bits"
            bpp = 4 if color == 6 else 3
        elif kind == b"IDAT":
            idat += body
    raw, stride = zlib.decompress(idat), width * bpp
    rows, prev, i = [], bytearray(stride), 0
    for _ in range(height):
        filt, line = raw[i], bytearray(raw[i + 1:i + 1 + stride])
        i += 1 + stride
        for x in range(stride):
            a = line[x - bpp] if x >= bpp else 0
            b, c = prev[x], prev[x - bpp] if x >= bpp else 0
            if filt == 1:
                line[x] = (line[x] + a) & 255
            elif filt == 2:
                line[x] = (line[x] + b) & 255
            elif filt == 3:
                line[x] = (line[x] + (a + b) // 2) & 255
            elif filt == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[x] = (line[x] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        rows.append([tuple(line[x * bpp:x * bpp + 3]) for x in range(width)])
        prev = line
    return width, height, rows


def write_png(path, width, height, rows):
    raw = b"".join(b"\x00" + bytes(v for px in row for v in px) for row in rows)
    def chunk(kind, body):
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body) & 0xFFFFFFFF)
    header = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    open(path, "wb").write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header)
                           + chunk(b"IDAT", zlib.compress(raw, 6)) + chunk(b"IEND", b""))


def main():
    capture, reference, out = sys.argv[1:4]
    w1, h1, a = read_png(capture)
    w2, h2, b = read_png(reference)
    assert (w1, h1) == (w2, h2), f"tamaños distintos: {w1}x{h1} vs {w2}x{h2}"
    same, diff_rows = 0, []
    for y in range(h1):
        row = []
        for x in range(w1):
            if max(abs(p - q) for p, q in zip(a[y][x], b[y][x])) <= 8:
                same += 1
                row.append(tuple(v // 3 for v in b[y][x]))
            else:
                row.append((255, 40, 40))
        diff_rows.append(row)
    write_png(out, w1, h1, diff_rows)
    print(f"Iguales: {100 * same / (w1 * h1):.1f} %  (mapa: {out})")


if __name__ == "__main__":
    main()
```

- [ ] **Paso 2: Capturar la escena sin parallax**

Se abre una ventana de Godot por un segundo.

```bash
mkdir -p /mnt/c/dev/capturas
~/tools/godot-wsl.sh --path "$PWD" --write-movie /mnt/c/dev/capturas/escena.png --fixed-fps 10 --quit-after 3 -- --no-parallax
ls /mnt/c/dev/capturas/
```

Esperado: archivos `escena00000000.png` a `escena00000002.png`, de 1280×720.

- [ ] **Paso 3: Comparar con la maqueta**

```bash
python3 -I tools/compare_png.py /mnt/c/dev/capturas/escena00000002.png art/_layout/scene_layout.png /mnt/c/dev/capturas/diferencias.png
```

Esperado: `Iguales: ≥ 90 %`.

Las diferencias del mapa (en rojo) deben estar solo en:

- las agujas, que giran según su valor;
- las entradas, que ahora tienen texto;
- las zonas del maestro con cambios entre frames.

Revisar el mapa con la herramienta de lectura de imágenes. Si hay rojo en otra parte, algún objeto está desplazado: corregir su posición en `desk.tscn`.

- [ ] **Paso 4: Commit**

```bash
git add tools/
git commit -m "Herramienta para comparar capturas con la maqueta" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Tarea 13: Prueba de escalado a 1080p (decisión pendiente desde la sesión 1)

**Archivos:** ninguno. Es una evaluación, y su resultado se anota en `resumen.md`.

- [ ] **Paso 1: Capturar a 1920×1080**

```bash
~/tools/godot-wsl.sh --path "$PWD" --resolution 1920x1080 --write-movie /mnt/c/dev/capturas/escala.png --fixed-fps 10 --quit-after 3 -- --no-parallax
```

- [ ] **Paso 2: Revisar**

Ampliar ×4 un recorte del teclado del PC y otro de un dial, y revisar si hay píxeles de 1 y 2 px alternados.

- [ ] **Paso 3: Probarlo Benja**

Abre el juego en su monitor a pantalla completa (**F5**, y luego **F11** si Godot lo permite, o maximizando la ventana) y mueve el mouse para ver el parallax.

- [ ] **Paso 4: Decidir y anotar en `resumen.md`**

Se mantiene Nearest, o se agrega un shader de escalado suave en un plan futuro. Este plan no agrega el shader, para no crecer.

---

### Tarea 14: Cierre del plan

- [ ] **Paso 1: Ejecutar todas las pruebas**

Esperado: `32 pruebas OK, 0 fallidas`.

- [ ] **Paso 2: Revisión visual de Benja en Godot**

1. Abrir Godot y el proyecto.
2. En **FileSystem**, abrir `scenes/desk/desk.tscn` con doble clic.
3. Presionar **F5** (Run Project).
4. Probar:
   - pasar el mouse sobre el cuaderno, el celular y el mixer: se resaltan con un contorno claro;
   - clic en una entrada del PC: se ilumina y se abre el panel;
   - `Esc` o clic derecho: se cierra el panel;
   - mover el mouse: la pared y la ventana se mueven levemente; el escritorio no.

- [ ] **Paso 3: Actualizar la documentación**

- En `docs/04_instrucciones_godot.md`, explicar cómo mover un objeto: seleccionarlo en el panel **Scene** → Inspector → **Transform > Position**.
- Agregar la entrada de la sesión en `resumen.md`.

- [ ] **Paso 4: Commit final**

```bash
git add docs/ resumen.md
git commit -m "Plan 1 terminado: escena del escritorio" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

## Autorrevisión del plan

- **Cobertura** (v1 #1 de `docs/05` y diseño §6–7 y §16):

  | Requisito | Tarea |
  | --- | --- |
  | Escena con el arte | 3, 11 y 12 |
  | Objetos clickeables | 7 |
  | Diales | 4 y 8 |
  | Entradas del PC | 9 |
  | Panel del chat | 10 |
  | Parallax | 5 y 11 |
  | Pantalla y escalado | 2 y 13 |

  El parallax del exterior de la ventana se implementa en la Tarea 11.
- **Fuera de este plan, a propósito:**
  - el contenido del chat (Plan 3);
  - el cuaderno (Plan 4);
  - los valores reales de los medidores (Plan 5);
  - las luces y los screamers (Plan 7).
- **Nombres consistentes:**
  - `value_to_degrees`, `offset_for`, `bitmap_from_texture` e `is_opaque` se usan igual en sus pruebas y en los scripts que los llaman;
  - `State` (`IDLE`, `WARNING`, `DISCONNECTED`, `SELECTED`), `pressed`, `clicked`, `display_name`, `set_state`, `set_seconds_left` y `open_for` coinciden entre tareas.
- **Conteo de pruebas acumulado:** 1, 4, 7, 10, 14, 17, 20, 23, 26, 28 y 32.
