extends Node3D
## World input -> existing rules -> view. No gameplay resolution in animation.

@export var pool_one_enabled: bool = true
@export_range(1, 5) var playable_pool: int = 5
@export var run_seed: int = 42
@export_range(0.0, 2.0) var feedback_duration: float = 0.8
@export_range(0.05, 2.0) var round_rain_duration: float = 0.65

var rules: RoundRules
var presentation_busy: bool = false
var _catalog: SetupCatalog
var _selected_id: String = ""
var _dragged_card: WorldCard
var _target_progress: int = 0
var _pending_impact: Dictionary = {}
var _display_integrity: int = -1
var _display_progress: int = -1

@onready var world: BridgeWorld = $World
@onready var picker: WorldPicker = $Picker
@onready var hud: InstrumentHud = $HUD/Hud
@onready var _rewards: ColorRect = hud.get_node("RewardPopup")
@onready var _prompt: Label = hud.control("Prompt")
@onready var _buy: Button = hud.control("BuyDraw")
@onready var _restart: Button = hud.control("Restart")


func _ready() -> void:
	_catalog = FullRun.create_catalog(SetupCatalog.load_directory()) if pool_one_enabled else EarlySlice.create_catalog(SetupCatalog.load_directory())
	_catalog.max_playable_pool = playable_pool if pool_one_enabled else 1
	if not _catalog.errors.is_empty():
		_prompt.text = "Content unavailable: " + " ".join(_catalog.errors)
		return
	for room: Dictionary in _catalog.config.rooms:
		_target_progress += int(room.requiredProgress)
	picker.camera = world.camera
	picker.hand_cards = world.cards
	picker.target_changed.connect(_hover_target)
	picker.target_pressed.connect(_press_target)
	picker.drag_started.connect(_begin_drag)
	picker.drag_moved.connect(_move_drag)
	picker.drag_finished.connect(_finish_drag)
	world.impact_reached.connect(_show_impact)
	_buy.pressed.connect(_buy_draw)
	_restart.pressed.connect(_restart_from_pause)
	hud.market.purchase_requested.connect(_buy_market)
	hud.animal_requested.connect(_activate_animal)
	hud.pause_requested.connect(_open_pause)
	_rewards.chosen.connect(_choose_reward)
	_start_slice()


func _start_slice() -> void:
	if presentation_busy or picker.dragging:
		return
	picker.clear_target()
	rules = RoundRules.new(_catalog, RunSetup.create(_catalog, run_seed))
	if not rules.errors.is_empty():
		_prompt.text = "Round unavailable: " + " ".join(rules.errors)
		return
	hud.reset()
	_selected_id = ""
	hud.notify("Place Constructs to earn Gold. Buy from the market or save for later rounds.")
	_render()


func _unhandled_input(event: InputEvent) -> void:
	if presentation_busy or not event.is_action_pressed("ui_cancel"): return
	if not rules.state.pending_choice.is_empty() and rules.state.pending_choice.optional:
		_choose_reward("")
	elif not _selected_id.is_empty():
		_selected_id = ""
		picker.clear_target()
		_render()
	else:
		_open_pause()


func _open_pause() -> void:
	if presentation_busy or picker.dragging: return
	hud.set_paused(true)


func _restart_from_pause() -> void:
	hud.set_paused(false)
	_start_slice()


func _activate_animal(instance_id: String) -> void:
	if presentation_busy or picker.dragging: return
	var problem: String = rules.activate_animal(instance_id)
	hud.notify(problem if not problem.is_empty() else rules.state.log.back())
	_render()


func _press_target(target: Area3D) -> void:
	if presentation_busy or rules == null or _rewards.visible:
		return
	if target is WorldCard:
		if not target.enabled:
			return
		var id: String = target.action_id
		picker.clear_target()
		_selected_id = "" if _selected_id == id else id
		_render()
	elif target is BridgeSlot:
		if rules.state.phase != &"playing":
			hud.notify("Choose a Construct reward in the popup first." if rules.state.phase == &"roundChoice" else "The run has ended. Open settings to start a new run.")
			return
		if target.occupied:
			if _selected_id.is_empty():
				_activate_flair(target.slot_index)
			else:
				hud.notify("That slot is occupied. Click the selected card again or press Escape to inspect its Flair.")
		else:
			_place(target.slot_index)


