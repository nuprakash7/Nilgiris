class_name CommonWildlife
extends RefCounted
## Wildlife effect contract for all authored rarities. Historical class name is retained for existing development fixtures.
static func validate(content: Dictionary, habitat_ids: Array[String]) -> Array[String]:
	var errors: Array[String] = []
	var animals: Variant = content.get("animals")
	var weights: Variant = content.get("rarityWeights")
	if not animals is Array or animals.size() < 4 or not weights is Dictionary:
		return ["Wildlife requires animals and rarity weights."]
	var ids: Dictionary = {}
	for animal: Variant in animals:
		if not animal is Dictionary or not animal.get("id") is String or ids.has(animal.get("id")) or not animal.get("name") is String:
			errors.append("Invalid or duplicate animal.")
			continue
		ids[animal.id] = true
		if not RoundContent._only_keys(animal, ["id", "name", "rarity", "effect", "effectText", "cooldown", "oncePerRun", "habitatAffinities"]) or animal.id.is_empty() or animal.name.is_empty() or not animal.get("effectText") is String or animal.effectText.is_empty() or not animal.get("oncePerRun", false) is bool:
			errors.append("%s: invalid animal definition." % animal.id)
		if not animal.get("rarity") in ["common", "uncommon", "rare", "veryRare", "exceedinglyRare"] or not _effect(animal.get("effect")) or not SetupCatalog.is_safe_integer(animal.get("cooldown", 0), 0):
			errors.append("%s: unsupported animal rules." % animal.id)
		if not animal.get("habitatAffinities") is Dictionary:
			errors.append("%s: missing affinities." % animal.id)
		else:
			for id: Variant in animal.habitatAffinities:
				var value: Variant = animal.habitatAffinities[id]
				if not habitat_ids.has(id) or not (value is float or value is int) or not is_finite(float(value)) or value < 0:
					errors.append("%s: invalid affinity." % animal.id)
	for animal: Dictionary in animals:
		var weight: Variant = weights.get(animal.get("rarity", ""))
		if not (weight is float or weight is int) or not is_finite(float(weight)) or weight <= 0:
			errors.append("Invalid animal rarity weight.")
	if not errors.is_empty():
		return errors
	for a: String in habitat_ids:
		for b: String in habitat_ids:
			for c: String in habitat_ids:
				var eligible: int = 0
				for animal: Dictionary in animals:
					if float(animal.habitatAffinities.get(a, 0)) + float(animal.habitatAffinities.get(b, 0)) + float(animal.habitatAffinities.get(c, 0)) > 0:
						eligible += 1
				if eligible < 4:
					errors.append("Need four eligible animals for every habitat batch.")
	return errors

