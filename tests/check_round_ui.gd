extends SceneTree
## Real projected mouse events exercise 3D ray picking, not view/controller shortcuts.

const Snapshot = preload("res://tests/state_snapshot.gd")

var failures: int = 0
var _output: String = ""
var _screen: Node3D


func _initialize() -> void:
	Engine.max_fps = 120
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not args.is_empty():
		_output = args[0]
	call_deferred("_run")


func _run() -> void:
	_screen = load("res://presentation/main.tscn").instantiate()
	_screen.pool_one_enabled = false
	_screen.feedback_duration = 0.4
	root.add_child(_screen)
	await physics_frame
	await process_frame
	_check(_screen.world.slots.size() == 5 and _screen.world.cards.size() == 6, "Bounded reusable 3D nodes")
	_check(_screen.world.cards[0] is Area3D, "Cards have world-space geometry and physics picking")
	var floor_mesh: MeshInstance3D = _screen.world.foundation.get_node("Visuals/Ground")
	var floor_top: float = floor_mesh.global_position.y + floor_mesh.mesh.get_aabb().end.y
	var previous_end: float = -1000
	var deck_height: float = _screen.world.slots[0].global_position.y + BridgeSlot.DECK_TOP_Y
	for slot: BridgeSlot in _screen.world.slots:
		var base: MeshInstance3D = slot.get_node("Column/Base")
		var deck: MeshInstance3D = slot.get_node("Column/Deck")
		_check(is_equal_approx(base.global_position.y + base.mesh.get_aabb().position.y, floor_top), "Every column base sits on the floor")
		_check(is_equal_approx(deck.global_position.y + deck.mesh.get_aabb().end.y, deck_height), "All deck surfaces share one level")
		_check(is_zero_approx(slot.global_position.z), "Slots lie on a straight centreline")
		var left: float = deck.global_position.x + deck.mesh.get_aabb().position.x
		if previous_end > -999:
			_check(is_equal_approx(left, previous_end), "Adjacent deck modules meet without gaps")
		previous_end = deck.global_position.x + deck.mesh.get_aabb().end.x
	await _capture("opening")
	await _choose_reward()
	_check(_screen.rules.state.phase == &"playing" and _screen.rules.state.hand.size() == 6, "Popup reward click reaches rules")
	var selection_before: Dictionary = Snapshot.capture(_screen.rules.state)
	await _click(_card("starter-timber-plank"))
	_check(Snapshot.capture(_screen.rules.state) == selection_before, "Selection does not mutate rules or RNG")
	await _hover(_screen.world.slots[0])
	_check(_screen.world.slots[0].get_node("Ghost").visible, "Valid hover displays the wire column preview")
	_check(_screen.world.slots[0].get_node("Column").visible == false, "Empty slot has no solid column")
	await _capture("preview")
	var drag_before: Dictionary = Snapshot.capture(_screen.rules.state)
	await _drag(_card("starter-timber-plank"), Vector2(8, 8))
	_check(Snapshot.capture(_screen.rules.state) == drag_before, "Off-board drop leaves rules and RNG unchanged")
	await _drag(_card("starter-timber-plank"), _screen.world.camera.unproject_position(_screen.world.slots[0].global_position), true)
	_check(Snapshot.capture(_screen.rules.state) == drag_before, "Escape cancels a drag without changing rules")
	await _drag(_card("starter-timber-plank"), _screen.world.camera.unproject_position(_screen.world.slots[0].global_position))
	_check(_screen.rules.state.cells[0].construct.card_id == "starter-timber-plank", "Slot index maps correctly")
	_check(_screen.world.slots[0].get_node("Column").visible, "Placement creates a visible 3D column")
	await _capture("column")
	var occupied_before: Dictionary = Snapshot.capture(_screen.rules.state)
	await _drag(_card("starter-cross-tie"), _screen.world.camera.unproject_position(_screen.world.slots[0].global_position))
	_check(Snapshot.capture(_screen.rules.state) == occupied_before, "Occupied drop neither replaces a column nor spends Flair")
	await _click(_screen.world.slots[0])
	_check(_screen.rules.state.integrity == 6 and _screen.rules.state.cells[0].construct.flair_spent, "Column click activates Integrity Flair")
	await _click(_card("starter-cross-tie"))
	await _click(_screen.world.slots[2])
	var hand_before: int = _screen.rules.state.hand.size()
	await _click(_screen.world.slots[2])
	_check(_screen.rules.state.hand.size() == hand_before + 2, "Column click activates Draw Flair")
	_screen.hud.get_node("%BuyDraw").pressed.emit()
	_check(_screen.rules.state.hand.size() == 7 and _screen.rules.purchased_draw_cost() == 3, "Purchased Draw and its price")
	var page_before: Dictionary = Snapshot.capture(_screen.rules.state)
	_screen.hud.get_node("%Following").pressed.emit()
	_check(_screen.world.cards[0].action_id == _screen.rules.state.hand[6].instance_id, "Seventh card is accessible on page two")
	_check(Snapshot.capture(_screen.rules.state) == page_before, "Paging is view-only")
	_screen.hud.get_node("%Previous").pressed.emit()
	for index in [1, 3, 4]:
		await _click(_screen.world.cards[0])
		await _click(_screen.world.slots[index])
		if index == 3:
			await _capture("bridge-in-progress")
	_check(_screen.presentation_busy and _screen.rules.state.phase != &"playing", "Model closes before visual feedback finishes")
	var settled: Dictionary = Snapshot.capture(_screen.rules.state)
	for slot: BridgeSlot in _screen.world.slots:
		_check(slot.get_node("Column").visible, "Final column is visible before cleanup presentation")
	_screen.hud.get_node("%BuyDraw").pressed.emit()
	_screen.hud.get_node("%NextRound").pressed.emit()
	_screen.hud.get_node("%Restart").pressed.emit()
	_check(Snapshot.capture(_screen.rules.state) == settled, "Input cannot rescue/reopen a visually pending round")
	await _capture("final-column")
	await _wait_for_feedback()
	_check(Snapshot.capture(_screen.rules.state) == settled, "Feedback never changes the settled outcome")
	for slot: BridgeSlot in _screen.world.slots:
		_check(not slot.occupied, "Visual cleanup follows model cleanup")
	await _capture("complete")
	_screen.hud.get_node("%NextRound").pressed.emit()
	_check(_screen.rules.state.round_number == 2 and _screen.rules.purchased_draw_cost() == 1, "Next-round controls preserve price reset")
	for remaining in range(2):
		await _choose_reward()
		for index in range(5):
			await _click(_screen.world.cards[0])
			await _click(_screen.world.slots[index])
			if index < 4 and _screen.world.slots[index].flair_available:
				await _click(_screen.world.slots[index])
		await _wait_for_feedback()
		if remaining == 0:
			_screen.hud.get_node("%NextRound").pressed.emit()
	_check(_screen.rules.state.animal_round_pending or _screen.rules.state.phase == &"roomComplete", "Existing slice boundary is preserved")
	_check(_screen.hud.get_node("%NextRound").disabled, "3D presentation cannot bypass the slice boundary")
	await _capture("slice-complete")
	var terminal_states: Array[Dictionary] = []
	for duration: float in [0.0, 0.65]:
		_screen.hud.get_node("%Restart").pressed.emit()
		_screen.feedback_duration = duration
		Engine.max_fps = 30 if duration == 0.0 else 120
		await _choose_reward()
		for index in range(5):
			await _click(_screen.world.cards[0])
			await _click(_screen.world.slots[index])
		await _wait_for_feedback()
		terminal_states.append(Snapshot.capture(_screen.rules.state))
	_check(terminal_states[0] == terminal_states[1], "Zero/slow feedback at 30/120 FPS caps produces identical rule states")
	_screen.hud.get_node("%Restart").pressed.emit()
	root.size = Vector2i(960, 600)
	await physics_frame
	await process_frame
	await _capture("compact-reward")
	await _choose_reward()
	_check(_screen.rules.state.phase == &"playing", "Popup selection works at 16:10 and smaller window size")
	await _capture("compact")
	print("Native render sample: %d draw calls, %d rendered objects." % [RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)])
	if failures == 0:
		print("World UI checks passed: real ray clicks, columns, both Flair types, paging, Draw, final-placement visibility, closure, slice boundary, feedback-speed independence and resize.")
	_screen.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)


