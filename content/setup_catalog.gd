class_name SetupCatalog
extends RefCounted
## Validates only the data consumed by initial setup, not effect semantics.
## Definitions are read-only by convention; instances never modify them.

const FILES: Dictionary = {
	"cards": "integrity_cards.json",
	"config": "integrity_config.json",
	"forestAttacks": "integrity_forest_attacks.json",
	"wildlife": "integrity_wildlife.json",
}
const MAX_SAFE_INTEGER: int = 9007199254740991
const FIXED_CONFIG: Dictionary = {"handLimit": 12, "drawPerRound": 5, "rewardOfferCount": 4}

var wildlife: Dictionary = {}
var max_playable_pool: int = 1
var animals_enabled: bool = false
var errors: Array[String] = []
var cards: Dictionary[String, Dictionary] = {}
var attacks: Array[Dictionary] = []
var config: Dictionary = {}
var habitat_ids: Array[String] = []
var habitats: Dictionary[String, Dictionary] = {}
var initial_pool: Dictionary = {}


static func load_directory(directory: String = "res://content/data") -> SetupCatalog:
	var catalog := SetupCatalog.new()
	var data: Dictionary = {}
	for key: String in FILES:
		var path: String = directory.path_join(FILES[key])
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			catalog.errors.append("Cannot read %s: %s" % [path, error_string(FileAccess.get_open_error())])
			continue
		var json := JSON.new()
		if json.parse(file.get_as_text()) != OK:
			catalog.errors.append("%s:%d: %s" % [path, json.get_error_line(), json.get_error_message()])
			continue
		data[key] = json.data
	if catalog.errors.is_empty():
		catalog._validate(data)
	return catalog


static func from_data(data: Dictionary) -> SetupCatalog:
	var catalog := SetupCatalog.new()
	# Own the definitions; external edits must not invalidate the validated view.
	catalog._validate(data.duplicate(true))
	return catalog


func pool(pool_id: int) -> Dictionary:
	for definition: Dictionary in config.rewardPools:
		if definition.id == pool_id:
			return definition
	return {}


func _validate(data: Dictionary) -> void:
	if not data.get("config") is Dictionary or not data.get("wildlife") is Dictionary:
		errors.append("Setup requires config and wildlife objects.")
		return
	var card_index: Dictionary = _index(data.get("cards"), "Cards")
	var attack_index: Dictionary = _index(data.get("forestAttacks"), "Attacks")
	var habitat_index: Dictionary = _index(data.wildlife.get("habitats"), "Habitats")
	if not errors.is_empty():
		return
	wildlife = data.wildlife
	cards.assign(card_index)
	attacks.assign(data.forestAttacks)
	habitats.assign(habitat_index)
	for id: String in habitats:
		habitat_ids.append(id)
	for card: Dictionary in cards.values():
		if not is_safe_integer(card.get("baseIntegrity"), 0):
			errors.append("%s: baseIntegrity must be a nonnegative safe integer." % card.id)
		if card.has("placementGold") and not is_safe_integer(card.placementGold, 0): errors.append("%s: invalid placement Gold." % card.id)
		if card.has("purchasePrice") and not is_safe_integer(card.purchasePrice, 1): errors.append("%s: invalid market price." % card.id)
	for attack: Dictionary in attacks:
		var width: Variant = attack.get("boardSize", 5)
		if attack.get("category") != "forest" or not is_safe_integer(width, 1) or (width != 5 and width != 7):
			errors.append("%s: invalid category or board size." % attack.id)
		var requirements: Variant = attack.get("requires")
		if not requirements is Dictionary:
			errors.append("%s: requires must be an object." % attack.id)
		elif not is_safe_integer(requirements.get("wet"), 0) or not is_safe_integer(requirements.get("windy"), 0):
			errors.append("%s: weather requirements must be nonnegative safe integers." % attack.id)
	config = data.config
	for key: String in ["starterDeck", "rewardCardIds", "rewardPools", "rooms"]:
		if not config.get(key) is Array or config[key].is_empty():
			errors.append("Config needs a nonempty %s array." % key)
	for key: String in FIXED_CONFIG:
		if not is_safe_integer(config.get(key), 1) or config[key] != FIXED_CONFIG[key]:
			errors.append("Config requires %s = %d." % [key, FIXED_CONFIG[key]])
	for key: String in ["startingGold", "weatherCap", "paidDrawBaseCost", "paidDrawCostStep"]:
		var minimum: int = 1 if key.begins_with("paidDraw") else 0
		if (config.has(key) or key == "weatherCap") and not is_safe_integer(config.get(key), minimum):
			errors.append("Config: invalid %s." % key)
	if not is_safe_integer(config.get("openingHandSize", config.drawPerRound), 1) or int(config.get("openingHandSize", config.drawPerRound)) > int(config.handLimit):
		errors.append("Opening hand must fit the hand limit.")
	for id: String in config.get("rewardCardIds", []):
		if cards.has(id) and not is_safe_integer(cards[id].get("purchasePrice"), 1): errors.append("%s: market cards require a fixed price." % id)
	if not errors.is_empty():
		return
	_validate_references(attack_index)