func _begin_drag(card: WorldCard) -> void:
	hud.market.set_interaction_locked(true)
	_dragged_card = card
	_selected_id = card.action_id
	for view: WorldCard in world.cards:
		view.set_selected(view == card)
	_update_slot_captions()


func _move_drag(screen_position: Vector2) -> void:
	if _dragged_card != null:
		_dragged_card.move_drag_visual(world.camera, screen_position)


func _finish_drag(slot: BridgeSlot) -> void:
	if _dragged_card == null:
		return
	_dragged_card.reset_drag_visual()
	_dragged_card = null
	if slot != null and not slot.occupied and not presentation_busy and rules.state.phase == &"playing":
		_place(slot.slot_index)
	else:
		_selected_id = ""
		picker.clear_target()
		hud.notify("Card returned to hand. Drop onto an empty bridge slot.")
		_render()


func _choose_reward(offer_id: String) -> void:
	if presentation_busy:
		return
	var previous_phase: StringName = rules.state.phase
	var previous_integrity: int = rules.state.integrity
	var previous_progress: int = rules.total_progress()
	var previous_impact: int = rules.state.forest_impact_sequence
	var problem: String = ""
	if not rules.state.pending_animal.is_empty():
		problem = rules.resolve_animal_acquisition(offer_id)
	elif not rules.state.pending_choice.is_empty():
		problem = rules.resolve_choice(offer_id)
	elif rules.state.reward_round_type == &"animal":
		problem = rules.choose_animal_reward(offer_id)
	else:
		problem = "No reward choice is active."
	hud.notify(problem if not problem.is_empty() else rules.state.log.back())
	if problem.is_empty() and previous_phase in [&"playing", &"roundChoice"] and rules.state.phase in [&"roundComplete", &"roomComplete", &"won", &"lost"]:
		await _play_settled_feedback(previous_integrity, previous_progress, previous_impact)
	else:
		_render()
		if problem.is_empty(): _advance_if_ready()


func _render_modal(choosing: bool) -> void:
	var state: RunState = rules.state
	var entries: Array[Dictionary] = []
	if not state.pending_animal.is_empty():
		for animal: Dictionary in state.animals:
			entries.append({"id": animal.instanceId, "text": "Replace %s\n%s" % [rules.animals.definition(animal.animalId).name, rules.animals.definition(animal.animalId).effectText]})
		entries.append({"id": "", "text": "Decline newcomer"})
		_rewards.show_entries(entries, "ANIMAL CAPACITY FULL", "New sighting: %s. Replace one owned copy or decline." % rules.animals.definition(state.pending_animal.animalId).name)
	elif not state.pending_choice.is_empty():
		for id: String in state.pending_choice.ids:
			var card: CardInstance = CardZones.find_live(state, id)
			var location: String = "Hand card %d" % (state.hand.find(card) + 1)
			if card is PlacedConstruct:
				for cell: Dictionary in state.cells:
					if cell.construct == card: location = "Slot %d" % (cell.slotIndex + 1)
			elif state.draw_pile.has(card):
				location = "Deck card %d" % (state.draw_pile.find(card) + 1)
			elif state.discard_pile.has(card):
				location = "Discard card %d" % (state.discard_pile.find(card) + 1)
			entries.append({"id": id, "text": "%s\n%s · Power %d%s" % [_catalog.cards[card.card_id].name, location, rules.card_power(card), (" · Selected" if state.pending_choice.get("selected", []).has(id) else "") + (" · Flair spent" if card.flair_spent else "")]})
		if state.pending_choice.get("kind", "") == "construct" and state.pending_choice.effect.type == "bounce":
			var source: PlacedConstruct = state.cells[state.construct_resolution.slot].construct
			if not source.flair_spent and _catalog.cards[source.card_id].get("flair", {}).get("type", "") == "bounce" and state.pending_choice.ids.size() >= 2 and state.hand.size() <= int(_catalog.config.handLimit) - 2:
				entries.append({"id": "toggle-flair", "text": "Flair: Bounce two · %s" % ("ON" if state.pending_choice.flairMode else "OFF")})
			if state.pending_choice.get("flairMode", false):
				entries.append({"id": "confirm-flair", "text": "Confirm two bounces", "disabled": state.pending_choice.selected.size() != 2})
		if state.pending_choice.optional:
			entries.append({"id": "", "text": "Done"})
		_rewards.show_entries(entries, state.pending_choice.title.to_upper(), "%d selection(s) remaining" % state.pending_choice.remaining)
	elif choosing and state.reward_round_type == &"animal":
		_rewards.show_offers(state.animal_offers, _catalog, true)
	else:
		_rewards.hide()


