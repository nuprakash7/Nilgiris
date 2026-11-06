extends SceneTree
## Four focused fan cases; no gameplay suite or seed sweep.
var screen: Node3D
var failures: int = 0
const OUTPUT := "/tmp/nilgiris-hand-fan"
func _initialize() -> void:
	call_deferred("_run")
func expect(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1920, 1080)
	screen = load("res://presentation/main.tscn").instantiate()
	root.add_child(screen)
	await create_timer(0.3).timeout
	screen.rules.state.phase = &"playing"
	screen.rules.state.hand.clear()
	for index in range(12): screen.rules.state.hand.append(CardInstance.new("fan-%d" % index, "timber-plank" if index % 2 == 0 else "tempered-arch"))
	screen._render()
	await physics_frame
	if "--final" in OS.get_cmdline_user_args():
		await hover_access()
		await small_and_seven()
		print("Final fan hover and small framing: %d failures." % failures)
		quit(1 if failures else 0)
		return
	if "--hover-only" in OS.get_cmdline_user_args():
		await hover_access()
		print("Fan hover retry: %d failures." % failures)
		quit(1 if failures else 0)
		return
	await all_cards()
	await hover_access()
	await dragging()
	await small_and_seven()
	print("Hand fan: four focused cases, %d failures." % failures)
	quit(1 if failures else 0)

func all_cards() -> void:
	var visible: int = 0
	for card: WorldCard in screen.world.cards:
		visible += int(card.visible)
		for point: Vector2 in card.screen_polygon(screen.world.camera): expect(root.get_visible_rect().has_point(point), "Every resting card corner stays in the viewport")
	expect(visible == 12 and not screen.hud.ui.has("Previous") and not screen.hud.ui.has("Following") and not screen.hud.ui.has("Page"), "Entire twelve-card hand is visible without pagination")
	expect(screen.world.cards[0].rotation.z > 0 and screen.world.cards[-1].rotation.z < 0, "Hand forms a fan with opposite end rotations")
	await capture("wide")

func point_for(card: WorldCard) -> Vector2:
	for x: float in [-0.46, -0.35, -0.2, 0.0, 0.2, 0.35, 0.46]:
		for y: float in [0.4, 0.2, 0.0, -0.2, -0.4]:
			var point: Vector2 = screen.world.camera.unproject_position(card.to_global(Vector3(x * WorldCard.SIZE.x, y * WorldCard.SIZE.y, 0.14)))
			if screen.picker.pick(point) == card: return point
	return Vector2(-1, -1)

func motion(at: Vector2) -> void:
	root.warp_mouse(at)
	var event := InputEventMouseMotion.new()
	event.position = at
	root.push_input(event, true)
func mouse(at: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = at
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	root.push_input(event, true)

func hover_access() -> void:
	for card: WorldCard in screen.world.cards:
		var point: Vector2 = point_for(card)
		expect(point.x >= 0, "Every overlapped copy has an accessible exposed strip")
		motion(point)
		await process_frame
		expect(screen.picker.target == card, "Hover expected %s got %s at %s; GUI %s" % [card.name, screen.picker.target.name if screen.picker.target != null else "none", str(point), str(root.gui_get_hovered_control())])
	var card: WorldCard = screen.world.cards[5]
	motion(point_for(card))
	await create_timer(0.2).timeout
	expect(card._visual.position.z > screen.world.cards[-1].position.z and is_zero_approx(card.rotation.z + card._visual.rotation.z), "Hovered card rises in front and straightens for reading")
	await capture("hover")

func dragging() -> void:
	var card: WorldCard = screen.world.cards[3]
	var id: String = card.action_id
	var from: Vector2 = point_for(card)
	var to: Vector2 = screen.world.camera.unproject_position(screen.world.slots[0].global_position)
	motion(from)
	mouse(from, true)
	motion(to)
	await process_frame
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape, true)
	mouse(to, false)
	await process_frame
	expect(not screen.picker.dragging and screen.rules.state.hand.size() == 12 and screen.rules.state.cells[0].construct == null, "Escape cancels a fan drag without playing a card")
	from = point_for(card)
	motion(from)
	mouse(from, true)
	motion(to)
	await process_frame
	mouse(to, false)
	await process_frame
	expect(screen.rules.state.cells[0].construct != null and screen.rules.state.cells[0].construct.instance_id == id and screen.rules.state.hand.size() == 11, "Fan drag plays the intended physical copy")

func small_and_seven() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	if screen.rules.state.hand.size() < 12:
		screen.rules.state.hand.append(CardInstance.new("fan-extra", "monolithic-pier"))
	screen.rules.state.reward_pool_id = 5
	RunSetup.initialize_intent(screen.rules.state, screen._catalog)
	screen.rules._update_attack()
	screen._render()
	await create_timer(0.3).timeout
	screen.picker.clear_target()
	await create_timer(0.2).timeout
	for card: WorldCard in screen.world.cards:
		for point: Vector2 in card.screen_polygon(screen.world.camera): expect(root.get_visible_rect().has_point(point), "All twelve cards fit after resize and seven-slot camera widening")
	expect(screen.world.cards.filter(func(card: WorldCard) -> bool: return card.visible).size() == screen.rules.state.hand.size(), "No card is hidden at the smaller resolution")
	await capture("small")

func capture(label: String) -> void:
	screen.hud.inspect("", "")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT.path_join(label + ".png"))
