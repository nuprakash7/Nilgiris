class_name InstrumentHud
extends Control
## Presentation and menus only. Signals submit actions to WorldScreen.
signal animal_requested(instance_id: String)
signal pause_requested
var ui: Dictionary[String, Control] = {}
var integrity: IntegrityReadout
var rain: RoundRain
var market: MarketStrip
var sequence: ForestSequence
var _round_stat: BrassPanel
var _gold_stat: BrassPanel
var _gold_symbol: InstrumentSymbol
var _threat: BrassPanel
var _animals: BoxContainer
var _piles: HBoxContainer
var _actions: VBoxContainer
var _inspect: PanelContainer
var _toast: Label
var _toast_motion: Tween
var _pause: Control
var _animal_signature: int = 0
var _phase_key: String = ""
const IVORY := Color(0.96, 0.92, 0.79)
const BRASS := Color(0.83, 0.68, 0.42)

func control(id: String) -> Control:
	return ui[id]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = _theme()
	rain = RoundRain.new()
	add_child(rain)
	move_child(rain, 0)
	_round_stat = _stat(self, "Round", "clock", "Round / deadline")
	_gold_stat = _stat(self, "Gold", "coin", "Gold · shared wallet for market purchases and paid draws")
	_gold_symbol = _gold_stat.get_child(0).get_child(0)
	ui.Gold.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui.Gold.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ui.Gold.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.Round.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.Round.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	integrity = IntegrityReadout.new()
	add_child(integrity)
	_threat = BrassPanel.new()
	_threat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_threat)
	var threat_contents := VBoxContainer.new()
	threat_contents.add_theme_constant_override("separation", 2)
	_threat.add_child(threat_contents)
	var heading := HBoxContainer.new()
	threat_contents.add_child(heading)
	_symbol(heading, "threat")
	var attack_label := _label(heading, "Attack", 17)
	attack_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	attack_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sequence = ForestSequence.new()
	threat_contents.add_child(sequence)
	sequence.detail_requested.connect(inspect)
	sequence.detail_closed.connect(inspect.bind("", ""))
	_label(threat_contents, "Hazards", 15)
	_animals = BoxContainer.new()
	add_child(_animals)
	_piles = HBoxContainer.new()
	add_child(_piles)
	_stat(_piles, "DrawPile", "draw", "Draw pile")
	_stat(_piles, "DiscardPile", "discard", "Discard pile")
	_actions = VBoxContainer.new()
	add_child(_actions)
	_button(_actions, "BuyDraw", "▱  ◉ 1", "Draw one card")
	var pause_button := _button(self, "Pause", "", "Pause / settings · Esc")
	var gear := InstrumentSymbol.new()
	gear.kind = "settings"
	gear.position = Vector2(9, 6)
	gear.size = Vector2(26, 26)
	pause_button.add_child(gear)
	pause_button.pressed.connect(pause_requested.emit)
	_toast = _label(self, "Prompt", 22)
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.visible = false
	ui["Feedback"] = _toast
	_inspect = PanelContainer.new()
	_inspect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_inspect)
	var contents := VBoxContainer.new()
	contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inspect.add_child(contents)
	_label(contents, "InspectTitle", 21)
	_label(contents, "InspectText", 19).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inspect.hide()
	market = $Market
	_build_pause()
	move_child($RewardPopup, get_child_count() - 1)
	move_child(_pause, get_child_count() - 1)
	resized.connect(_layout)
	_layout()

