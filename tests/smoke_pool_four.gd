extends SceneTree
## One short native flow: cross into Pool 4, render an attack and rare removal modal.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var screen: Node3D = load("res://presentation/main.tscn").instantiate()
	root.add_child(screen)
	await create_timer(0.25).timeout
	var rules: RoundRules = screen.rules
	if rules == null or not rules.errors.is_empty():
		push_error("Main scene failed to initialize Pool 4.")
		quit(1)
		return
	rules.state.phase = &"roomComplete"
	rules.state.bridge_progress = 150
	ConstructOffers.sync_pool(rules.state, screen._catalog)
	if not rules.start_next_round().is_empty() or rules.state.reward_pool_id != 4:
		push_error("Progression did not enter Pool 4.")
		quit(1)
		return
	screen._render()
	await create_timer(0.25).timeout
	rules.choose_reward(rules.state.reward_offers[0].offerId)
	rules.state.animals.append({"instanceId": "smoke-bear", "animalId": "sloth-bear", "nextEligibleRound": 1, "lastActivationRound": null, "effectState": {"activations": 0}})
	rules.state.discard_pile.append(CardInstance.new("smoke-target", "debris"))
	rules.activate_animal("smoke-bear")
	screen._render()
	await create_timer(0.5).timeout
	if rules.state.pending_choice.is_empty() or not screen._rewards.visible:
		push_error("Debris removal popup did not open.")
		quit(1)
		return
	print("Pool 4 native smoke: progression, attack HUD and rare Debris removal popup opened.")
	quit()
