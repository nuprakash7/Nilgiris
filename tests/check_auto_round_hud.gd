extends SceneTree
## Six focused native cases; short fixtures keep verification bounded.
var screen: Node3D
var failures: int = 0
const OUTPUT := "/tmp/nilgiris-auto-round-hud"
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
	screen.feedback_duration = 0.04
	screen.round_rain_duration = 0.08
	root.add_child(screen)
	await create_timer(0.3).timeout
	if "--choice-only" in OS.get_cmdline_user_args():
		await final_target_choice()
		print("Final target-choice auto transition: %d failures." % failures)
		quit(1 if failures else 0)
		return
	await ordinary_round()
	await room_crossing()
	await capacity_choice()
	await terminal_states()
	await wide_input()
	await small_layout()
	print("Reference HUD / automatic rounds: six focused cases, %d failures." % failures)
	quit(1 if failures else 0)

func fixture(room: int = 0, progress: int = 0, integrity: int = 40) -> void:
	screen._start_slice()
	var state: RunState = screen.rules.state
	state.phase = &"playing"
	state.room_index = room
	state.bridge_progress = progress
	state.integrity = integrity
	state.selected_reward.clear()
	state.hand.clear()
	state.hand.append(CardInstance.new("fixture-last", "starter-timber-plank"))
	state.hand.append(CardInstance.new("fixture-spare", "starter-timber-plank"))
	state.constructs_placed_this_round = 4
	for slot in range(4):
		state.cells[slot].construct = PlacedConstruct.new(CardInstance.new("fixture-%d" % slot, "starter-timber-plank"), 4, 4)
	screen._selected_id = "fixture-last"
	screen._render()

func ordinary_round() -> void:
	fixture()
	screen._place(4)
	expect(screen.presentation_busy and screen.hud.rain.active, "Completed round immediately starts non-interactive rain")
	await create_timer(0.8).timeout
	expect(screen.rules.state.round_number == 2 and screen.rules.state.phase == &"roundChoice", "Ordinary round automatically opens the next reward choice")
	expect(screen.rules.state.gold == 8 and screen.rules.state.bridge_progress == 29, "Transition preserves 29 Progress and exactly 5 round Gold")
	await create_timer(0.1).timeout
	expect(screen.rules.state.round_number == 2 and not screen.hud.ui.has("NextRound"), "No Next round control and no repeated advancement")

func room_crossing() -> void:
	fixture(0, 45)
	screen._place(4)
	await create_timer(0.8).timeout
	expect(screen.rules.state.room_index == 1 and screen.rules.state.round_number == 2 and screen.rules.total_progress() == 74, "Automatic progression crosses a room boundary without losing overflow")

func capacity_choice() -> void:
	fixture()
	var state: RunState = screen.rules.state
	state.reward_round_type = &"animal"
	state.selected_animal_id = "nilgiri-tahr"
	state.animal_round_pending = true
	state.habitat_batch.assign(["woods", "woods", "woods"])
	for index in range(4):
		state.animals.append({"instanceId": "owned-%d" % index, "animalId": screen._catalog.wildlife.animals[index].id, "nextEligibleRound": 1, "lastActivationRound": null, "effectState": {"activations": 0}})
	screen._place(4)
	await create_timer(0.8).timeout
	expect(state.round_number == 1 and not state.pending_animal.is_empty() and screen._rewards.visible, "Animal capacity decision pauses automatic advancement after rain")
	screen._choose_reward("")
	await process_frame
	expect(state.round_number == 2 and state.pending_animal.is_empty() and not screen.hud.rain.active, "Resolving capacity resumes automatically without replaying rain")

func terminal_states() -> void:
	fixture(4, 45)
	screen._place(4)
	await create_timer(0.8).timeout
	expect(screen.rules.state.phase == &"won" and screen.rules.state.round_number == 1, "Victory remains terminal")
	fixture(0, 0, 0)
	screen._place(4)
	await create_timer(0.2).timeout
	expect(screen.rules.state.phase == &"lost" and screen.rules.state.round_number == 1 and not screen.hud.rain.active, "Defeat is not automatically restarted")

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

func wide_input() -> void:
	screen._start_slice()
	screen._rewards.options.get_child(0).pressed.emit()
	await physics_frame
	var card: WorldCard = screen.world.cards[0]
	var id: String = card.action_id
	var from: Vector2 = screen.world.camera.unproject_position(card.global_position)
	var to: Vector2 = screen.world.camera.unproject_position(screen.world.slots[0].global_position)
	motion(from)
	await process_frame
	expect(screen.hud._inspect.visible, "Reference skin retains contextual hover")
	mouse(from, true)
	motion(to)
	await process_frame
	mouse(to, false)
	await process_frame
	expect(screen.rules.state.cells[0].construct != null and screen.rules.state.cells[0].construct.instance_id == id, "Dragging still reaches the correct slot")
	screen.hud.inspect("", "")
	expect(screen.hud.integrity.size.x == screen.hud.integrity.size.y and screen.hud.sequence.get_child(0) is DiamondCheckpoint, "Circular uncapped readout and diamond checkpoint views are present")
	await capture("wide")

func small_layout() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	await create_timer(0.3).timeout
	screen.hud.inspect("", "")
	expect(screen.hud.integrity.get_rect().end.x < screen.hud.ruler.position.x and screen.hud.ruler.get_rect().end.x < screen.hud._threat.position.x, "Dial, ruler and threat housing remain separate at 1280×720")
	expect(screen.hud._stats.get_rect().end.x < screen.hud.control("Pause").position.x and screen.hud._threat.get_rect().end.x <= screen.hud.size.x, "Small-window status controls stay inside the viewport")
	await capture("small")

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT.path_join(label + ".png"))

func final_target_choice() -> void:
	fixture()
	screen.rules.state.hand[0].card_id = "grand-load-distributor"
	screen._render()
	screen._place(4)
	expect(not screen.rules.state.pending_choice.is_empty() and not screen.hud.rain.active, "Final Support placement waits for its required target before rain")
	screen._choose_reward("fixture-0")
	expect(screen.presentation_busy and screen.hud.rain.active, "Target resolution starts the same rain transition")
	await create_timer(0.8).timeout
	expect(screen.rules.state.round_number == 2 and screen.rules.state.phase == &"roundChoice" and screen.rules.state.gold == 10 and screen.rules.total_progress() == 36, "Final target choice advances once, retaining net Integrity / 5 Gold")