func _theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 22
	result.set_color("font_color", "Label", IVORY)
	result.set_color("font_outline_color", "Label", Color(0.04, 0.07, 0.06, 0.9))
	result.set_constant("outline_size", "Label", 4)
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.055, 0.075, 0.065, 0.91 if state == "normal" else 0.98)
		style.border_color = BRASS if state in ["hover", "focus", "pressed"] else Color(BRASS, 0.35)
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		style.content_margin_left = 9
		style.content_margin_right = 9
		style.content_margin_top = 5
		style.content_margin_bottom = 5
		result.set_stylebox(state, "Button", style)
	result.set_color("font_color", "Button", IVORY)
	result.set_color("font_hover_color", "Button", Color(1, 0.85, 0.5))
	result.set_color("font_disabled_color", "Button", Color(IVORY, 0.35))
	result.set_color("font_outline_color", "Button", Color(0.04, 0.07, 0.06, 0.9))
	result.set_constant("outline_size", "Button", 3)
	var local := StyleBoxFlat.new()
	local.bg_color = Color(0.06, 0.1, 0.09, 0.78)
	local.border_color = Color(BRASS, 0.65)
	local.border_width_top = 1
	local.border_width_bottom = 1
	local.content_margin_left = 16
	local.content_margin_right = 16
	local.content_margin_top = 12
	local.content_margin_bottom = 12
	result.set_stylebox("panel", "PanelContainer", local)
	result.set_stylebox("panel", "TooltipPanel", local)
	result.set_color("font_color", "TooltipLabel", IVORY)
	result.set_font_size("font_size", "TooltipLabel", 20)
	result.set_constant("separation", "HBoxContainer", 12)
	result.set_constant("separation", "VBoxContainer", 8)
	return result

func _label(parent: Node, id: String, font_size: int) -> Label:
	var label := Label.new()
	label.name = id
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	ui[id] = label
	return label

func _button(parent: Node, id: String, text: String, hint: String) -> Button:
	var button := Button.new()
	button.name = id
	button.text = text
	button.tooltip_text = hint
	button.custom_minimum_size = Vector2(44, 38)
	parent.add_child(button)
	ui[id] = button
	button.focus_entered.connect(func() -> void: inspect(button.text, button.tooltip_text))
	button.focus_exited.connect(inspect.bind("", ""))
	return button

func _symbol(parent: Node, kind: String) -> InstrumentSymbol:
	var symbol := InstrumentSymbol.new()
	symbol.kind = kind
	parent.add_child(symbol)
	return symbol

func _stat(parent: Node, id: String, kind: String, hint: String) -> BrassPanel:
	var housing := BrassPanel.new()
	parent.add_child(housing)
	var row := HBoxContainer.new()
	row.tooltip_text = hint
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	housing.add_child(row)
	_symbol(row, kind)
	_label(row, id, 24)
	return housing

func _layout() -> void:
	if integrity == null: return
	var narrow: bool = size.x < 1700
	_gold_stat.position = Vector2(size.x - (325 if narrow else 410), 18)
	_gold_stat.size = Vector2(245 if narrow else 300, 84 if narrow else 96)
	_gold_symbol.custom_minimum_size = Vector2(44 if narrow else 52, 44 if narrow else 52)
	_gold_symbol.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ui.Gold.add_theme_font_size_override("font_size", 48 if narrow else 58)
	var left: float = 210 if narrow else 300
	var reserve: float = 345 if narrow else 440
	var dial_size: float = 170 if narrow else 220
	integrity.position = Vector2(18 if narrow else 38, 12 if narrow else 18)
	integrity.size = Vector2(dial_size, dial_size)
	_round_stat.size = Vector2(146 if narrow else 166, 44)
	_round_stat.position = Vector2(integrity.position.x + (dial_size - _round_stat.size.x) * 0.5, integrity.position.y + dial_size + 10)
	_threat.position = Vector2(size.x - (325 if narrow else 410), 124 if narrow else 138)
	_threat.size.x = 305 if narrow else 380
	_animals.vertical = false
	_animals.position = Vector2(30, size.y - 225)
	_piles.position = Vector2(30, size.y - 150)
	_actions.position = Vector2(size.x - 205, size.y - 145)
	_actions.size.x = 175
	ui.Pause.position = Vector2(size.x - 65, 24)
	market.fit_width(maxf(400, size.x - left - reserve))
	market.position = Vector2(left + (size.x - left - reserve - market.size.x) * 0.5, 18)
	rain.size = size
	_toast.position = Vector2(size.x * 0.5 - 350, size.y * 0.716 - 60)
	_toast.size = Vector2(700, 65)
	if _pause != null: _pause.size = size

