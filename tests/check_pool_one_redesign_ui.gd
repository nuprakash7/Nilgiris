extends SceneTree
## One native interaction case and wide/small captures.
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func expect(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)
func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1920, 1080)
	var screen = load("res://presentation/main.tscn").instantiate()
	screen.feedback_duration = 0.04
	root.add_child(screen)
	await create_timer(0.3).timeout
	var state: RunState = screen.rules.state
	state.phase = &"playing"
	state.selected_reward.clear()
	state.hand.clear()
	state.deck.clear()
	state.draw_pile.clear()
	state.discard_pile.clear()
	state.integrity = 100
	var ids := ["centre-pier", "steel-girder", "pool-1-lone-pier", "timber-plank", "iron-spike", "cross-tie", "guide-beam", "end-bearing", "staging-deck", "steel-girder", "starter-cross-tie", "pool-1-layered-support"]
	for index in range(ids.size()):
		var card := CardInstance.new("redesign-%d" % index, ids[index])
		state.hand.append(card)
		state.deck.append(card.plain_copy())
	for index in range(3): state.draw_pile.append(CardInstance.new("extra-%d" % index, "starter-iron-spike"))
	state.intent = {"attackId": "reward-05-brief-squall", "resolvedHitKeys": [], "resolved": false}
	screen.rules._update_attack()
	screen._render()
	screen._selected_id = "redesign-0"
	await screen._place(0)
	expect(screen.hud.sequence.checkpoints[2].text == "8", "Hefty next-hit bonus is displayed at original checkpoint")
	screen._selected_id = "redesign-1"
	await screen._place(1)
	screen._activate_flair(1)
	expect(state.hand.any(func(card: CardInstance) -> bool: return card.zero_integrity_this_round), "Steel Flair updates exact hand copy")
	screen._selected_id = "redesign-2"
	await screen._place(3)
	screen._activate_flair(3)
	expect(screen._rewards.visible and state.pending_choice.get("kind", "") == "flairDiscard", "New Flair opens existing choice popup")
	var discard_id: String = state.pending_choice.ids[0]
	screen._rewards.chosen.emit(discard_id)
	expect(state.pending_choice.is_empty() and not screen._rewards.visible and state.forest_impacts.back().damage == 8, "Flair resolves and original scheduled hit includes Hefty once")
	var steel_view: WorldCard
	for card: WorldCard in screen.world.cards:
		if card.visible and card.definition.get("id", "") == "steel-girder": steel_view = card
	expect(steel_view != null and steel_view._effect.text.contains("random"), "New Flair text is present on hand card")
	screen.picker._set_target(steel_view)
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://references/pool-one-redesign-wide.png")
	root.size = Vector2i(1280, 720)
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://references/pool-one-redesign-small.png")
	expect(not screen.hud._inspect.visible, "Hover lift does not restore removed tooltip")
	print("Pool 1 redesign UI: one native case; failures=", failures)
	screen.queue_free()
	await process_frame
	quit(1 if failures else 0)