func _choose_reward() -> void:
	await process_frame
	var popup: Control = _screen.hud.get_node("%RewardPopup")
	_check(popup.visible, "Reward popup opens each round")
	_check(not _screen.world.cards[0].visible, "World hand is hidden during reward choice")
	var before: Dictionary = Snapshot.capture(_screen.rules.state)
	# Outside/bridge input must not pass through the modal overlay.
	await _click(_screen.world.slots[0])
	_check(Snapshot.capture(_screen.rules.state) == before, "Popup blocks world input")
	var option: Button = popup.options.get_child(0)
	var point: Vector2 = option.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
	await process_frame
	_check(not popup.visible, "Choosing a reward dismisses the popup")


func _card(definition_id: String) -> WorldCard:
	for card: WorldCard in _screen.world.cards:
		if card.visible and card.definition.id == definition_id:
			return card
	_check(false, "Missing visible card %s" % definition_id)
	return _screen.world.cards[0]


func _click(target: Area3D) -> void:
	await physics_frame
	var point: Vector2 = _screen.world.camera.unproject_position(target.global_position)
	_check(_screen.picker.pick(point) == target, "Projected ray selects %s" % target.name)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	var button := InputEventMouseButton.new()
	button.position = point
	button.button_index = MOUSE_BUTTON_LEFT
	button.pressed = true
	root.push_input(button, true)
	button = button.duplicate()
	button.pressed = false
	root.push_input(button, true)
	await process_frame


func _drag(card: WorldCard, destination: Vector2, cancel: bool = false) -> void:
	await physics_frame
	var origin: Vector2 = _screen.world.camera.unproject_position(card.global_position)
	var press := InputEventMouseButton.new()
	press.position = origin
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	root.push_input(press, true)
	var motion := InputEventMouseMotion.new()
	motion.position = destination
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(motion, true)
	await process_frame
	_check(_screen.picker.dragging, "Moving a held card starts dragging")
	if not cancel and _screen.picker.target is BridgeSlot and not _screen.picker.target.occupied:
		await _capture("drag-preview")
	if cancel:
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.pressed = true
		root.push_input(escape, true)
	press.position = destination
	press.pressed = false
	root.push_input(press, true)
	await process_frame
	_check(not _screen.picker.dragging and card.collision_layer == 1, "Release/cancel restores card picking")


func _hover(target: Area3D) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = _screen.world.camera.unproject_position(target.global_position)
	root.push_input(motion, true)
	await process_frame


func _wait_for_feedback() -> void:
	for _frame in range(180):
		if not _screen.presentation_busy:
			return
		await process_frame
	_check(false, "Feedback did not finish")


func _capture(name: String) -> void:
	if _output.is_empty():
		return
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(_output.path_join(name + ".png")) == OK, "Capture %s" % name)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr(message)
