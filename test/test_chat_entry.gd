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


func test_vida() -> bool:
	var entry := _make_entry()
	entry.set_health(2, 3)
	var pips := entry.get_node("Health").get_children()
	check_eq(pips.size(), 3, "una marca por punto de vida")
	var filled := pips.map(func(pip: Panel) -> bool: return (pip.get_theme_stylebox(&"panel") as StyleBoxFlat).draw_center)
	check_eq(filled, [true, true, false], "2 llenas y 1 vacía: no depende del color")
	for pip: Control in pips:
		check_eq(pip.mouse_filter, Control.MOUSE_FILTER_IGNORE, "no le quita el clic a la entrada")
	entry.set_health(0, 3)
	check_eq(entry.get_node("Health").get_child_count(), 3, "se rehacen, no se acumulan")
	entry.free()
	return true


func test_aturdido() -> bool:
	var entry := _make_entry()
	var background := entry.get_node("Background") as AnimatedSprite2D
	entry.set_state(ChatEntry.State.STUNNED)
	check_eq(background.animation, &"idle", "aturdido usa idle")
	check_eq(background.modulate, ChatEntry.STATE_MODULATE[ChatEntry.State.STUNNED], "más oscuro")
	entry.show_stun(12)
	var timer := entry.get_node("TimerLabel") as Label
	check(timer.visible, "visible")
	check_eq(timer.text, String(TranslationServer.translate("ENTRY_STUNNED")).format({"seconds": 12}), "texto")
	check(timer.text.contains("12"), "con los segundos")
	entry.free()
	return true


## Cuántas barras llenas muestra el cuadro de art/ui/signal_bars.png que se ve.
func _filled_bars(entry: Node2D) -> int:
	var picture := entry.get_node("Signal").get_child(0) as TextureRect
	return roundi((picture.texture as AtlasTexture).region.position.x / entry.SIGNAL_FRAME.x)


func test_barras_de_senal() -> bool:
	var entry := _make_entry()
	entry.set_signal(100.0)
	check_eq(_filled_bars(entry), 5, "señal llena: 5 barras")
	entry.set_signal(45.0)
	check_eq(_filled_bars(entry), 3, "una barra por cada 20: 3 llenas y 2 vacías")
	entry.set_signal(0.0)
	check_eq(_filled_bars(entry), 0, "sin señal, todas vacías")
	check_eq(entry.get_node("Signal").get_child_count(), 1, "un solo dibujo, que no se acumula")
	entry.free()
	return true


func test_titila_si_viene_una_interferencia() -> bool:
	var entry := _make_entry()
	entry.set_interference_warning(true)
	entry._process(0.05)
	check(entry.modulate.a < 1.0, "se apaga")
	entry._process(0.12)
	check_eq(entry.modulate.a, 1.0, "y se vuelve a encender")
	entry._process(0.12)
	check(entry.modulate.a < 1.0, "titila")
	entry.set_interference_warning(false)
	check_eq(entry.modulate.a, 1.0, "al pasar, queda encendida")
	entry.free()
	return true


func test_video_y_sin_senal() -> bool:
	var entry := _make_entry()
	var timer := entry.get_node("TimerLabel") as Label
	entry.show_video(12)
	check(timer.visible, "visible")
	check_eq(timer.text, String(TranslationServer.translate("ENTRY_VIDEO")).format({"seconds": 12}), "el video")
	check(timer.text.contains("12"), "con los segundos")
	entry.show_offline()
	check_eq(timer.text, String(TranslationServer.translate("ENTRY_OFFLINE")), "sin señal")
	check(timer.text != "ENTRY_OFFLINE", "el texto está en ui.csv")
	entry.free()
	return true


## "Reducir destellos" (diseño §19): la alerta queda fija en lugar de parpadear, y el aviso de una interferencia
## atenúa la entrada en lugar de hacerla titilar.
func test_reducir_destellos() -> bool:
	var entry := _make_entry()
	var background := entry.get_node("Background") as AnimatedSprite2D
	entry.reduce_flashes = true
	entry.set_state(ChatEntry.State.WARNING)
	check_eq(background.animation, &"warning", "alerta")
	check(not background.is_playing(), "sin parpadear")
	check_eq(background.frame, 0, "en el cuadro de la alerta")
	entry.set_interference_warning(true)
	for _i in 4:
		entry._process(0.06)
		check(is_equal_approx(entry.modulate.a, ChatEntry.DIM_ALPHA), "atenuada, sin titilar: %s" % entry.modulate.a)
	entry.reduce_flashes = false
	check(background.is_playing(), "al apagar la opción, vuelve a parpadear")
	entry.free()
	return true