func present(rules: RoundRules, busy: bool, integrity_value: int, progress_value: int, progress_target: int, locked: bool) -> void:
	var state: RunState = rules.state
	market.present(rules, busy or locked or state.phase != &"playing")
	integrity.present(progress_value + integrity_value, progress_target, integrity_value)
	ui.Round.text = "%d/%d" % [state.round_number, state.round_limit]
	ui.Gold.text = str(state.gold)
	ui.DrawPile.text = str(state.draw_pile.size())
	ui.DiscardPile.text = str(state.discard_pile.size())
	ui.Attack.text = rules.attack_definition().name
	ui.Attack.tooltip_text = "%s · Wet %d / Wind %d" % [rules.attack_definition().name, state.weather.wet, state.weather.windy]
	ui.Attack.mouse_filter = Control.MOUSE_FILTER_STOP
	sequence.present(rules.attack_definition(), state.intent, state.cells, state.next_forest_damage_bonus)
	var hazards: PackedStringArray = []
	for penalty: Dictionary in rules.attack_definition().get("slotPenalties", []):
		hazards.append("S%d −%d%s" % [penalty.slotIndex + 1, penalty.amount, " ✓" if state.intent.get("usedSlotPenalties", []).has(int(penalty.slotIndex)) else ""])
	ui.Hazards.text = "  ".join(hazards)
	ui.Hazards.visible = not hazards.is_empty()
	var penalty_hints: PackedStringArray = []
	for penalty: Dictionary in rules.attack_definition().get("slotPenalties", []):
		penalty_hints.append("Physical slot %d: placement contributes %d less Integrity%s. This is not Forest damage." % [penalty.slotIndex + 1, penalty.amount, " on its first use" if penalty.get("once", false) else ""])
	ui.Hazards.tooltip_text = "\n".join(penalty_hints)
	ui.Hazards.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.BuyDraw.text = "▱  ◉ %d" % rules.purchased_draw_cost()
	ui.BuyDraw.disabled = busy or locked or not rules.purchase_draw_error().is_empty()
	ui.BuyDraw.tooltip_text = "Draw one card · %d Gold\n%s" % [rules.purchased_draw_cost(), rules.purchase_draw_error()]
	ui.Pause.disabled = busy
	ui.Restart.disabled = busy
	_set_animals(rules, busy or locked)
	var key: String = "%d:%s" % [state.round_number, state.phase]
	if not busy and key != _phase_key:
		_phase_key = key
		if state.phase == &"won": notify("Bridge complete · Run won\nPause to start a new run", 6)
		elif state.phase == &"lost": notify(state.loss_reason, 6)
		elif state.phase in [&"roundComplete", &"roomComplete"]: notify("+%d Progress · %d Gold saved" % [state.round_result.progress, state.gold], 4)