func _validate_references(attack_index: Dictionary) -> void:
	var rewards: Dictionary = _references(config.rewardCardIds, cards, "Reward cards")
	var starters: Dictionary = {}
	for entry: Variant in config.starterDeck:
		if not entry is Dictionary:
			errors.append("Starter entries must be objects.")
			continue
		if not _text(entry.get("cardId")) or not cards.has(entry.cardId) or not is_safe_integer(entry.get("copies"), 1):
			errors.append("Starter entries need a known cardId and positive whole copies.")
			continue
		starters[entry.cardId] = true
		if rewards.has(entry.cardId):
			errors.append("Starter cards cannot be reward offers.")
	var rooms: Dictionary = _index(config.rooms, "Rooms")
	for room: Dictionary in rooms.values():
		if not is_safe_integer(room.get("requiredProgress"), 1):
			errors.append("%s: requiredProgress must be positive." % room.id)
	var pooled_cards: Dictionary = {}
	var pooled_attacks: Dictionary = {}
	var previous_id: int = -1
	for pool: Variant in config.rewardPools:
		if not pool is Dictionary:
			errors.append("Reward pools must be objects.")
			continue
		if not is_safe_integer(pool.get("id"), 0) or pool.id <= previous_id or not _text(pool.get("name")):
			errors.append("Reward pools need names and increasing integer IDs.")
			continue
		previous_id = int(pool.id)
		var pool_cards: Dictionary = _references(pool.get("cardIds"), cards, "Pool cards")
		var pool_attacks: Dictionary = _references(pool.get("attackIds"), attack_index, "Pool attacks")
		if pool.id == 0:
			if not pool_attacks.is_empty():
				errors.append("Pool 0 cannot have attacks.")
			for id: String in starters:
				if not pool_cards.has(id):
					errors.append("Pool 0 must contain all starters.")
			for id: String in pool_cards:
				if rewards.has(id):
					errors.append("Pool 0 cannot contain rewards.")
			continue
		for id: String in pool_cards:
			if not rewards.has(id) or pooled_cards.has(id):
				errors.append("Pool cards must be unique reward cards.")
			pooled_cards[id] = true
		var ungated: bool = false
		for id: String in pool_attacks:
			if pooled_attacks.has(id):
				errors.append("Attacks cannot belong to multiple pools.")
			pooled_attacks[id] = true
			var attack: Dictionary = attack_index[id]
			if int(attack.get("boardSize", 5)) != (7 if pool.id == 5 else 5):
				errors.append("Attack board size does not match its pool.")
			if attack.requires.wet == 0 and attack.requires.windy == 0:
				ungated = true
		if not pool_cards.is_empty():
			if pool_cards.size() <= int(config.rewardOfferCount) or not ungated:
				errors.append("Active pools need spare reward cards and an ungated attack.")
			if initial_pool.is_empty():
				initial_pool = pool
	for id: String in rewards:
		if not pooled_cards.has(id):
			errors.append("Reward card %s has no pool." % id)
	if initial_pool.is_empty():
		errors.append("No active reward pool.")


func _index(value: Variant, label: String) -> Dictionary:
	var result: Dictionary = {}
	if not value is Array or value.is_empty():
		errors.append("%s must be a nonempty array." % label)
		return result
	for entry: Variant in value:
		if not entry is Dictionary:
			errors.append("%s entries must be objects." % label)
			continue
		if not _text(entry.get("id")) or not _text(entry.get("name")) or result.has(entry.id):
			errors.append("%s entries need unique IDs and nonempty names." % label)
			continue
		result[entry.id] = entry
	return result


func _references(value: Variant, known: Dictionary, label: String) -> Dictionary:
	var result: Dictionary = {}
	if not value is Array:
		errors.append("%s must be an array." % label)
		return result
	for id: Variant in value:
		if not _text(id) or not known.has(id) or result.has(id):
			errors.append("%s must contain unique known IDs." % label)
			continue
		result[id] = true
	return result


static func _text(value: Variant) -> bool:
	return value is String and not value.is_empty()


static func is_safe_integer(value: Variant, minimum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) \
		and value >= minimum and value <= MAX_SAFE_INTEGER and floor(float(value)) == value
