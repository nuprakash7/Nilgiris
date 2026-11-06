class_name AnimalRules
extends RefCounted
## Common/uncommon/rare roster lifecycle and targeting. Shares the owning RoundRules state.
var state: RunState
var catalog: SetupCatalog

func _init(run: RunState, content: SetupCatalog) -> void:
	state = run
	catalog = content

func definition(id: String) -> Dictionary:
	for animal: Dictionary in catalog.wildlife.get("animals", []):
		if animal.id == id:
			return animal
	return {}

func prepare_offers() -> void:
	if not state.animal_offers.is_empty():
		return
	var remaining: Array = catalog.wildlife.animals.duplicate()
	for _pick in range(4):
		var weights: Array[float] = []
		var total: float = 0
		for animal: Dictionary in remaining:
			var affinity: float = 0
			for habitat: String in state.habitat_batch:
				affinity += float(animal.habitatAffinities.get(habitat, 0))
			var weight: float = float(catalog.wildlife.rarityWeights[animal.rarity]) * affinity
			weights.append(weight)
			total += weight
		var cursor: float = state.random.roll() * total
		var index: int = remaining.size() - 1
		for i in range(remaining.size()):
			cursor -= weights[i]
			if cursor < 0:
				index = i
				break
		var chosen: Dictionary = remaining.pop_at(index)
		state.animal_offers.append({"offerId": "offer-%d" % state.next_offer_id, "animalId": chosen.id})
		state.next_offer_id += 1
		if not state.animal_encounters.has(chosen.id):
			state.animal_encounters.append(chosen.id)

func choose_reward(offer_id: String) -> String:
	if state.reward_round_type != &"animal" or state.phase != &"roundChoice" or not state.selected_animal_id.is_empty() or not state.pending_animal.is_empty():
		return "The round's reward choice is locked."
	for offer: Dictionary in state.animal_offers:
		if offer.offerId == offer_id:
			state.selected_animal_id = offer.animalId
			state.phase = &"playing"
			state.note("Animal reward selected: %s." % definition(offer.animalId).name)
			return ""
	return "That offer is no longer available."

func acquire() -> void:
	var animal: Dictionary = {
		"instanceId": "animal-%d" % state.next_animal_instance_id, "animalId": state.selected_animal_id,
		"acquisitionRound": state.round_number, "lastActivationRound": null,
		"nextEligibleRound": state.round_number + 1, "effectState": {"activations": 0},
	}
	state.next_animal_instance_id += 1
	var space: bool = state.animals.size() < state.animal_capacity
	if not state.animal_encounters.has(animal.animalId):
		state.animal_encounters.append(animal.animalId)
	state.sightings.append({"round": state.round_number, "habitats": state.habitat_batch.duplicate(), "animalId": animal.animalId, "instanceId": animal.instanceId, "disposition": "kept" if space else "pending"})
	if space:
		state.animals.append(animal)
		state.habitat_batch.clear()
		state.animal_round_pending = false
	else:
		state.pending_animal = animal
	state.note("Animal sighted: %s%s." % [definition(animal.animalId).name, "; joins next round" if space else "; choose whether to replace an animal"])

func resolve_acquisition(replace_id: String = "") -> String:
	if state.pending_animal.is_empty() or not state.phase in [&"roundComplete", &"roomComplete", &"won"]:
		return "No acquisition to resolve."
	var index: int = -1
	for i in range(state.animals.size()):
		if state.animals[i].instanceId == replace_id:
			index = i
	if not replace_id.is_empty() and index < 0:
		return "Animal not owned."
	if index >= 0:
		state.animals.remove_at(index)
		state.animals.append(state.pending_animal)
	for sighting: Dictionary in state.sightings:
		if sighting.instanceId == state.pending_animal.instanceId:
			sighting.disposition = "kept" if index >= 0 else "declined"
	state.pending_animal = {}
	state.habitat_batch.clear()
	state.animal_round_pending = false
	state.note("Scrapped one animal; newcomer joins next round." if index >= 0 else "Declined the sighting.")
	return ""