func _set_animals(rules: RoundRules, locked: bool) -> void:
	var entries: Array[Dictionary] = []
	for animal: Dictionary in rules.state.animals:
		var definition: Dictionary = rules.animals.definition(animal.animalId)
		var problem: String = rules.animals.use_error(animal.instanceId)
		var cooldown: int = maxi(0, int(animal.nextEligibleRound) - rules.state.round_number)
		entries.append({"id": animal.instanceId, "definition": definition, "problem": problem, "cooldown": cooldown})
	var signature: int = hash([entries, locked])
	if signature == _animal_signature: return
	_animal_signature = signature
	for child in _animals.get_children():
		_animals.remove_child(child)
		child.queue_free()
	for entry: Dictionary in entries:
		var button := Button.new()
		button.custom_minimum_size = Vector2(60, 66)
		button.text = "\n" + (str(entry.cooldown) if entry.cooldown > 0 else ("·" if entry.problem.is_empty() else "×"))
		button.disabled = locked or not entry.problem.is_empty()
		button.tooltip_text = "%s\n%s\n%s" % [entry.definition.name, entry.definition.effectText, "Ready" if entry.problem.is_empty() else entry.problem]
		var symbol := InstrumentSymbol.new()
		var effect: Dictionary = entry.definition.effect
		symbol.kind = effect.get("action", effect.type)
		symbol.position = Vector2(17, 4)
		symbol.size = Vector2(26, 26)
		button.add_child(symbol)
		button.focus_entered.connect(inspect.bind(String(entry.definition.name), button.tooltip_text))
		button.focus_exited.connect(inspect.bind("", ""))
		button.pressed.connect(animal_requested.emit.bind(String(entry.id)))
		_animals.add_child(button)

func notify(message: String, duration: float = 2.4) -> void:
	if message.is_empty(): return
	if _toast_motion != null: _toast_motion.kill()
	_toast.text = message
	_toast.modulate.a = 1
	_toast.show()
	_toast_motion = create_tween()
	_toast_motion.tween_interval(duration)
	_toast_motion.tween_property(_toast, "modulate:a", 0.0, 0.35)
	_toast_motion.tween_callback(_toast.hide)

func inspect(title: String, text: String) -> void:
	if _inspect == null: return
	if title.is_empty():
		_inspect.hide()
		return
	ui.InspectTitle.text = title
	ui.InspectText.text = text
	_inspect.size = Vector2(330, 0)
	var at: Vector2 = get_viewport().get_mouse_position() + Vector2(24, -100)
	_inspect.position = Vector2(clampf(at.x, 12, size.x - 350), clampf(at.y, 12, size.y - 220))
	_inspect.show()

func reset() -> void:
	_phase_key = ""
	integrity.reset()
	inspect("", "")

func _build_pause() -> void:
	_pause = Control.new()
	_pause.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_pause)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 0)
	center.add_child(panel)
	var list := VBoxContainer.new()
	panel.add_child(list)
	_label(list, "PauseTitle", 25).text = "PAUSE / SETTINGS"
	_button(list, "Resume", "Resume", "Return to the game").pressed.connect(set_paused.bind(false))
	_button(list, "WindowMode", "Toggle fullscreen", "Switch between fullscreen and maximized window").pressed.connect(_toggle_window)
	_button(list, "Restart", "New run", "Reset this run and return to the first reward")
	var menu_controls: Array[Control] = [ui.Resume, ui.WindowMode, ui.Restart]
	for index in range(menu_controls.size()):
		var button: Control = menu_controls[index]
		button.focus_next = menu_controls[(index + 1) % menu_controls.size()].get_path()
		button.focus_previous = menu_controls[(index + menu_controls.size() - 1) % menu_controls.size()].get_path()
		button.focus_neighbor_top = button.focus_previous
		button.focus_neighbor_bottom = button.focus_next
		button.focus_neighbor_left = button.get_path()
		button.focus_neighbor_right = button.get_path()
	_pause.hide()

func set_paused(value: bool) -> void:
	market.hide_preview()
	_pause.visible = value
	get_tree().paused = value
	inspect("", "")
	if value: ui.Resume.grab_focus()

func is_paused() -> bool:
	return _pause.visible

func _toggle_window() -> void:
	get_window().mode = Window.MODE_MAXIMIZED if get_window().mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN

func _unhandled_key_input(event: InputEvent) -> void:
	if _pause.visible and event.is_action_pressed("ui_cancel"):
		set_paused(false)
		get_viewport().set_input_as_handled()


func dismiss_notification() -> void:
	if _toast_motion != null: _toast_motion.kill()
	_toast.hide()
