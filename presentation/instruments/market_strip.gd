class_name MarketStrip
extends HBoxContainer
## Four small full-card offers. Rules own prices, money and acquisition.
signal purchase_requested(offer_id: String)
@export var artwork: Dictionary[String, Texture2D] = {}
var tiles: Array[Button] = []
var _names: Array[Label] = []
var _prices: Array[Label] = []
var _art: Array[MarketArt] = []
var _offers: Array[Dictionary] = []
var _cards: Dictionary = {}
var _locked: bool = false
var _preview_index: int = -1
var preview: PanelContainer
var _preview_name: Label
var _preview_gold: Label
var _preview_values: Label
var _preview_text: Label
var _preview_price: Label
var _preview_art: MarketArt
var _faces: Array[Control] = []
var _effects: Array[Label] = []
var _values: Array[Label] = []
var _gold_values: Array[Label] = []
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 12)
	for index in range(4): _make_tile(index)
	preview = PanelContainer.new()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.z_index = 20
	get_parent().add_child.call_deferred(preview)
	preview.add_theme_stylebox_override("panel", _offer_frame(false))
	var face := Control.new()
	face.custom_minimum_size = Vector2(327, 532)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.add_child(face)
	var card := _card_backing(face, Vector2(315, 470))
	_preview_name = _label(card, "", 25)
	_preview_name.position = Vector2(20, 32)
	_preview_name.size = Vector2(275, 62)
	_preview_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_art = MarketArt.new()
	_preview_art.position = Vector2(22, 102)
	_preview_art.size = Vector2(271, 125)
	card.add_child(_preview_art)
	_preview_text = _label(card, "", 16)
	_preview_text.position = Vector2(22, 233)
	_preview_text.size = Vector2(271, 112)
	_preview_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_values = _label(card, "", 39)
	_preview_gold = _label(card, "", 39)
	_preview_values.position = Vector2(25, 398)
	_preview_gold.position = Vector2(210, 398)
	for label in [_preview_values, _preview_gold]:
		label.size = Vector2(80, 52)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(1, 0.97, 0.86))
	_preview_price = _label(face, "", 25)
	_preview_price.position = Vector2(6, 483)
	_preview_price.size = Vector2(315, 40)
	_preview_price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for label in [_preview_name, _preview_text]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_color_override("font_color", Color(0.16, 0.15, 0.13))
	preview.hide()
func _offer_frame(highlighted: bool) -> StyleBoxFlat:
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.055, 0.085, 0.075, 0.98)
	frame.border_color = Color(1, 0.83, 0.45) if highlighted else Color(0.67, 0.53, 0.29)
	frame.set_border_width_all(2)
	frame.set_corner_radius_all(5)
	frame.set_content_margin_all(0)
	return frame

func _card_backing(parent: Control, dimensions: Vector2) -> Control:
	var card := Control.new()
	card.position = Vector2(6, 6)
	card.size = dimensions
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(card)
	var backing := TextureRect.new()
	backing.texture = CardVisuals.FACE
	backing.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backing.size = dimensions
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(backing)
	return card