func _place(index: int) -> void:
	if _selected_id.is_empty():
		hud.notify("Select a card from your hand, then click an empty bridge slot.")
		return
	var card: CardInstance = CardZones.find_live(rules.state, _selected_id)
	var definition: Dictionary = _catalog.cards[card.card_id]
	var gain: int = rules.contribution(_selected_id, index)
	var previous_integrity: int = rules.state.integrity
	var previous_progress: int = rules.total_progress()
	var previous_impact: int = rules.state.forest_impact_sequence
	var problem: String = rules.play_card(_selected_id, index)
	if not problem.is_empty():
		hud.notify(problem)
		return
	_selected_id = ""
	picker.clear_target()
	# The model may already have cleared its board. Show the actual last placement
	# first, then reconcile to the settled model after visual-only feedback.
	world.slots[index].show_placement(card, definition, gain)
	hud.notify("%s placed · +%d Integrity." % [definition.name, gain])
	if rules.state.phase != &"playing" or rules.state.forest_impact_sequence > previous_impact:
		await _play_settled_feedback(previous_integrity + gain, previous_progress, previous_impact)
	else:
		_render()
		_update_slot_captions()


func _play_settled_feedback(integrity: int, progress: int, impact_sequence: int) -> void:
	presentation_busy = true
	_display_integrity = integrity
	_display_progress = progress
	_pending_impact = rules.state.forest_impacts.back().duplicate() if rules.state.forest_impact_sequence > impact_sequence else {}
	if not _pending_impact.is_empty(): _display_integrity = int(_pending_impact.before)
	_rewards.hide()
	_render(false)
	if rules.state.phase in [&"roundComplete", &"roomComplete", &"won"]:
		hud.rain.start(round_rain_duration)
	await world.play_end_feedback(feedback_duration, not _pending_impact.is_empty())
	if hud.rain.active: await hud.rain.finished
	presentation_busy = false
	_display_integrity = -1
	_display_progress = -1
	_pending_impact.clear()
	hud.notify(rules.state.loss_reason if rules.state.phase == &"lost" else rules.state.log.back())
	_render()
	_advance_if_ready()


func _show_impact() -> void:
	if _pending_impact.is_empty():
		return
	_display_integrity = int(_pending_impact.after)
	hud.notify("%s · %d damage%s" % [_pending_impact.attackName, _pending_impact.damage, " · crossing lost" if _pending_impact.fatal else ""])
	_render(false)
	hud.integrity.pulse(-int(_pending_impact.damage))


func _buy_market(offer_id: String) -> void:
	if presentation_busy or picker.dragging or hud.is_paused(): return
	hud.market.hide_preview()
	var problem: String = rules.purchase_market(offer_id)
	hud.notify(problem if not problem.is_empty() else rules.state.log.back())
	_render()


func _buy_draw() -> void:
	if presentation_busy or picker.dragging:
		return
	picker.clear_target()
	var problem: String = rules.purchase_draw()
	hud.notify(problem if not problem.is_empty() else rules.state.log.back())
	_render()


func _activate_flair(index: int) -> void:
	var placed: PlacedConstruct = rules.state.cells[index].construct
	if placed == null:
		return
	picker.clear_target()
	var problem: String = rules.activate_flair(placed.instance_id)
	hud.notify(problem if not problem.is_empty() else "Flair spent for this exact copy.")
	_render()


func _advance_if_ready() -> void:
	if presentation_busy or not rules.state.phase in [&"roundComplete", &"roomComplete"]: return
	if not rules.state.pending_animal.is_empty() or not rules.state.pending_choice.is_empty(): return
	var problem: String = rules.next_round_error()
	if not problem.is_empty():
		hud.notify(problem)
		return
	picker.clear_target()
	problem = rules.start_next_round()
	if not problem.is_empty():
		hud.notify(problem)
		return
	_selected_id = ""
	_render()