## La alarma (pedido de Benja, 12 de noviembre): una entrada en alerta pita una vez por segundo, en el segundo justo de
## un reloj común a las 3, para que suenen juntas y hagan su acorde.
func test_la_alarma_pita_cada_segundo_en_alerta() -> bool:
	var entry := _make_entry()
	entry.alarm = load("res://audio/sfx/alarm_leon.wav")
	check(not entry.ring(0.2), "la primera vez solo toma el reloj")
	check(not entry.ring(1.3), "sin alerta no pita")
	entry.set_state(ChatEntry.State.WARNING)
	check(not entry.ring(1.8), "dentro del mismo segundo, nada")
	check(entry.ring(2.05), "al empezar el segundo, pita")
	check_eq((entry.get_node("Background") as AnimatedSprite2D).frame, 0, "y la entrada se enciende en rojo con el pitido")
	check(not entry.ring(2.5), "una vez por segundo")
	check(entry.ring(3.0), "el siguiente")
	entry.muted = true
	check(not entry.ring(4.0), "callada no pita")
	entry.muted = false
	entry.set_state(ChatEntry.State.SELECTED)
	check(not entry.ring(5.0), "con su chat abierto no pita")
	entry.free()
	return true


func test_la_alarma_pita_tambien_sin_destellos() -> bool:
	var entry := _make_entry()
	entry.alarm = load("res://audio/sfx/alarm_leon.wav")
	entry.reduce_flashes = true
	entry.set_state(ChatEntry.State.WARNING)
	entry.ring(0.5)
	check(entry.ring(1.0), "con la alerta fija, el mismo ritmo")
	entry.free()
	return true


func test_cada_amigo_tiene_su_nota() -> bool:
	var streams := []
	for friend_id: String in ["leon", "gonzalo", "agustin"]:
		var friend: FriendData = load("res://data/friends/%s.tres" % friend_id)
		check(friend.alarm != null, "%s tiene su alarma" % friend_id)
		check(not streams.has(friend.alarm), "%s no repite la de otro" % friend_id)
		streams.append(friend.alarm)
	return true


## Bloqueada (en la noche 0, hasta que León la use), no recibe clics (Plan 9.5).
func test_bloqueada_no_recibe_clics() -> bool:
	var entry := _make_entry()
	check(entry.accepts_click_at(Vector2(40, 12)), "habilitada, sí")
	check(not entry.accepts_click_at(Vector2(300, 12)), "fuera de la entrada, no")
	entry.enabled = false
	check(not entry.accepts_click_at(Vector2(40, 12)), "bloqueada, no")
	entry.free()
	return true


func test_puede_parpadear() -> bool:
	var entry := _make_entry()
	entry.highlighted = true
	var highlight := entry.get_node("Highlight")
	check(highlight.active, "el borde se enciende")
	check_eq(highlight.border_rect().size, ChatEntry.SIZE + Vector2.ONE * 2 * (highlight.MARGIN + highlight.WIDTH),
			"alrededor de la entrada")
	entry.highlighted = false
	check(not highlight.active, "y se apaga")
	entry.free()
	return true


## Mientras dura la llamada grupal, las entradas muestran su ícono (Plan 9.7).
func test_en_llamada_muestra_el_icono() -> bool:
	var entry := _make_entry()
	var icon := entry.get_node("CallIcon") as Sprite2D
	check(not icon.visible, "sin llamada, no")
	entry.set_call(true)
	check(icon.visible, "en llamada, sí")
	check(not (entry.get_node("TimerLabel") as Label).visible, "en lugar del temporizador")
	check(icon.position.x + icon.texture.get_width() <= ChatEntry.SIZE.x - 6, "dentro de la entrada")
	entry.set_call(false)
	check(not icon.visible, "se va")
	entry.free()
	return true
