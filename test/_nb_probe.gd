extends SceneTree
const DESK := preload("res://scenes/desk/desk.tscn")
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	DisplayServer.window_set_size(Vector2i(int(args[1]), int(args[2])))
	await create_timer(0.3).timeout
	var desk := DESK.instantiate()
	desk.get_node("RequestManager").night_number = 1
	desk.get_node("RequestManager").requests_arrive = false
	root.add_child(desk)
	var entity: EntityData = desk.get_node("RequestManager").catalog.known_entities(1)[0]
	desk._on_entity_page_requested(0, entity)
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(args[0])
	quit()