static func _effect(effect: Variant, depth: int = 0) -> bool:
	if not effect is Dictionary or depth > 3:
		return false
	var type: String = effect.get("type", "")
	if type == "sequence":
		if not RoundContent._only_keys(effect, ["type", "effects"]) or not effect.get("effects") is Array or effect.effects.is_empty() or effect.effects.size() > 8:
			return false
		for part: Variant in effect.effects:
			if not _effect(part, depth + 1):
				return false
		return true
	if type == "choose":
		if not RoundContent._only_keys(effect, ["type", "action", "count", "amount", "nextRoundPower", "drawAfter", "lookCount", "optional", "nextPlacementBonus", "unusedFlair", "nextPlacementMultiplier", "differentDefinitions", "satisfyNeighbors", "permanentMultiplier"]) or not effect.get("action") in ["handPower", "retain", "bounce", "look", "discard", "protect", "recover", "search", "discardDebris", "removeDebris"] or not SetupCatalog.is_safe_integer(effect.get("count"), 1) or effect.count > 12 or not effect.get("optional", false) is bool:
			return false
		for key: String in ["amount", "nextRoundPower", "drawAfter", "lookCount", "nextPlacementBonus"]:
			if effect.has(key) and not SetupCatalog.is_safe_integer(effect[key], 1):
				return false
		if effect.has("permanentMultiplier") and (effect.action != "handPower" or not _multiplier(effect.permanentMultiplier)): return false
		if effect.has("nextPlacementMultiplier") and (not effect.action in ["bounce", "handPower", "search"] or not _multiplier(effect.nextPlacementMultiplier)): return false
		if effect.has("differentDefinitions") and (effect.action != "search" or not effect.differentDefinitions is bool): return false
		if effect.has("satisfyNeighbors") and (effect.action != "handPower" or not effect.satisfyNeighbors is bool): return false
		if effect.has("amount") and effect.action != "handPower": return false
		if effect.has("nextRoundPower") and effect.action != "retain": return false
		if effect.has("drawAfter") and not effect.action in ["bounce", "discardDebris"]: return false
		if effect.has("unusedFlair") and (effect.action != "search" or not effect.unusedFlair is bool): return false
		if effect.has("nextPlacementBonus") and not effect.action in ["bounce", "handPower", "search"]: return false
		if effect.has("lookCount") and effect.action != "look": return false
		return (effect.action != "handPower" or SetupCatalog.is_safe_integer(effect.get("amount"), 1) or SetupCatalog.is_safe_integer(effect.get("nextPlacementBonus"), 1) or effect.get("satisfyNeighbors", false) or _multiplier(effect.get("nextPlacementMultiplier")) or _multiplier(effect.get("permanentMultiplier"))) and (effect.action != "look" or SetupCatalog.is_safe_integer(effect.get("lookCount"), int(effect.count)))
	if type == "placementBonus":
		return RoundContent._only_keys(effect, ["type", "amount", "count", "condition", "block", "escalating", "multiplier"]) and SetupCatalog.is_safe_integer(effect.get("amount"), 0) and (int(effect.amount) > 0 or SetupCatalog.is_safe_integer(effect.get("block"), 1) or _multiplier(effect.get("multiplier"))) and (not effect.has("multiplier") or _multiplier(effect.multiplier)) and (not effect.has("block") or SetupCatalog.is_safe_integer(effect.block, 1)) and effect.get("escalating", false) is bool and SetupCatalog.is_safe_integer(effect.get("count", 1), 1) and effect.get("condition", "") in ["", "endSlot", "centerSlot", "emptyNeighbors", "perNeighbor", "adjacentSlotOccupied"]
	if type == "hitProtection":
		return RoundContent._only_keys(effect, ["type", "amount", "count"]) and SetupCatalog.is_safe_integer(effect.get("amount"), 1) and SetupCatalog.is_safe_integer(effect.get("count", 1), 1)
	if type == "progress":
		return RoundContent._only_keys(effect, ["type", "percent", "requiresFullBoard"]) and SetupCatalog.is_safe_integer(effect.get("percent"), 1) and effect.get("requiresFullBoard", false) is bool
	if type == "preventDestruction": return RoundContent._only_keys(effect, ["type"])
	if type == "halfNextHit": return RoundContent._only_keys(effect, ["type", "amount"]) and (not effect.has("amount") or SetupCatalog.is_safe_integer(effect.amount, 1))
	if type == "grace":
		return RoundContent._only_keys(effect, ["type", "amount", "drawOnTrigger", "nextPlacementBonus"]) and SetupCatalog.is_safe_integer(effect.get("amount"), 1) and (not effect.has("drawOnTrigger") or SetupCatalog.is_safe_integer(effect.drawOnTrigger, 1)) and (not effect.has("nextPlacementBonus") or SetupCatalog.is_safe_integer(effect.nextPlacementBonus, 1))
	return type in ["grace", "sharedProtection", "halfNextHit", "integrity", "integrityPerOccupied", "draw", "gold", "reduceNextHit"] and RoundContent._only_keys(effect, ["type", "amount"]) and SetupCatalog.is_safe_integer(effect.get("amount"), 1)


static func _multiplier(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and value > 1
