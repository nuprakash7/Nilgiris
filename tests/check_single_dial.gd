extends SceneTree
## Two focused native cases: dial direction/settlement, market layout/input.
var screen: Node3D
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
	screen = load("res://presentation/main.tscn").instantiate()
	screen.feedback_duration = 0.04
	screen.round_rain_duration = 0.06
	root.add_child(screen)
	await create_timer(0.25).timeout
	if not "--layout-only" in OS.get_cmdline_user_args(): await direction_and_settlement()
	await market_layout()
	print("Single dial/top market: ", 1 if "--layout-only" in OS.get_cmdline_user_args() else 2, " native cases; failures=", failures)
	screen.queue_free()
	await process_frame
	quit(1 if failures else 0)
func direction_and_settlement() -> void:
	var state: RunState = screen.rules.state
	state.bridge_progress = 10
	state.integrity = 10
	screen._render()
	await create_timer(0.5).timeout
	var dial: IntegrityReadout = screen.hud.integrity
	expect(dial.value == 20 and dial.target == 250 and dial.round_value == 10, "One dial combines built and live values against actual target")
	state.integrity += 8
	screen._render()
	await create_timer(0.15).timeout
	var rising: float = dial.reading
	expect(rising > 20 and rising < 28, "Gain animates clockwise")
	state.integrity -= 12
	screen._render()
	await create_timer(0.15).timeout
	expect(dial.reading < rising and dial.value == 16, "Forest subtraction animates anticlockwise")
	# Same surviving amount changes ownership from round Integrity to Progress.
	await create_timer(0.4).timeout
	state.bridge_progress += state.integrity
	state.integrity = 0
	screen._render()
	expect(dial.value == 16 and dial.round_value == 0, "Round commitment neither drains nor double-counts dial")
	# Exercise actual final-slot resolution and automatic advancement.
	state.bridge_progress = 0
	state.integrity = 30
	state.intent = {"attackId":"reward-01-first-drizzle", "resolvedHitKeys":[], "resolved":false}
	screen.rules._update_attack()
	var initial_gold: int = state.gold
	for index in range(5):
		state.hand[0].card_id = "starter-timber-plank"
		screen._selected_id = state.hand[0].instance_id
		await screen._place(index)
	expect(state.round_number == 2 and state.phase == &"playing" and dial.value == 20 and dial.round_value == 0 and state.gold == initial_gold + 15, "Actual Forest hit/cleanup preserves correct meter and wallet")
func market_layout() -> void:
	var market: MarketStrip = screen.hud.market
	var offered := ["timber-plank", "pool-1-layered-support", "guide-beam", "centre-pier"]
	for index in range(4):
		screen.rules.state.reward_offers[index] = {"offerId":"display-%d" % index, "cardId":offered[index], "price":screen.rules.catalog.cards[offered[index]].purchasePrice}
	screen._render()
	expect(market is HBoxContainer and market.tiles.size() == 4 and screen.hud.get_node_or_null("ProgressRuler") == null, "Four full market cards replace ruler")
	expect(market.position.x > screen.hud.integrity.get_rect().end.x and market.get_rect().end.x < screen.hud._threat.position.x and market.get_rect().end.y < screen.hud.size.y * 0.28, "Top cards fit between dial/threat and above bridge")
	expect(not market._effects[0].text.is_empty() or market._values[0].text.begins_with("I "), "Card faces include effects and corner values")
	market._show_preview(0)
	expect(market.preview.visible and market.preview.position.y > market.get_rect().end.y, "Enlarged inspection opens below row")
	screen._begin_drag(screen.world.cards[0])
	expect(not market.preview.visible, "Hand dragging dismisses market inspection")
	screen._finish_drag(null)
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://references/single-dial-market-wide.png")
	root.size = Vector2i(1280, 720)
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://references/single-dial-market-small.png")
	expect(market.get_rect().end.x <= screen.hud.size.x and market.get_rect().end.y < screen.hud.size.y * 0.28, "Smaller window retains top-row framing")
	var other: Array = screen.rules.state.reward_offers.slice(1).duplicate(true)
	var owned: int = screen.rules.state.deck.size()
	screen.rules.state.gold = 100
	screen._render()
	market.tiles[0].pressed.emit()
	expect(screen.rules.state.deck.size() == owned + 1 and screen.rules.state.reward_offers.slice(1) == other, "Full-card market click still purchases exactly one and refills one slot")
