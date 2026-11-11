extends Node
## La letra en pixel art, nítida en cualquier pantalla (pedido de Benja, 11 de noviembre). Departure Mono está dibujada
## en una grilla de 11 px, así que solo se ve nítida si su tamaño real (el de la letra por la escala de la ventana) es
## múltiplo de 11. A 1080p la escala es 1,5: la letra de 11 quedaría en 16,5 px reales, con trazos disparejos, y con 15
## queda en 22, el doble exacto, y además un poco más grande. A 1280×720, 1440p y 4K, la de 11 ya es nítida.
## Como autoload (PixelTextSizer), cada vez que cambia la ventana aplica el tamaño nítido a los temas y a cada Control
## con un tamaño de letra propio. El texto que se dibuja por código usa size().

## Cambiaron los tamaños de letra.
signal changed

## La grilla de la fuente, en píxeles.
const GRID := 11
## El tamaño del juego, que se escala a la ventana.
const BASE_SIZE := Vector2(1280, 720)
## Cuánto puede crecer la letra común cuando eso la deja nítida: un poco más grande se lee mejor (pedido de Benja).
const BODY_ZOOM := 4.0 / 3.0
## Entre qué fracciones de su tamaño base se busca un tamaño nítido: más allá, el texto ya no cabe donde va.
const SIZE_RANGE := Vector2(0.7, 1.46)
## Los tamaños de letra que puede tener un Control propio (los de Label, Button y RichTextLabel).
const FONT_SIZE_NAMES: Array[StringName] = [&"font_size", &"normal_font_size", &"bold_font_size",
		&"italics_font_size", &"bold_italics_font_size", &"mono_font_size"]
## Los temas del juego.
const THEMES: Array[Theme] = [
	preload("res://scenes/ui/chat_theme.tres"),
	preload("res://scenes/ui/notebook_theme.tres"),
	preload("res://scenes/ui/menu_theme.tres"),
]
## Dónde guarda cada Control su tamaño base.
const META_PREFIX := "pixel_text_base_"

## La escala aplicada.
var scale := 1.0

## Los temas que sigue, con sus tamaños base: tema → {"": por defecto, "tipo/nombre": tamaño}.
var _bases := {}


## El tamaño nítido para la letra de `base` a la escala `scale`. Primero elige cuántos píxeles reales debe medir: el
## múltiplo de 11 más cercano a base × escala (× 4/3 para la letra común, que puede crecer un poco). Después busca el
## tamaño que da justo esos píxeles reales, sin pasar de base × 1,46 ni bajar de base × 0,7, para que todo siga cabiendo;
## si ese no existe, prueba con los múltiplos vecinos. Si ninguno funciona, base.
static func crisp_size(base: int, scale: float) -> int:
	scale = maxf(scale, 1.0)
	var zoom := BODY_ZOOM if base <= GRID else 1.0
	var ideal := base * scale * zoom / GRID
	var candidates := [roundi(ideal), floori(ideal), ceili(ideal), floori(ideal) - 1]
	for grid_steps: int in candidates:
		if grid_steps < 1:
			continue
		var real := grid_steps * GRID
		for size in [ceili(real / scale - 0.001), floori(real / scale)]:
			if size < base * SIZE_RANGE.x or size > base * SIZE_RANGE.y:
				continue
			if int(size * scale + 0.001) == real:
				return size
	return base


## La escala del juego en una ventana de `window_size`: el lado que más limita.
static func window_scale_for(window_size: Vector2) -> float:
	return minf(window_size.x / BASE_SIZE.x, window_size.y / BASE_SIZE.y)


## El tamaño nítido de `base` en la ventana de ahora: para el texto que se dibuja por código.
static func size(base: int) -> int:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return base
	return crisp_size(base, window_scale_for(Vector2(tree.root.size)))


func _ready() -> void:
	for theme: Theme in THEMES:
		track_theme(theme)
	get_tree().node_added.connect(_on_node_added)
	get_tree().root.size_changed.connect(_refresh)
	_refresh.call_deferred()


## Sigue el tema `theme`: guarda sus tamaños base.
func track_theme(theme: Theme) -> void:
	var sizes := {"": theme.default_font_size}
	for type_name: StringName in theme.get_font_size_type_list():
		for size_name: StringName in theme.get_font_size_list(type_name):
			sizes["%s/%s" % [type_name, size_name]] = theme.get_font_size(size_name, type_name)
	_bases[theme] = sizes


## Aplica la escala `new_scale` a los temas y, si está en el árbol, a cada Control con tamaño propio.
func apply(new_scale: float) -> void:
	scale = new_scale
	for theme: Theme in _bases:
		var sizes: Dictionary = _bases[theme]
		for key: String in sizes:
			var base: int = sizes[key]
			var crisp := crisp_size(base, scale) if base > 0 else base
			if key.is_empty():
				theme.default_font_size = crisp
			else:
				var parts := key.split("/")
				theme.set_font_size(StringName(parts[1]), StringName(parts[0]), crisp)
	if is_inside_tree():
		_apply_branch(get_tree().root)
	changed.emit()


## Aplica la escala a los tamaños de letra propios de `control`. La primera vez guarda su tamaño base.
func apply_to_control(control: Control) -> void:
	for size_name: StringName in FONT_SIZE_NAMES:
		if not control.has_theme_font_size_override(size_name):
			continue
		var meta := META_PREFIX + size_name
		if not control.has_meta(meta):
			control.set_meta(meta, control.get_theme_font_size(size_name))
		control.add_theme_font_size_override(size_name, crisp_size(control.get_meta(meta), scale))


func _refresh() -> void:
	var new_scale := window_scale_for(Vector2(get_tree().root.size))
	if not is_equal_approx(new_scale, scale) or scale == 1.0:
		apply(new_scale)


func _apply_branch(node: Node) -> void:
	if node is Control:
		apply_to_control(node)
	for child: Node in node.get_children():
		_apply_branch(child)


func _on_node_added(node: Node) -> void:
	if node is Control:
		apply_to_control(node)
