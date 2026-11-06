extends SceneTree
## Native pointer-driven Pool 1 → common-animal trial → activation loop.
var screen: Node3D
var failures := 0
var output := ""
var animal_trials := 0
var acquisitions := 0
var activations := 0
var test_seed: int = 1

func _initialize() -> void:
	Engine.max_fps = 120
	var args := OS.get_cmdline_user_args()
	if not args.is_empty(): output = args[0]
	if args.size() > 1: test_seed = int(args[1])
	call_deferred("_run")

func _run() -> void:
	screen = load("res://presentation/main.tscn").instantiate()
	screen.run_seed = test_seed
	screen.feedback_duration = 0.02
	root.add_child(screen)
	await physics_frame
	await process_frame
	_check(screen.rules.errors.is_empty(), "Pool 1 content is ready")
	await _capture("pool-one-opening")
	for turn in range(160):
		var state: RunState = screen.rules.state
		var popup: Control = screen.hud.get_node("%RewardPopup")
		if screen.presentation_busy:
			await process_frame
			continue
		if state.phase == &"roundChoice":
			if state.reward_round_type == &"animal":
				animal_trials += 1
				await _capture("common-animal-offers")
			await _click_button(popup.options.get_child(0))
		elif not state.pending_choice.is_empty():
			await _capture("animal-choice")
			await _click_button(popup.options.get_child(0))
		elif state.phase == &"playing":
			if not state.animals.is_empty() and activations == 0 and state.constructs_placed_this_round == 1:
				await _click_button(screen.hud.get_node("%Animals"))
				await _capture("common-animal-roster")
				var selected: Button
				for option: Button in popup.options.get_children():
					if not option.disabled and option.text != "Close":
						selected = option
						break
				_check(selected != null, "Acquired animal is usable on the next round")
				if selected != null:
					await _click_button(selected)
					activations += 1
				else:
					await _click_button(popup.options.get_child(popup.options.get_child_count() - 1))
				continue
			var flair: PlacedConstruct = null
			for cell: Dictionary in state.cells:
				if cell.construct != null and screen.rules.flair_error(cell.construct.instance_id).is_empty():
					flair = cell.construct
					break
			if flair != null:
				for slot: BridgeSlot in screen.world.slots:
					if state.cells[slot.slot_index].construct == flair:
						await _click_world(slot)
				continue
			var card: WorldCard = null
			for view: WorldCard in screen.world.cards:
				if view.visible and view.action_id == "card-1": card = view
			if card == null: card = screen.world.cards[0]
			var best := -1
			var gain := -1
			for cell: Dictionary in state.cells:
				if cell.construct == null and screen.rules.contribution(card.action_id, cell.slotIndex) > gain:
					gain = screen.rules.contribution(card.action_id, cell.slotIndex)
					best = cell.slotIndex
			await _click_world(card)
			await _click_world(screen.world.slots[best])
		elif not state.pending_animal.is_empty():
			await _click_button(popup.options.get_child(popup.options.get_child_count() - 1))
		elif state.phase == &"roundComplete" and screen.rules.next_round_error().is_empty():
			if state.round_result.has("earnedAnimalId"):
				acquisitions += 1
				_check(int(state.animals.back().nextEligibleRound) == state.round_number + 1, "Acquisition begins next round")
			await _click_button(screen.hud.get_node("%NextRound"))
		else:
			break
		if activations > 0 and state.pending_choice.is_empty():
			break
	print("UI checkpoint: ", animal_trials, " / ", acquisitions, " / ", activations, " phase ", screen.rules.state.phase, " round ", screen.rules.state.round_number, " log ", screen.rules.state.log.slice(-5))
	_check(animal_trials > 0 and acquisitions > 0 and activations > 0, "Complete natural trial/acquisition/activation loop")
	await _capture("animal-active-gameplay")
	for id: String in ["wild-boar", "bonnet-macaque-troop", "peafowl-flock", "common-kingfisher", "red-whiskered-bulbul", "spotted-dove-pair"]:
		screen.hud.get_node("%Restart").pressed.emit()
		var state: RunState = screen.rules.state
		state.animals.assign([{"instanceId": "ui-animal", "animalId": id, "acquisitionRound": 0, "lastActivationRound": null, "nextEligibleRound": 1, "effectState": {"activations": 0}}])
		screen._render()
		var popup: Control = screen.hud.get_node("%RewardPopup")
		await _click_button(popup.options.get_child(0))
		for slot in range(2):
			await _click_world(screen.world.cards[0])
			await _click_world(screen.world.slots[slot])
		await _click_button(screen.hud.get_node("%Animals"))
		await _click_button(popup.options.get_child(0))
		_check(not state.pending_choice.is_empty(), "Target popup for " + id)
		_check(screen.hud.get_node("%BuyDraw").disabled, "Target choice locks background Draw")
		await _capture("choice-" + id)
		await _click_button(popup.options.get_child(0))
		if not state.pending_choice.is_empty() and state.pending_choice.optional:
			await _click_button(popup.options.get_child(popup.options.get_child_count() - 1))
		_check(state.pending_choice.is_empty() and not popup.visible, "Target choice completes and unlocks gameplay")
	# Controlled capacity fixture tests the same modal used by real acquisitions.
	var state: RunState = screen.rules.state
	state.phase = &"roundComplete"
	state.round_result = {"progress": 0, "earnedCardId": "timber-plank", "trialIncomplete": false}
	state.animal_capacity = 1
	state.pending_animal = {"instanceId": "incoming", "animalId": "chital", "acquisitionRound": state.round_number, "lastActivationRound": null, "nextEligibleRound": state.round_number + 1, "effectState": {"activations": 0}}
	state.sightings.append({"round": state.round_number, "habitats": ["woods", "woods", "woods"], "animalId": "chital", "instanceId": "incoming", "disposition": "pending"})
	screen._render()
	await _capture("animal-capacity")
	await _click_button(screen.hud.get_node("%RewardPopup").options.get_child(0))
	_check(state.pending_animal.is_empty() and state.animals.size() == 1 and state.animals[0].instanceId == "incoming", "Capacity replacement through actual button input")
	if failures == 0:
		print("Pool 1 UI passed: native reward selection, placements, Flair, animal trial, acquisition, next-round readiness, activation, all six targeting UI cases and capacity replacement.")
	screen.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

func _click_world(target: Area3D) -> void:
	await physics_frame
	await _mouse(screen.world.camera.unproject_position(target.global_position))

func _click_button(button: Button) -> void:
	_check(not button.disabled, "Control is enabled")
	await _mouse(button.get_global_rect().get_center())

func _mouse(position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	root.push_input(motion, true)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
	await process_frame

func _capture(label: String) -> void:
	if output.is_empty(): return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label + ".png"))

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)
