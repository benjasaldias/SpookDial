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
	for _i in 4:
		entry.advance_alarm(0.15)
		check_eq(background.frame, 0, "sin parpadear: siempre en el cuadro de la alerta")
	entry.set_interference_warning(true)
	for _i in 4:
		entry._process(0.06)
		check(is_equal_approx(entry.modulate.a, ChatEntry.DIM_ALPHA), "atenuada, sin titilar: %s" % entry.modulate.a)
	entry.reduce_flashes = false
	var frames := []
	for _i in 4:
		entry.advance_alarm(0.15)
		frames.append(background.frame)
	check(frames.has(1), "al apagar la opción, vuelve a parpadear: %s" % str(frames))
	entry.free()
	return true


## La alarma (pedido de Benja en el Plan 9.8): cada entrada pita con su propio ritmo, desde el instante en que entra en
## alerta, y la luz parpadea con el pitido: encendida la primera mitad de cada medio segundo.
func test_la_alarma_pita_al_entrar_en_alerta_y_cada_medio_segundo() -> bool:
	var entry := _make_entry()
	entry.alarm = load("res://audio/sfx/alarm_leon.wav")
	var background := entry.get_node("Background") as AnimatedSprite2D
	check(not entry.advance_alarm(0.125), "sin alerta no pita")
	entry.set_state(ChatEntry.State.WARNING)
	# Cada paso dice cómo está al empezar: pitó y en qué cuadro quedó la luz.
	var steps := []
	for _i in 5:
		var beeped: bool = entry.advance_alarm(0.125)
		steps.append([beeped, background.frame])
	check_eq(steps, [[true, 0], [false, 0], [false, 1], [false, 1], [true, 0]],
			"pita al entrar en alerta y a los 0,5 s, con la luz encendida el primer cuarto de segundo")
	entry.muted = true
	for _i in 5:
		check(not entry.advance_alarm(0.125), "callada no pita")
	entry.muted = false
	entry.set_state(ChatEntry.State.SELECTED)
	check(not entry.advance_alarm(0.6), "con su chat abierto no pita")
	entry.free()
	return true


## Cada entrada lleva su ritmo: ya no suenan todas juntas.
func test_cada_entrada_lleva_su_ritmo() -> bool:
	var first := _make_entry()
	var second := _make_entry()
	for entry: Node2D in [first, second]:
		entry.alarm = load("res://audio/sfx/alarm_leon.wav")
	first.set_state(ChatEntry.State.WARNING)
	var beeps := [[], []]
	for step in 8:
		if step == 2:
			second.set_state(ChatEntry.State.WARNING)
		if first.advance_alarm(0.125):
			beeps[0].append(step)
		if second.advance_alarm(0.125):
			beeps[1].append(step)
	check_eq(beeps, [[0, 4], [2, 6]], "cada una desde que entró en alerta")
	first.free()
	second.free()
	return true


func test_la_alarma_pita_tambien_sin_destellos() -> bool:
	var entry := _make_entry()
	entry.alarm = load("res://audio/sfx/alarm_leon.wav")
	entry.reduce_flashes = true
	entry.set_state(ChatEntry.State.WARNING)
	check(entry.advance_alarm(0.25), "pita al entrar en alerta")
	check(not entry.advance_alarm(0.25), "la luz fija, el mismo ritmo")
	check(entry.advance_alarm(0.25), "a los 0,5 s, otra vez")
	entry.free()
	return true


## Un mensaje sin leer en su chat (o en la llamada): un punto junto al nombre (Plan 9.8). Nunca parpadea.
func test_el_punto_de_no_leido() -> bool:
	var entry := _make_entry()
	var label := entry.get_node("NameLabel") as Label
	entry.set_unread(true)
	check_eq(label.text, "León •", "con el punto")
	entry.set_unread(false)
	check_eq(label.text, "León", "sin el punto")
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
