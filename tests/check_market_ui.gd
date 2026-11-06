extends SceneTree
## One native case: visible market -> place -> buy -> hover -> next round.
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
	screen.round_rain_duration = 0.06
	root.add_child(screen)
	await create_timer(0.3).timeout
	var state: RunState = screen.rules.state
	var market: MarketStrip = screen.hud.market
	expect(not screen._rewards.visible and market.tiles.size() == 4 and state.hand.size() == 7, "Direct board entry with seven cards and four market offers")
	state.gold = 5
	state.reward_offers[0] = {"offerId":"ui-eight", "cardId":"guide-beam", "price":8}
	var other: Array = state.reward_offers.slice(1).duplicate(true)
	state.hand.back().card_id = "starter-timber-plank"
	screen._render()
	market.tiles[0].grab_focus()
	expect(market.preview.visible and not market.tiles[0].disabled, "Unaffordable offer still focus-inspectable")
	var last: int = state.hand.size() - 1
	screen._begin_drag(screen.world.cards[last])
	expect(not market.preview.visible, "Hand drag dismisses market preview")
	screen._finish_drag(screen.world.slots[0])
	expect(state.gold == 8 and state.cells[0].construct != null, "Weak placement immediately earns three into shared wallet")
	var count: int = state.deck.size()
	market.tiles[0].pressed.emit()
	expect(state.gold == 0 and state.deck.size() == count + 1 and state.hand.back().card_id == "guide-beam" and state.reward_offers.slice(1) == other, "Tile click charges once and grants one copy while other offers remain")
	expect(not screen.world.cards[state.hand.size()-1]._effect.text.contains("Price") and screen.world.cards[state.hand.size()-1]._gold.text == "G 1", "Owned card shows placement Gold and hides acquisition price")
	state.gold = 100
	screen._render()
	market.tiles[0].pressed.emit()
	expect(state.deck.size() == count + 2, "Another purchase works without leaving the board")
	state.gold = 0
	screen._render()
	market._show_preview(0)
	var raised: WorldCard = screen.world.cards[state.hand.size() - 1]
	screen.picker._set_target(raised)
	await create_timer(0.25).timeout
	expect(raised._power.position.x < 0 and raised._gold.position.x > 0 and raised._power.position.y < -1.4 and raised._gold.position.y < -1.4 and raised._power.text.begins_with("I ") and raised._gold.text.begins_with("G "), "Integrity/Gold occupy distinct bottom corners")
	var contained: bool = market.preview.is_inside_tree()
	for index in range(market.tiles.size()):
		contained = contained and market._prices[index].get_global_rect().end.y <= market.tiles[index].get_global_rect().end.y and market._art[index].get_global_rect().end.y <= market.tiles[index].get_global_rect().end.y
	expect(contained, "Preview is attached and tile prices/art remain inside their bounds")
	expect(market.get_rect().end.y < screen.hud.size.y * 0.28, "Permanent market row stays above bridge and hand")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://references/card-corner-values-wide.png")
	market.hide_preview()
	root.size = Vector2i(1280, 720)
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://references/card-corner-values-small.png")
	var offers: Array = state.reward_offers.duplicate(true)
	state.integrity = 30
	state.intent = {"attackId":"reward-01-first-drizzle", "resolvedHitKeys":[], "resolved":false}
	screen.rules._update_attack()
	for index in range(1, 5):
		state.hand[0].card_id = "starter-timber-plank"
		screen._selected_id = state.hand[0].instance_id
		await screen._place(index)
	expect(state.round_number == 2 and state.phase == &"playing" and state.gold == 12 and not screen._rewards.visible and state.reward_offers == offers, "Round rain advances directly, preserves earned Gold and keeps offers")
	screen._open_pause()
	screen.hud.control("Restart").pressed.emit()
	expect(state != screen.rules.state and screen.rules.state.gold == 3 and screen.rules.state.round_number == 1, "Fresh run starts with 3 Gold")
	print("Market UI: one native case; failures=", failures)
	screen.queue_free()
	await process_frame
	quit(1 if failures else 0)
