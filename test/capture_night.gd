extends SceneTree
## Capturas de la noche para revisarla a ojo (Plan 5). No es una prueba: corre con ventana.
## Uso: ~/tools/godot-wsl.sh --path "$PWD" -s res://test/capture_night.gd -- /mnt/c/dev/capturas/night.png /mnt/c/dev/capturas/night_lost.png
## 1. A las 03:00, con Sanity 25 (viñeta), Trust 55, 1 de 3 videos y León herido y aturdido. Gonzalo pide ayuda.
##    El chat está cerrado, así que se ven la hora del celular y las entradas del PC.
## 2. Se abre el chat de Gonzalo, que con 1 PV recibe una acción incorrecta y muere: la pantalla de derrota
##    explica la solicitud, y detrás, en el chat, quedan su grito y el aviso de daño.

const DESK := preload("res://scenes/desk/desk.tscn")
const RuleEvaluator := preload("res://scripts/core/rule_evaluator.gd")


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var desk := DESK.instantiate()
	root.add_child(desk)
	var manager := desk.get_node("RequestManager")
	manager.requests_arrive = false
	manager.rng.seed = 5
	var state: RefCounted = manager.state
	state.elapsed = 210.0
	state.sanity = 25.0
	state.trust = 55.0
	state.videos.pending.clear()
	state.videos.received = 1
	state.friends[0].hurt(2, 15.0)
	var request: RefCounted = manager.start_request(1)
	await create_timer(2.0).timeout
	await _save(0)
	desk.get_node("UI/ChatPanel").open_for(1)
	state.friends[1].health = 1
	manager.catalog.balance.wrong_hurt_chance = 1.0
	var entity: EntityData = request.get("entity")
	var rule := RuleEvaluator.applicable_rule(entity, request.get("situation"))
	for action: ActionData in entity.actions:
		if action.id != rule.correct_action_id and action.id != rule.risky_action_id:
			manager.answer(1, action)
			break
	await create_timer(2.0).timeout
	await _save(1)
	quit()


func _save(index: int) -> void:
	await RenderingServer.frame_post_draw
	var path: String = OS.get_cmdline_user_args()[index]
	root.get_texture().get_image().save_png(path)
	print("Captura guardada en ", path)