func _render(sync_board: bool = true) -> void:
	var state: RunState = rules.state
	world.configure_slots(state.cells.size())
	world.get_node("ForestBackdrop").enter_room(state.room_index, run_seed, state.round_number)
	var choosing: bool = state.phase == &"roundChoice"
	var playing: bool = state.phase == &"playing"
	var integrity: int = _display_integrity if _display_integrity >= 0 else (0 if state.phase == &"lost" else state.integrity)
	var progress: int = _display_progress if _display_progress >= 0 else rules.total_progress()
	var modal_locked: bool = choosing or not state.pending_choice.is_empty() or not state.pending_animal.is_empty()
	hud.present(rules, presentation_busy, integrity, progress, _target_progress, modal_locked)
	if presentation_busy: _rewards.hide()
	else: _render_modal(choosing)
	var count: int = state.hand.size()
	world.arrange_cards(count)
	for index in range(count):
		var view: WorldCard = world.cards[index]
		var card: CardInstance = state.hand[index]
		var detail: String = "CONSTRUCT"
		if state.placement_gold_paid.has(card.instance_id):
			detail += " · GOLD PAID THIS ROUND"
		if card.permanent_power_bonus > 0:
			detail += " · PERMANENT +%d" % card.permanent_power_bonus
		if card.zero_integrity_this_round:
			detail += " · ADDS ZERO THIS ROUND"
		if card.permanent_integrity_multiplier > 1.0:
			detail += " · RUN MULTIPLIER ×%s" % str(card.permanent_integrity_multiplier)
		if card.next_placement_multiplier > 1.0:
			detail += " · NEXT PLACEMENT ×%s" % str(card.next_placement_multiplier)
		if card.weakness > 0:
			detail += " · WEAKENED −%d" % card.weakness
		if card.next_placement_bonus > 0:
			detail += " · NEXT PLACEMENT +%d" % card.next_placement_bonus
		if card.power_bonus > 0:
			detail += " · POWER +%d" % card.power_bonus
		if card.retain_next_round:
			detail += " · RETAIN"
		if _catalog.cards[card.card_id].has("flair"):
			detail += " · FLAIR SPENT" if card.flair_spent else " · FLAIR READY"
		view.present(_catalog.cards[card.card_id], detail, card.instance_id, WorldCard.Role.HAND, playing and not presentation_busy)
		view.set_power(rules.hand_power(card.instance_id))
		view.set_placement_gold(int(_catalog.cards[card.card_id].get("placementGold", 0)), state.placement_gold_paid.has(card.instance_id))
		view.set_selected(view.action_id == _selected_id)
	if sync_board:
		for index in range(world.slots.size()):
			var placed: PlacedConstruct = state.cells[index].construct
			world.slots[index].present(placed, _catalog.cards[placed.card_id].name if placed != null else "", placed != null and rules.flair_error(placed.instance_id).is_empty())
	_update_slot_captions()
	_hover_target(null)


func _update_slot_captions() -> void:
	for slot: BridgeSlot in world.slots:
		if not slot.occupied:
			var gain: int = rules.contribution(_selected_id, slot.slot_index) if not _selected_id.is_empty() else -1
			slot.preview(gain, picker.target == slot and gain >= 0 and not presentation_busy)


func _hover_target(target: Area3D) -> void:
	_update_slot_captions()
	if presentation_busy or picker.dragging or _rewards.visible or hud.is_paused():
		hud.inspect("", "")
		return
	if target is WorldCard:
		hud.market.hide_preview()
		hud.dismiss_notification()
		hud.inspect("", "")
	elif target is BridgeSlot:
		if target.occupied:
			var placed: PlacedConstruct = rules.state.cells[target.slot_index].construct
			hud.inspect(_catalog.cards[placed.card_id].name, "Added %d Integrity · Live power %d\n%s" % [placed.integrity_added, placed.power, "Click for Flair" if target.flair_available else "No available Flair on this copy"])
		else:
			hud.inspect("Slot %d" % (target.slot_index + 1), "Drop a card here" if _selected_id.is_empty() else "Click to place the selected card")
	else:
		hud.inspect("", "")