func _label(parent: Node, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", 0)
	parent.add_child(label)
	return label
func _make_tile(index: int) -> void:
	var tile := Button.new()
	tile.custom_minimum_size = Vector2(172, 292)
	for state: String in ["normal", "hover", "focus", "pressed", "disabled"]:
		tile.add_theme_stylebox_override(state, _offer_frame(state in ["hover", "focus", "pressed"]))
	add_child(tile)
	tiles.append(tile)
	var face := Control.new()
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.size = Vector2(172, 292)
	tile.add_child(face)
	_faces.append(face)
	var card := _card_backing(face, Vector2(160, 245))
	var title := _label(card, "", 16)
	title.position = Vector2(10, 16)
	title.size = Vector2(140, 39)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.max_lines_visible = 2
	title.clip_text = true
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_names.append(title)
	var art := MarketArt.new()
	art.position = Vector2(10, 57)
	art.size = Vector2(140, 72)
	card.add_child(art)
	_art.append(art)
	var price := _label(face, "", 23)
	price.position = Vector2(6, 254)
	price.size = Vector2(160, 32)
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prices.append(price)
	var effect := _label(card, "", 11)
	effect.position = Vector2(12, 132)
	effect.size = Vector2(136, 49)
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect.max_lines_visible = 4
	effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect.clip_text = true
	effect.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_effects.append(effect)
	var integrity_value := _label(card, "", 22)
	integrity_value.position = Vector2(13, 202)
	integrity_value.size = Vector2(40, 29)
	_values.append(integrity_value)
	var gold_value := _label(card, "", 22)
	gold_value.position = Vector2(107, 202)
	gold_value.size = Vector2(40, 29)
	gold_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	integrity_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_values.append(gold_value)
	for label in [title, effect]:
		label.add_theme_color_override("font_color", Color(0.17, 0.15, 0.1))
	for label in [integrity_value, gold_value]:
		label.add_theme_color_override("font_color", Color(1, 0.97, 0.86))
	price.add_theme_color_override("font_color", Color(1, 0.91, 0.65))
	tile.mouse_entered.connect(_show_preview.bind(index))
	tile.mouse_exited.connect(_leave.bind(index))
	tile.focus_entered.connect(_show_preview.bind(index))
	tile.focus_exited.connect(_leave.bind(index))
	tile.pressed.connect(func() -> void:
		if not _locked and index < _offers.size(): purchase_requested.emit(String(_offers[index].offerId)))

func fit_width(available: float) -> void:
	var width: float = minf(172, maxf(100, (available - 36) / 4))
	for index in range(tiles.size()):
		tiles[index].custom_minimum_size = Vector2(width, width * 292 / 172)
		_faces[index].scale = Vector2.ONE * width / 172
	size = Vector2(width * 4 + 36, width * 292 / 172)

func present(rules: RoundRules, locked: bool) -> void:
	_offers = rules.state.reward_offers
	_cards = rules.catalog.cards
	tooltip_text = "Market · Pool %d" % rules.state.construct_offer_pool_id
	set_interaction_locked(locked)
	for index in range(tiles.size()):
		var offer: Dictionary = _offers[index]
		var card: Dictionary = _cards[offer.cardId]
		_names[index].text = String(card.name).to_upper()
		_names[index].add_theme_font_size_override("font_size", 12 if String(card.name).length() > 19 else 14)
		_effects[index].text = CardText.compact(card)
		if _effects[index].text.is_empty(): _effects[index].text = "CONSTRUCT"
		_values[index].text = "%d" % card.baseIntegrity
		_gold_values[index].text = "%d" % int(card.get("placementGold", 0))
		_prices[index].text = "BUY  ◉ %d" % offer.price
		var affordable: bool = rules.state.gold >= int(offer.price)
		tiles[index].modulate = Color.WHITE if affordable else Color(0.88, 0.88, 0.86)
		_art[index].card_id = "%s %s" % [offer.cardId, String(card.name).to_lower()]
		_art[index].texture = artwork.get(offer.cardId)
		_art[index].queue_redraw()
		# Unaffordable/locked tiles still accept focus for inspection, never play.
		tiles[index].mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if affordable and not locked else Control.CURSOR_ARROW
	if _preview_index >= 0: _show_preview(_preview_index)
func set_interaction_locked(locked: bool) -> void:
	_locked = locked
	if locked: hide_preview()
func hide_preview() -> void:
	_preview_index = -1
	if preview != null: preview.hide()
func _leave(index: int) -> void:
	if _preview_index == index and not tiles[index].has_focus(): hide_preview()
func _show_preview(index: int) -> void:
	if _locked or index >= _offers.size(): return
	_preview_index = index
	var offer: Dictionary = _offers[index]
	var card: Dictionary = _cards[offer.cardId]
	_preview_name.text = String(card.name).to_upper()
	_preview_values.text = "%d" % card.baseIntegrity
	_preview_gold.text = "%d" % int(card.get("placementGold", 0))
	_preview_text.text = CardText.compact(card)
	_preview_price.text = "BUY  ◉ %d" % offer.price
	_preview_art.card_id = "%s %s" % [offer.cardId, String(card.name).to_lower()]
	_preview_art.texture = artwork.get(offer.cardId)
	_preview_art.queue_redraw()
	preview.size = Vector2(327, 532)
	preview.position = Vector2(clampf(tiles[index].global_position.x - 70, 12, get_parent_control().size.x - 339), minf(position.y + size.y + 12, get_parent_control().size.y - 544))
	preview.show()
