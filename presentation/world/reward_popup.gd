extends ColorRect
## Reusable modal for rewards, animal targeting and capacity; no rule resolution.
signal chosen(offer_id: String)
var _signature: int = 0
var _entry_height: int = 130

func _ready() -> void:
	color = Color(0.03, 0.06, 0.05, 0.2)
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color(0.92, 0.89, 0.79, 0.96)
	paper.border_color = Color(0.6, 0.46, 0.25)
	paper.set_border_width_all(1)
	paper.content_margin_left = 22
	paper.content_margin_right = 22
	paper.content_margin_top = 20
	paper.content_margin_bottom = 20
	$Center/Panel.add_theme_stylebox_override("panel", paper)
	for label: Label in [$Center/Panel/Content/Title, $Center/Panel/Content/Hint]:
		label.add_theme_color_override("font_color", Color(0.12, 0.18, 0.16))
		label.add_theme_constant_override("outline_size", 0)
	resized.connect(_layout)

func _layout() -> void:
	var available: float = minf(1250, size.x - 100)
	var columns: int = 3 if options.get_child_count() > 6 and available > 1050 else (2 if available > 680 else 1)
	options.columns = columns
	$Center/Panel/Content/Scroll.custom_minimum_size = Vector2(available, minf(580, size.y - 220))
	for button: Button in options.get_children():
		button.custom_minimum_size = Vector2((available - 20 * (columns - 1)) / columns, _entry_height)

@onready var options: GridContainer = $Center/Panel/Content/Scroll/Options

func show_offers(offers: Array, catalog: SetupCatalog, animal_round: bool = false) -> void:
	var entries: Array[Dictionary] = []
	for offer: Dictionary in offers:
		if animal_round:
			var animal: Dictionary = {}
			for definition: Dictionary in catalog.wildlife.animals:
				if definition.id == offer.animalId:
					animal = definition
			entries.append({"id": offer.offerId, "text": "%s\n\n%s\n\nCooldown %d" % [animal.name + " · " + String(animal.rarity).capitalize(), animal.effectText, animal.get("cooldown", 0)]})
		else:
			var card: Dictionary = catalog.cards[offer.cardId]
			entries.append({"id": offer.offerId, "text": "%s\n\n%d INTEGRITY\n%s\n\n%s" % [card.name, card.baseIntegrity, CardText.compact(card), catalog.habitats[offer.habitatId].name]})
	show_entries(entries, "CHOOSE AN ANIMAL" if animal_round else "CHOOSE A CONSTRUCT REWARD", "Survive every Forest hit to earn your chosen animal." if animal_round else "Survive the Forest to keep your chosen card.", 240)

func show_entries(entries: Array[Dictionary], heading: String, hint: String, entry_height: int = 130) -> void:
	var signature: int = hash([entries, heading, hint])
	if visible and signature == _signature:
		return
	_signature = signature
	for child in options.get_children():
		options.remove_child(child)
		child.queue_free()
	_entry_height = entry_height
	$Center/Panel/Content/Scroll.scroll_vertical = 0
	$Center/Panel/Content/Title.text = heading
	$Center/Panel/Content/Hint.text = hint
	for entry: Dictionary in entries:
		var button := Button.new()
		button.custom_minimum_size = Vector2(360, entry_height)
		button.add_theme_color_override("font_color", Color(0.12, 0.18, 0.16))
		button.add_theme_color_override("font_hover_color", Color(0.2, 0.3, 0.24))
		button.add_theme_constant_override("outline_size", 0)
		button.text = entry.text
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.disabled = entry.get("disabled", false)
		button.tooltip_text = entry.get("hint", "")
		button.pressed.connect(chosen.emit.bind(String(entry.id)))
		options.add_child(button)
	_layout()
	show()
	for child: Button in options.get_children():
		if not child.disabled:
			child.grab_focus()
			break
