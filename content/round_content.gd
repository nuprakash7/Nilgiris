class_name RoundContent
extends RefCounted
## The playable slice's rule contract, separate from setup and action resolution.

const CARD_FIELDS: Array[String] = [
	"id", "name", "flavorText", "number", "effectText", "baseIntegrity", "positionEffect", "integrityFormula", "flair", "draw", "effects", "reinforce", "placementGold", "purchasePrice", "cantBounce", "placementGoldBonus",
]
const ATTACK_FIELDS: Array[String] = [
	"id", "name", "arc", "category", "boardSize", "hits", "requires", "weatherDelta", "slotPenalties", "placementPenalties", "midRoundEffects",
]


static func validate(catalog: SetupCatalog) -> Array[String]:
	var problems: Array[String] = catalog.errors.duplicate()
	if not problems.is_empty():
		return problems
	var playable: Dictionary = {}
	if catalog.cards.has("debris"): playable["debris"] = true
	for entry: Dictionary in catalog.config.starterDeck:
		playable[entry.cardId] = true
	for pool: Dictionary in catalog.config.rewardPools:
		if int(pool.id) > catalog.max_playable_pool or int(pool.id) < 1: continue
		for id: String in pool.cardIds:
			playable[id] = true
	for id: String in playable:
		var card: Dictionary = catalog.cards[id]
		if not _only_keys(card, CARD_FIELDS):
			problems.append("%s: unsupported card mechanics." % id)
		if card.has("cantBounce") and not card.cantBounce is bool: problems.append("%s: invalid Bounce immunity." % id)
		if card.has("placementGoldBonus"):
			var bonus: Variant = card.placementGoldBonus
			if not bonus is Dictionary or not _only_keys(bonus, ["minimumOther", "amount"]) or not SetupCatalog.is_safe_integer(bonus.get("minimumOther"), 1) or not SetupCatalog.is_safe_integer(bonus.get("amount"), 1): problems.append("%s: invalid placement Gold bonus." % id)
		if card.has("reinforce") and not SetupCatalog.is_safe_integer(card.reinforce, 1): problems.append("%s: invalid Reinforce." % id)
		if card.has("positionEffect"):
			var effect: Variant = card.positionEffect
			if not effect is Dictionary or not _only_keys(effect, ["condition", "params", "integrityBonus", "supportedIntegrityBonus"]):
				problems.append("%s: invalid positional effect." % id)
			elif not effect.get("condition") in ["adjacentReinforce", "evenSlot", "perAdjacentSlotOccupied", "leftOccupied", "rightOccupied", "emptyNeighbors", "firstPlayedThisRound", "centerSlot", "lastEmptySlot", "lastPlacementThisRound", "endSlot", "bothNeighborsOccupied", "nthConstructPlacedThisRound"] \
					or not effect.get("params") is Dictionary or not (effect.params.is_empty() or (effect.condition == "nthConstructPlacedThisRound" and _only_keys(effect.params, ["n"]) and SetupCatalog.is_safe_integer(effect.params.get("n"), 1))) \
					or not SetupCatalog.is_safe_integer(effect.get("integrityBonus"), 0):
				problems.append("%s: unsupported positional effect." % id)
			if effect is Dictionary and effect.has("supportedIntegrityBonus") and not SetupCatalog.is_safe_integer(effect.supportedIntegrityBonus, 1): problems.append("%s: invalid supported positional bonus." % id)
		if card.has("integrityFormula"):
			var formula: Variant = card.integrityFormula
			if not formula is Dictionary or not _only_keys(formula, ["type", "amount"]) or not formula.get("type") in ["priorConstructs", "adjacentReinforce", "adjacentChain"] or not SetupCatalog.is_safe_integer(formula.get("amount"), 1):
				problems.append("%s: unsupported formula." % id)
		if card.has("draw"):
			var draw: Variant = card.draw
			if not draw is Dictionary or not _only_keys(draw, ["trigger", "amount", "params"]) \
					or not draw.get("trigger") in ["onPlacement", "anotherSupportedThisRound", "supportUsedThisRound", "adjacentReinforce"] or not SetupCatalog.is_safe_integer(draw.get("amount"), 1) \
					or not draw.get("params", {}) is Dictionary or not draw.get("params", {}).is_empty():
				problems.append("%s: unsupported Draw." % id)
		if card.has("flair"):
			var flair: Variant = card.flair
			if not flair is Dictionary or not _only_keys(flair, ["type", "amount", "count"]) \
					or not flair.get("type") in ["integrity", "draw", "gold", "bounce", "supportAll", "permanentIntegrity", "randomHandIntegrity", "drawPerNeighbor", "discardDraw", "recoverLast"] or (flair.get("type") != "randomHandIntegrity" and not SetupCatalog.is_safe_integer(flair.get("amount", flair.get("count")), 1)):
				problems.append("%s: unsupported Flair." % id)
		var effects: Variant = card.get("effects", [])
		if not effects is Array:
			problems.append("%s: effects must be an array." % id)
		else:
			for effect: Variant in effects:
				if not effect is Dictionary or not _only_keys(effect, ["type", "amount", "target", "reinforceAmount", "count", "drawOnBounce", "replayedAmount", "placementBonus", "bouncedAmount", "supportedAmount"]) \
						or not effect.get("type") in ["gold", "nextAdjacentIntegrity", "nextAdjacentPermanent", "nextForestDamage", "support", "bounce"] or not SetupCatalog.is_safe_integer(effect.get("amount", effect.get("count")), 1):
					problems.append("%s: unsupported normal effect." % id)
				elif effect.type in ["support", "bounce"] and not effect.get("target") in ["adjacent", "adjacentOne", "adjacentAll", "lowest", "any", "playedTwice", "left", "edge"]:
					problems.append("%s: unsupported target." % id)
				if effect is Dictionary:
					for key: String in ["reinforceAmount", "replayedAmount", "drawOnBounce", "bouncedAmount", "supportedAmount"]:
						if effect.has(key) and not SetupCatalog.is_safe_integer(effect[key], 1): problems.append("%s: invalid effect amount." % id)
					if effect.has("placementBonus"):
						var bonus: Variant = effect.placementBonus
						if not bonus is Dictionary or not _only_keys(bonus, ["count", "amount"]) or not SetupCatalog.is_safe_integer(bonus.get("count"), 1) or not SetupCatalog.is_safe_integer(bonus.get("amount"), 1): problems.append("%s: invalid placement Support bonus." % id)
	for attack: Dictionary in catalog.attacks:
		if not catalog.config.rewardPools.any(func(pool: Dictionary) -> bool: return int(pool.id) >= 1 and int(pool.id) <= catalog.max_playable_pool and pool.attackIds.has(attack.id)):
			continue
		if not _only_keys(attack, ATTACK_FIELDS) or not int(attack.get("boardSize", 5)) in [5, 7]:
			problems.append("%s: unsupported Forest mechanics." % attack.id)
		for field: String in ["slotPenalties", "placementPenalties"]:
			var penalties: Variant = attack.get(field, [])
			if not penalties is Array:
				problems.append("%s: invalid penalties." % attack.id)
				continue
			for penalty: Variant in penalties:
				var key: String = "slotIndex" if field == "slotPenalties" else "count"
				if not penalty is Dictionary or not _only_keys(penalty, [key, "amount", "once"]) or not SetupCatalog.is_safe_integer(penalty.get(key), 0 if key == "slotIndex" else 1) or not SetupCatalog.is_safe_integer(penalty.get("amount"), 1):
					problems.append("%s: invalid penalty." % attack.id)
		var hits: Variant = attack.get("hits")
		if not hits is Array or hits.is_empty():
			problems.append("%s: expected hits." % attack.id)
			continue
		for hit: Variant in hits:
			if not hit is Dictionary or not _only_keys(hit, ["damage", "when", "conditionalReduction"]) or not SetupCatalog.is_safe_integer(hit.get("damage"), 0) or not hit.get("when") is Dictionary:
				problems.append("%s: unsupported hit." % attack.id)
				continue
			if hit.when != {"type": "fullBoard"} and not (hit.when.get("type") == "slotCount" and _only_keys(hit.when, ["type", "count"]) and SetupCatalog.is_safe_integer(hit.when.get("count"), 1)):
				problems.append("%s: unsupported hit timing." % attack.id)
			if hit.has("conditionalReduction"):
				var reduction: Variant = hit.conditionalReduction
				if not reduction is Dictionary or not _only_keys(reduction, ["type", "minimum", "amount"]) or not reduction.get("type") in ["centerContributionAtLeast", "endContributionsAtLeast", "supportUsed", "reinforcePlayed", "copyReplayed", "endPowerAtLeast"] or not SetupCatalog.is_safe_integer(reduction.get("minimum", 0), 0) or not SetupCatalog.is_safe_integer(reduction.get("amount"), 0):
					problems.append("%s: unsupported hit reduction." % attack.id)
		for event: Variant in attack.get("midRoundEffects", []):
			if not _forest_event(event, int(attack.get("boardSize", 5))): problems.append("%s: unsupported mid-round event." % attack.id)
		var delta: Variant = attack.get("weatherDelta")
		if not delta is Dictionary or not _only_keys(delta, ["wet", "windy"]) or not SetupCatalog.is_safe_integer(delta.get("wet"), 0) or not SetupCatalog.is_safe_integer(delta.get("windy"), 0):
			problems.append("%s: invalid weather gain." % attack.id)
	return problems


static func _only_keys(value: Dictionary, allowed: Array) -> bool:
	for key: Variant in value:
		if not allowed.has(key):
			return false
	return true


static func _forest_event(event: Variant, board_size: int = 5) -> bool:
	if not event is Dictionary or not _only_keys(event, ["when", "effect"]): return false
	var timing: Variant = event.get("when")
	var effect: Variant = event.get("effect")
	if not timing is Dictionary or not _only_keys(timing, ["type", "count"]) or timing.get("type") != "slotCount" or not SetupCatalog.is_safe_integer(timing.get("count"), 1) or timing.count > board_size or not effect is Dictionary: return false
	match effect.get("type"):
		"elephantCharge", "lightningStrike": return _only_keys(effect, ["type"])
		"shakyGround": return _only_keys(effect, ["type", "amount"]) and SetupCatalog.is_safe_integer(effect.get("amount"), 1)
		"persistentRain":
			if not _only_keys(effect, ["type", "slotIndexes"]) or not effect.get("slotIndexes") is Array or effect.slotIndexes.is_empty(): return false
			for index: Variant in effect.slotIndexes:
				if not SetupCatalog.is_safe_integer(index, 0) or index >= board_size: return false
			return true
	return false
