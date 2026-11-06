extends SceneTree
## One native lifecycle: final-animal target → paused final placement → win → fresh run.
func _initialize() -> void:
	call_deferred("_run")

func fail(message: String) -> void:
	push_error(message)
	quit(1)

func _run() -> void:
	var screen: Node3D = load("res://presentation/main.tscn").instantiate()
	root.add_child(screen)
	await create_timer(0.25).timeout
	var rules: RoundRules = screen.rules
	if rules == null or not rules.errors.is_empty() or rules.catalog.wildlife.animals.size() != 75:
		fail("Full roster did not initialize.")
		return
	rules.choose_reward(rules.state.reward_offers[0].offerId)
	rules.state.animals.append({"instanceId": "panther", "animalId": "ghost-of-the-nilgiris-black-panther", "nextEligibleRound": 1, "lastActivationRound": null, "effectState": {"activations": 0}})
	rules.activate_animal("panther")
	screen._render()
	if not screen._rewards.visible:
		fail("Final-animal target popup did not open.")
		return
	var marked: String = rules.state.hand[0].instance_id
	screen._choose_reward(marked)
	if rules.state.hand[0].permanent_integrity_multiplier != 1.5:
		fail("Panther target selection did not mark the copy.")
		return
	rules.state.room_index = 4
	rules.state.bridge_progress = 0
	rules.state.intent = {"attackId": "reward-61-the-mountain-roars", "resolvedHitKeys": [], "resolved": false}
	rules._update_attack()
	rules.state.cells.clear()
	for index in range(7):
		var placed: PlacedConstruct = null if index == 6 else PlacedConstruct.new(CardInstance.new("board-%d" % index, "mountain-abutment"), 28, 28)
		rules.state.cells.append({"slotIndex": index, "construct": placed})
	rules.state.hand.clear()
	rules.state.hand.append(CardInstance.new("last", "grand-load-distributor"))
	rules.state.selected_reward.clear()
	rules.state.integrity = 110
	rules.play_card("last", 6)
	screen.feedback_duration = 0.05
	screen._render()
	await create_timer(0.25).timeout
	screen._choose_reward("board-0")
	if not screen.presentation_busy or screen._rewards.visible or screen._display_progress != 200:
		fail("Final Support choice skipped feedback or left its modal blocking the scene.")
		return
	await create_timer(0.25).timeout
	if rules.state.phase != &"won" or screen.presentation_busy or not "Bridge complete" in screen._prompt.text:
		fail("Choice completion did not settle into the clear victory flow.")
		return
	screen._start_slice()
	await create_timer(0.25).timeout
	if screen.rules.state.phase != &"roundChoice" or not screen.rules.state.animals.is_empty() or screen.world.slots.size() != 5:
		fail("Fresh run did not reset animals and seven-slot presentation.")
		return
	print("Full-roster native lifecycle passed: animal popup, final-choice feedback, victory, fresh run.")
	quit()