func targets(effect: Dictionary) -> Array[CardInstance]:
	var result: Array[CardInstance] = []
	match effect.action:
		"bounce", "protect":
			if effect.action == "protect" or state.hand.size() < 12:
				for cell: Dictionary in state.cells:
					if cell.construct != null and (effect.action != "bounce" or not catalog.cards[cell.construct.card_id].get("cantBounce", false)):
						result.append(cell.construct)
		"recover":
			if state.hand.size() < 12: result.assign(state.discard_pile)
		"search":
			if state.hand.size() < 12:
				for card: CardInstance in state.draw_pile:
					if not effect.get("unusedFlair", false) or (catalog.cards[card.card_id].has("flair") and not card.flair_spent): result.append(card)
		"removeDebris":
			for card: CardInstance in state.hand + state.discard_pile:
				if card.card_id == "debris": result.append(card)
		"discardDebris":
			for card: CardInstance in state.hand:
				if card.card_id == "debris": result.append(card)
		"look":
			if state.hand.size() < 12:
				result.assign(state.draw_pile.slice(0, int(effect.lookCount)))
		_:
			result.assign(state.hand)
	return result

func use_error(instance_id: String) -> String:
	var owned: Dictionary = {}
	for animal: Dictionary in state.animals:
		if animal.instanceId == instance_id:
			owned = animal
	if owned.is_empty():
		return "Animal not owned."
	var animal: Dictionary = definition(owned.animalId)
	if animal.get("oncePerRun", false) and owned.effectState.activations > 0:
		return "Spent for this run."
	if state.phase != &"playing" or not state.pending_choice.is_empty() or not state.animal_effects.is_empty() or not state.pending_animal.is_empty():
		return "Available between Construct placements."
	if owned.lastActivationRound == state.round_number:
		return "Already activated this round."
	if state.round_number < int(owned.nextEligibleRound):
		return "Ready in round %d." % owned.nextEligibleRound
	var effect: Dictionary = animal.effect
	if effect.type == "draw" and state.hand.size() >= 12:
		return "Hand is full."
	if effect.type == "choose" and targets(effect).is_empty() and not (effect.action == "look" and state.draw_pile.is_empty() and not state.discard_pile.is_empty() and state.hand.size() < 12):
		return "No eligible target."
	return ""

func activate(instance_id: String) -> String:
	var problem: String = use_error(instance_id)
	if not problem.is_empty():
		return problem
	for animal: Dictionary in state.animals:
		if animal.instanceId != instance_id:
			continue
		var authored: Dictionary = definition(animal.animalId)
		animal.lastActivationRound = state.round_number
		animal.nextEligibleRound = state.round_number + int(authored.get("cooldown", 0)) + 1
		animal.effectState.activations += 1
		state.animal_effects.assign([authored.effect.duplicate(true)])
		_continue_effects()
		state.note("%s activated." % authored.name)
	return ""

func _continue_effects() -> void:
	while not state.animal_effects.is_empty():
		var effect: Dictionary = state.animal_effects.pop_front()
		match effect.type:
			"sequence":
				state.animal_effects.assign(effect.effects + state.animal_effects)
			"integrity": state.integrity += int(effect.amount)
			"integrityPerOccupied":
				for cell: Dictionary in state.cells:
					if cell.construct != null:
						state.integrity += int(effect.amount)
			"draw": CardZones.draw(state, int(effect.amount))
			"gold": state.gold += int(effect.amount)
			"preventDestruction": state.prevent_destruction = true
			"sharedProtection": state.shared_protection += int(effect.amount)
			"grace": state.grace.append(effect.duplicate())
			"progress": state.progress_bonuses.append(effect.duplicate())
			"halfNextHit": state.half_next_hit.append(int(effect.get("amount", 2147483647)))
			"hitProtection": state.hit_protection.append({"amount": int(effect.amount), "remaining": int(effect.get("count", -1))})
			"reduceNextHit": state.next_hit_reduction += int(effect.amount)
			"placementBonus":
				var bonus: Dictionary = effect.duplicate()
				bonus.remaining = int(effect.get("count", -1 if effect.get("escalating", false) else 1))
				bonus.used = 0
				state.placement_bonuses.append(bonus)
			"choose":
				if effect.action == "look" and state.draw_pile.is_empty() and not state.discard_pile.is_empty():
					state.draw_pile.assign(state.random.shuffled(state.discard_pile))
					state.discard_pile.clear()
				var cards: Array[CardInstance] = targets(effect)
				if not cards.is_empty():
					var ids: Array[String] = []
					for card: CardInstance in cards:
						ids.append(card.instance_id)
					state.pending_choice = {"ids": ids, "effect": effect, "remaining": int(effect.count), "selected": [], "optional": effect.get("optional", effect.action in ["retain", "bounce"]), "title": {"handPower": "Choose Hand Card", "retain": "Retain Cards", "bounce": "Return Constructs to Hand", "look": "Choose Cards from Deck Top", "discard": "Discard a Hand Card", "protect": "Protect a Construct", "search": "Search Draw Pile", "recover": "Return from Discard", "discardDebris": "Discard Debris", "removeDebris": "Remove Debris Permanently"}[effect.action]}
					return

