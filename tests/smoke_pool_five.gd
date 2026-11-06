extends SceneTree
## One short native flow: cross into Pool 5, render an attack and very-rare search modal.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var screen: Node3D = load("res://presentation/main.tscn").instantiate()
	root.add_child(screen)
	await create_timer(0.25).timeout
	var rules: RoundRules = screen.rules
	if rules == null or not rules.errors.is_empty():
		push_error("Main scene failed to initialize Pool 5.")
		quit(1)
		return
	rules.state.phase = &"roomComplete"
	rules.state.bridge_progress = 200
	ConstructOffers.sync_pool(rules.state, screen._catalog)
	if not rules.start_next_round().is_empty() or rules.state.reward_pool_id != 5:
		push_error("Progression did not enter Pool 5.")
		quit(1)
		return
	screen._render()
	if screen.world.slots.size() != 7:
		push_error("Pool 5 did not create seven visual slots.")
		quit(1)
		return
	var camera: Camera3D = screen.world.camera
	var viewport_width: float = root.get_visible_rect().size.x
	for slot: BridgeSlot in screen.world.slots:
		for side: float in [-1.0, 1.0]:
			var edge: Vector3 = slot.global_position + Vector3(side * BridgeSlot.MODULE_WIDTH * 0.5, 0, 0)
			var projected: Vector2 = camera.unproject_position(edge)
			if projected.x < 0 or projected.x > viewport_width:
				push_error("Seven-slot bridge falls outside the camera width.")
				quit(1)
				return
	await create_timer(0.25).timeout
	rules.choose_reward(rules.state.reward_offers[0].offerId)
	rules.state.animals.append({"instanceId": "smoke-macaque", "animalId": "lion-tailed-macaque", "nextEligibleRound": 1, "lastActivationRound": null, "effectState": {"activations": 0}})
	rules.state.draw_pile.append(CardInstance.new("smoke-target", "mountain-abutment"))
	rules.activate_animal("smoke-macaque")
	screen._render()
	await create_timer(0.5).timeout
	if rules.state.pending_choice.is_empty() or not screen._rewards.visible:
		push_error("distinct-search popup did not open.")
		quit(1)
		return
	print("Pool 5 native smoke: progression, attack HUD and rare distinct-search popup opened.")
	quit()
