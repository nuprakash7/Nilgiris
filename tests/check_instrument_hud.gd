extends SceneTree
## Six focused presentation cases, including native interaction and two layouts.
var screen: Node3D
var failures: int = 0
var output: String = "/tmp/nilgiris-instrument-hud"
func _initialize() -> void:
	call_deferred("_run")
func expect(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1920, 1080)
	screen = load("res://presentation/main.tscn").instantiate()
	screen.feedback_duration = 0.1
	root.add_child(screen)
	await create_timer(0.4).timeout
	if screen.rules == null:
		push_error("Scene did not initialize")
		quit(1)
		return
	if "--layout-only" in OS.get_cmdline_user_args():
		await choose_first_reward()
		await capture("wide-final")
		await small_layout()
		print("Final responsive HUD layout: %d failures." % failures)
		quit(1 if failures else 0)
		return
	await wide_layout()
	await hover_and_drag()
	await targeting_and_pause()
	await instruments()
	await attack_sequence()
	await small_layout()
	print("Instrument HUD: six focused cases, %d failures." % failures)
	quit(1 if failures else 0)

func choose_first_reward() -> void:
	var button: Button = screen._rewards.options.get_child(0)
	button.pressed.emit()
	await process_frame

func wide_layout() -> void:
	expect(screen.hud.ruler.target == screen._target_progress and screen._target_progress == 250, "Ruler derives whole-run target")
	expect(screen.hud.control("Restart").is_visible_in_tree() == false and screen.hud._animals.get_child_count() == 0, "Restart is in pause menu and empty animal capacity is invisible")
	await choose_first_reward()
	await capture("wide")

func motion(at: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = at
	root.push_input(event, true)
func mouse(at: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = at
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	root.push_input(event, true)

func hover_and_drag() -> void:
	await physics_frame
	var card: WorldCard = screen.world.cards[0]
	var from: Vector2 = screen.world.camera.unproject_position(card.global_position)
	motion(from)
	await process_frame
	expect(screen.picker.target == card and screen.hud._inspect.visible, "Card hover shows only contextual inspection")
	var id: String = card.action_id
	var to: Vector2 = screen.world.camera.unproject_position(screen.world.slots[0].global_position)
	mouse(from, true)
	motion(to)
	await process_frame
	expect(screen.picker.dragging, "Drag starts through the unblocked HUD")
	mouse(to, false)
	await process_frame
	expect(screen.rules.state.cells[0].construct != null and screen.rules.state.cells[0].construct.instance_id == id and not screen.picker.dragging, "Drop places the original copy in the selected slot")

func targeting_and_pause() -> void:
	# Reuse the real animal targeting path, not a new HUD-specific game action.
	screen.rules.state.animals.append({"instanceId": "test-mark", "animalId": "ghost-of-the-nilgiris-black-panther", "nextEligibleRound": 1, "lastActivationRound": null, "effectState": {"activations": 0}})
	screen._render()
	var ability: Button = screen.hud._animals.get_child(0)
	ability.pressed.emit()
	await process_frame
	expect(screen._rewards.visible and not screen.rules.state.pending_choice.is_empty(), "Compact animal icon opens the existing target selection")
	var target: Button = screen._rewards.options.get_child(0)
	target.pressed.emit()
	await process_frame
	expect(not screen._rewards.visible, "Choosing a target closes the modal")
	screen.hud.control("Pause").pressed.emit()
	expect(paused and screen.hud.control("Restart").is_visible_in_tree(), "Pause freezes the scene and exposes Restart")
	screen.hud.control("Resume").pressed.emit()
	expect(not paused, "Resume restores processing")

func instruments() -> void:
	screen.hud.integrity.present(10)
	screen.hud.integrity.present(16)
	expect(screen.hud.integrity.value == 16 and screen.hud.integrity._delta == "+6", "Integrity shows exact gain with a transient +6")
	screen.hud.integrity.present(1)
	expect(screen.hud.integrity._delta == "-15", "Forest subtraction stays separate from Progress")
	screen.hud.ruler.present(0, 250, false)
	await screen.hud.transfer_to_progress(25, 25)
	await create_timer(0.3).timeout
	expect(roundi(screen.hud.ruler.value) == 25 and screen.hud.integrity.value == 0, "Surviving Integrity visually transfers into accumulated Progress")
	screen._render()

func attack_sequence() -> void:
	var attack := {"name": "Sample", "hits": [{"damage": 15, "when": {"type": "fullBoard"}}], "midRoundEffects": [{"when": {"type": "slotCount", "count": 2}, "effect": {"type": "lightningStrike"}}]}
	var intent := {"resolvedHitKeys": [], "resolvedEffectKeys": [], "resolved": false}
	screen.hud.sequence.present(attack, intent, screen.rules.state.cells)
	expect(screen.hud.sequence.checkpoints[0].text == "·" and screen.hud.sequence.checkpoints[4].text == "15" and "ϟ" in screen.hud.sequence.checkpoints[1].text, "Sequence projects dots, damage and non-damage effects from timing data")
	var checkpoint: Button = screen.hud.sequence.get_child(1)
	checkpoint.grab_focus()
	await process_frame
	expect(screen.hud._inspect.visible and "Lightning Strike" in screen.hud.control("InspectText").text, "Focused effect checkpoint exposes its detailed explanation")
	expect(CardText.compact({"effectText": "Adds 24 Integrity.", "baseIntegrity": 24}) == "", "Card copy does not duplicate its printed Integrity")
	screen._render()

func small_layout() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	await create_timer(0.35).timeout
	screen.hud.inspect("", "")
	motion(Vector2(650, 400))
	await process_frame
	expect(screen.hud.ruler.position.x > screen.hud.integrity.get_rect().end.x and screen.hud._threat.get_rect().end.x < screen.hud.size.x, "Ruler and attack strip fit at smaller logical resolution")
	expect(screen.hud._actions.get_rect().end.y <= screen.hud.size.y and screen.hud._piles.position.y > 0, "Hand-side controls stay within the smaller viewport")
	await capture("small")

func capture(label: String) -> void:
	screen.hud.inspect("", "")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label + ".png"))