func resolve_choice(id: String = "") -> String:
	var choice: Dictionary = state.pending_choice
	if choice.is_empty() or state.phase != &"playing":
		return "No animal choice is pending."
	if (id.is_empty() and not choice.optional) or (not id.is_empty() and not choice.ids.has(id)):
		return "Choose an eligible card."
	var effect: Dictionary = choice.effect
	if not id.is_empty():
		if effect.action == "protect":
			for cell: Dictionary in state.cells:
				if cell.construct != null and cell.construct.instance_id == id: cell.construct.destruction_protection += 1
		elif effect.action == "bounce":
			if state.hand.size() >= 12:
				return "Hand is full."
			for cell: Dictionary in state.cells:
				if cell.construct != null and cell.construct.instance_id == id:
					if catalog.cards[cell.construct.card_id].get("cantBounce", false): return "This Construct cannot be Bounced."
					if not state.bounced_instance_ids.has(id): state.bounced_instance_ids.append(id)
					var returned: CardInstance = cell.construct.plain_copy()
					returned.next_placement_bonus += int(effect.get("nextPlacementBonus", 0))
					returned.next_placement_multiplier *= float(effect.get("nextPlacementMultiplier", 1.0))
					state.hand.append(returned)
					state.note("Bounce: %s from slot %d; Integrity kept." % [id, cell.slotIndex + 1])
					cell.construct = null
		else:
			var zone: Array[CardInstance] = state.discard_pile if effect.action == "recover" else (state.draw_pile if effect.action in ["look", "search"] else (targets(effect) if effect.action == "removeDebris" else state.hand))
			var chosen: CardInstance
			for card: CardInstance in zone:
				if card.instance_id == id:
					chosen = card
			if chosen == null:
				return "Card is no longer available."
			match effect.action:
				"handPower": chosen.power_bonus += int(effect.get("amount", 0))
				"retain":
					chosen.retain_next_round = true
					chosen.has_next_round_power = true
					chosen.next_round_power += int(effect.get("nextRoundPower", 0))
				"look", "search", "recover":
					if state.hand.size() >= 12:
						return "Hand is full."
					zone.erase(chosen)
					state.hand.append(chosen)
				"removeDebris":
					state.hand.erase(chosen)
					state.discard_pile.erase(chosen)
					for index in range(state.deck.size() - 1, -1, -1):
						if state.deck[index].instance_id == id: state.deck.remove_at(index)
					state.exiled.append(chosen.plain_copy())
					state.note("Removed Debris permanently; no replacement created.")
				"discard", "discardDebris":
					state.hand.erase(chosen)
					state.discard_pile.append(chosen.plain_copy())
			if effect.action in ["handPower", "search"]:
				chosen.next_placement_bonus += int(effect.get("nextPlacementBonus", 0))
				chosen.next_placement_multiplier *= float(effect.get("nextPlacementMultiplier", 1.0))
				chosen.permanent_integrity_multiplier *= float(effect.get("permanentMultiplier", 1.0))
				chosen.satisfy_neighbor_conditions = chosen.satisfy_neighbor_conditions or effect.get("satisfyNeighbors", false)
		choice.selected.append(id)
		choice.remaining -= 1
		choice.ids.erase(id)
		var selected: CardInstance = CardZones.find_live(state, id)
		if selected == null:
			selected = state.exiled[-1]
		var definition_id: String = selected.card_id
		if effect.get("differentDefinitions", false):
			choice.ids = choice.ids.filter(func(target: String) -> bool: return CardZones.find_live(state, target).card_id != definition_id)
		state.note("%s: selected %s." % [choice.title, catalog.cards[definition_id].name])
	if id.is_empty() or choice.remaining == 0 or choice.ids.is_empty() or (state.hand.size() >= 12 and effect.action in ["look", "bounce", "search", "recover"]):
		if effect.action == "look":
			var bottom: Array[CardInstance] = []
			for card: CardInstance in state.draw_pile:
				if choice.ids.has(card.instance_id):
					bottom.append(card)
			for card: CardInstance in bottom:
				state.draw_pile.erase(card)
			state.draw_pile.append_array(bottom)
		if effect.get("drawAfter", 0) > 0 and not choice.selected.is_empty():
			CardZones.draw(state, int(effect.drawAfter))
		state.pending_choice = {}
		_continue_effects()
	return ""
