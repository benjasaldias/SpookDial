extends Control
## La mancha de tinta del screamer del cuaderno (diseño §11): tapa la página unos segundos y se desvanece al
## final. Provisional hasta el arte de Benja (docs/06 §3): se dibuja con círculos, siempre con la misma forma.

## Segundos que tarda en desvanecerse, al final.
const FADE_SECONDS := 0.5
const INK_COLOR := Color(0.05, 0.04, 0.08)
const SHAPE_SEED := 23

## Segundos que le quedan.
var time_left := 0.0


func _ready() -> void:
	hide()


## Aparece y tapa la página `seconds` segundos.
func splash(seconds: float) -> void:
	time_left = seconds
	modulate.a = 1.0
	show()


func _process(delta: float) -> void:
	if time_left <= 0.0:
		return
	time_left = maxf(time_left - delta, 0.0)
	modulate.a = clampf(time_left / FADE_SECONDS, 0.0, 1.0)
	if time_left <= 0.0:
		hide()


## Tres manchas grandes, una sobre otra, chorreones que caen de la última y salpicaduras alrededor: tapan casi
## toda la página sin salirse del rectángulo.
func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SHAPE_SEED
	var radius := size.x * 0.24
	var middle := size / 2.0
	var centers: Array[Vector2] = []
	for offset: float in [-0.22, 0.0, 0.22]:
		centers.append(middle + Vector2(0.0, size.y * offset))
	for center: Vector2 in centers:
		draw_circle(center, radius, INK_COLOR)
		for _i in 8:
			var angle := rng.randf_range(0.0, TAU)
			var distance := rng.randf_range(0.5, 1.0) * radius
			draw_circle(center + Vector2.from_angle(angle) * distance, rng.randf_range(0.35, 0.6) * radius, INK_COLOR)
	var bottom := centers[-1]
	for _i in 5:
		var x := bottom.x + rng.randf_range(-0.8, 0.8) * radius
		var length := rng.randf_range(0.6, 1.4) * radius
		draw_rect(Rect2(x - 4.0, bottom.y, 8.0, length), INK_COLOR)
		draw_circle(Vector2(x, bottom.y + length), 7.0, INK_COLOR)
	for _i in 24:
		var angle := rng.randf_range(0.0, TAU)
		var reach := Vector2(rng.randf_range(1.3, 1.6), rng.randf_range(1.0, 2.6)) * radius
		draw_circle(middle + Vector2(cos(angle), sin(angle)) * reach, rng.randf_range(3.0, 9.0), INK_COLOR)
