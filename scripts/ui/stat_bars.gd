extends Control
## Las barras de Connection, Sanity y Trust (decisión de Benja, 7 de noviembre): dicen de un vistazo cómo va la
## noche, porque los diales de la pared no se entendían. Van arriba, en el hueco entre el chat y el cuaderno, así
## que ninguno de los dos las tapa, y cada una conserva el color de su dial. Titilan si bajan de golpe y prenden
## una luz con poco valor. La placa es pixel art de Claude (art/ui/hud_bars.png), y las barras son de LED, en
## segmentos: los apagados se ven tenues.

## Las barras, de arriba hacia abajo.
enum Stat { CONNECTION, SANITY, TRUST }

const FONT := preload("res://fonts/departure_mono/DepartureMono-Regular.otf")
const PLATE := preload("res://art/ui/hud_bars.png")

## Sus nombres (ui.csv), en el orden de Stat.
const LABEL_KEYS: Array[String] = ["HUD_CONNECTION", "HUD_SANITY", "HUD_TRUST"]
## Los colores de las agujas de los diales, en el orden de Stat.
const COLORS: Array[Color] = [Color(0.35, 0.85, 0.45), Color(1.0, 0.3, 0.37), Color(0.95, 0.82, 0.3)]
const FONT_SIZE := 11
const METER_MAX := 100.0
## Una barra titila si baja al menos tantos puntos de una vez.
const FLASH_DROP := 2.0
const FLASH_SECONDS := 0.6
## Bajo este valor se prende su luz.
const ALERT_BELOW := 25.0
## Segundos que la luz de alerta está encendida, y después apagada.
const BLINK_SECONDS := 0.25
const TEXT_COLOR := Color(0.86, 0.88, 0.94)
const LIGHT_OFF := Color(0.2, 0.22, 0.28)
## Dónde va cada parte, en píxeles de las barras.
const ROW_TOP := 5.0
const ROW_HEIGHT := 16.0
const LABEL_LEFT := 7.0
const BAR_LEFT := 93.0
const BAR_SIZE := Vector2(184, 10)
const LIGHT_LEFT := 283.0
## Cada segmento de LED mide 4 px, con 1 px entre uno y otro: 37 segmentos llenan los 184 px de la barra.
const SEGMENT := 4.0
const SEGMENT_GAP := 1.0

## La opción "Reducir destellos" (diseño §19): la luz de alerta queda fija y la barra titila una sola vez.
var reduce_flashes := false

var _values: Array[float] = [METER_MAX, METER_MAX, METER_MAX]
var _flash_left: Array[float] = [0.0, 0.0, 0.0]
var _started := false
var _blink := 0.0


## Muestra los valores de 0 a 100. Una barra que bajó de golpe titila; el primer valor no cuenta como una baja.
func set_values(connection: float, sanity: float, trust: float) -> void:
	var next: Array[float] = [connection, sanity, trust]
	for stat in next.size():
		if _started and _values[stat] - next[stat] >= FLASH_DROP:
			_flash_left[stat] = FLASH_SECONDS
		_values[stat] = next[stat]
	_started = true
	queue_redraw()


## Cuánto se llena la barra, de 0 a 1.
func fill(stat: Stat) -> float:
	return clampf(_values[stat] / METER_MAX, 0.0, 1.0)


func is_flashing(stat: Stat) -> bool:
	return _flash_left[stat] > 0.0


func is_alert(stat: Stat) -> bool:
	return _values[stat] < ALERT_BELOW


## Cuánto brilla la luz de alerta: parpadea, o queda fija si se reducen los destellos.
func alert_light() -> float:
	return 1.0 if reduce_flashes or fmod(_blink, BLINK_SECONDS * 2.0) < BLINK_SECONDS else 0.0


func _process(delta: float) -> void:
	_blink += delta
	for stat in _flash_left.size():
		_flash_left[stat] = maxf(_flash_left[stat] - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	draw_texture(PLATE, Vector2.ZERO)
	for stat: int in Stat.values():
		_draw_row(stat)


## Una fila: el nombre, la barra de su color y la luz de alerta. Al bajar de golpe, la barra se aclara.
func _draw_row(stat: Stat) -> void:
	var top := ROW_TOP + stat * ROW_HEIGHT
	draw_string(FONT, Vector2(LABEL_LEFT, top + 10.0), tr(LABEL_KEYS[stat]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1,
			FONT_SIZE, TEXT_COLOR)
	var color := COLORS[stat]
	if is_flashing(stat):
		var lit := reduce_flashes or fmod(_flash_left[stat], BLINK_SECONDS) < BLINK_SECONDS / 2.0
		color = color.lightened(0.55) if lit else color
	var segments := roundi((BAR_SIZE.x + SEGMENT_GAP) / (SEGMENT + SEGMENT_GAP))
	var lit_segments := roundi(segments * fill(stat))
	for index in segments:
		var segment := Rect2(BAR_LEFT + index * (SEGMENT + SEGMENT_GAP), top + 2.0, SEGMENT, BAR_SIZE.y - 2.0)
		draw_rect(segment, color if index < lit_segments else color.darkened(0.82))
	var light := COLORS[stat].lerp(LIGHT_OFF, 1.0 - alert_light()) if is_alert(stat) else LIGHT_OFF
	draw_rect(Rect2(Vector2(LIGHT_LEFT, top + 2.0), Vector2(8, 8)), light)
