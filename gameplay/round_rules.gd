class_name RoundRules
extends RefCounted
## Synchronous Construct-round actions. Invalid actions do nothing.
## Mutates its owned state; presentation may read it but never writes gameplay.

var state: RunState
var catalog: SetupCatalog
var errors: Array[String] = []
var animals: AnimalRules
var _attack: Dictionary


func _init(content: SetupCatalog, run: RunState) -> void:
	catalog = content
	state = run
	animals = AnimalRules.new(run, content)
	errors = RoundContent.validate(catalog)
	if catalog.animals_enabled:
		errors.append_array(CommonWildlife.validate(catalog.wildlife, catalog.habitat_ids))
	if state == null:
		errors.append("A valid run is required.")
		return
	_update_attack()


func _update_attack() -> void:
	for attack: Dictionary in catalog.attacks:
		if attack.id == state.intent.attackId:
			_attack = attack
			return


func market_purchase_error(offer_id: String) -> String:
	if not errors.is_empty() or state.phase != &"playing" or not state.pending_choice.is_empty() or not state.construct_resolution.is_empty(): return "Available between placements."
	for offer: Dictionary in state.reward_offers:
		if offer.offerId == offer_id: return "" if state.gold >= int(offer.price) else "Not enough Gold."
	return "That offer has already changed."


func purchase_market(offer_id: String) -> String:
	var problem := market_purchase_error(offer_id)
	if not problem.is_empty(): return problem
	for index in range(state.reward_offers.size()):
		var offer: Dictionary = state.reward_offers[index]
		if offer.offerId != offer_id: continue
		state.gold -= int(offer.price)
		var card := CardZones.acquire(state, offer.cardId, int(catalog.config.handLimit))
		ConstructOffers.refill(state, catalog, index, offer.cardId)
		state.note("Bought %s for %d Gold%s." % [catalog.cards[card.card_id].name, offer.price, " · added to discard (hand full)" if state.discard_pile.has(card) else ""])
		return ""
	return "That offer has already changed."


func choose_animal_reward(offer_id: String) -> String:
	if not errors.is_empty() or not catalog.animals_enabled:
		return "Animal content is not ready."
	var problem: String = animals.choose_reward(offer_id)
	if problem.is_empty() and state.hand.is_empty():
		_finish_round()
	return problem


func activate_animal(instance_id: String) -> String:
	if not errors.is_empty() or not catalog.animals_enabled:
		return "Animal content is not ready."
	return animals.activate(instance_id)


func resolve_choice(instance_id: String = "") -> String:
	if not errors.is_empty():
		return "Round content is not ready."
	if state.pending_choice.get("kind", "") == "flairDiscard":
		return _resolve_flair_discard(instance_id)
	if state.pending_choice.get("kind", "") == "construct":
		return _resolve_construct_choice(instance_id)
	return animals.resolve_choice(instance_id)


func resolve_animal_acquisition(instance_id: String = "") -> String:
	if not errors.is_empty():
		return "Round content is not ready."
	return animals.resolve_acquisition(instance_id)


func attack_definition() -> Dictionary:
	return _attack


func purchased_draw_cost() -> int:
	return int(catalog.config.get("paidDrawBaseCost", 1)) + int(catalog.config.get("paidDrawCostStep", 2)) * state.purchased_draws_this_round


func purchase_draw_error() -> String:
	if not errors.is_empty() or state.phase != &"playing" or not state.pending_choice.is_empty():
		return "Available between Construct placements."
	if state.hand.size() >= int(catalog.config.handLimit):
		return "Hand is full."
	if state.draw_pile.is_empty() and state.discard_pile.is_empty():
		return "No cards to draw."
	if state.gold < purchased_draw_cost():
		return "Not enough Gold."
	return ""


func purchase_draw() -> String:
	var problem: String = purchase_draw_error()
	if not problem.is_empty():
		return problem
	var cost: int = purchased_draw_cost()
	CardZones.draw(state, 1)
	state.gold -= cost
	state.purchased_draws_this_round += 1
	state.note("Purchased Draw: -%d Gold." % cost)
	return ""


func flair_error(instance_id: String) -> String:
	if not errors.is_empty() or state.phase != &"playing" or not state.pending_choice.is_empty():
		return "Available between Construct placements."
	var card: CardInstance = _placed_card(instance_id)
	if card == null or card.flair_spent or not catalog.cards[card.card_id].has("flair"):
		return "No unused Flair on this placed copy."
	if catalog.cards[card.card_id].flair.type == "supportAll" and not state.cells.any(func(cell: Dictionary) -> bool: return cell.construct != null and cell.construct.instance_id != instance_id):
		return "No other Construct to Support."
	if catalog.cards[card.card_id].flair.type == "bounce":
		return "Choose Flair during this copy’s normal Bounce selection."
	if catalog.cards[card.card_id].flair.type == "draw" and state.hand.size() >= int(catalog.config.handLimit):
		return "Hand is full."
	var flair: Dictionary = catalog.cards[card.card_id].flair
	if flair.type in ["randomHandIntegrity", "discardDraw"] and state.hand.is_empty(): return "No card in hand."
	if flair.type == "drawPerNeighbor":
		if state.hand.size() >= int(catalog.config.handLimit): return "Hand is full."
		if _occupied_neighbors(_slot_of(instance_id)) == 0: return "No occupied neighbours."
	if flair.type == "recoverLast":
		if state.hand.size() >= int(catalog.config.handLimit): return "Hand is full."
		if state.discard_pile.is_empty(): return "Discard pile is empty."
	return ""


func activate_flair(instance_id: String) -> String:
	var problem: String = flair_error(instance_id)
	if not problem.is_empty():
		return problem
	var placed: PlacedConstruct = _placed_card(instance_id)
	var flair: Dictionary = catalog.cards[placed.card_id].flair
	placed.flair_spent = true
	for zone: Array[CardInstance] in [state.deck, state.hand, state.draw_pile, state.discard_pile]:
		for card: CardInstance in zone:
			if card.instance_id == instance_id:
				card.flair_spent = true
	state.note("Flair spent for this copy for the rest of the run.")
	if flair.type == "supportAll":
		for cell: Dictionary in state.cells:
			if cell.construct != null and cell.construct.instance_id != instance_id:
				_support(cell.construct.instance_id, {"amount": flair.amount})
	elif flair.type == "gold":
		state.gold += int(flair.amount)
	elif flair.type == "integrity":
		state.integrity += int(flair.amount)
	elif flair.type == "permanentIntegrity":
		CardUpgrades.add_power(state, placed, int(flair.amount))
		state.integrity += int(flair.amount)
	elif flair.type == "randomHandIntegrity":
		var target: CardInstance = state.hand[int(floor(state.random.roll() * state.hand.size()))]
		var amount: int = card_power(target)
		target.zero_integrity_this_round = true
		placed.power += amount
		state.integrity += amount
		state.note("Steel Girder borrows %d Integrity from %s; its placement contribution is zero this round." % [amount, catalog.cards[target.card_id].name])
	elif flair.type == "drawPerNeighbor":
		CardZones.draw(state, _occupied_neighbors(_slot_of(instance_id)) * int(flair.amount))
	elif flair.type == "discardDraw":
		var ids: Array[String] = []
		for card: CardInstance in state.hand: ids.append(card.instance_id)
		state.pending_choice = {"kind": "flairDiscard", "ids": ids, "remaining": 1, "optional": false, "title": "Discard a card, then draw two", "draw": int(flair.amount)}
	elif flair.type == "recoverLast":
		for _index in range(mini(int(flair.amount), int(catalog.config.handLimit) - state.hand.size())):
			if state.discard_pile.is_empty(): break
			state.hand.append(state.discard_pile.pop_back())
	else:
		CardZones.draw(state, int(flair.amount))
	return ""


func _resolve_flair_discard(id: String) -> String:
	var index: int = _hand_index(id)
	if state.phase != &"playing" or index < 0 or not state.pending_choice.ids.has(id): return "Choose a card in hand to discard."
	var count: int = state.pending_choice.draw
	state.discard_pile.append(state.hand.pop_at(index).plain_copy())
	state.pending_choice.clear()
	CardZones.draw(state, count)
	state.note("Lone Pier: discarded one card and drew up to %d." % count)
	return ""


func _slot_of(instance_id: String) -> int:
	for cell: Dictionary in state.cells:
		if cell.construct != null and cell.construct.instance_id == instance_id: return int(cell.slotIndex)
	return -1


func _occupied_neighbors(slot: int) -> int:
	var count: int = 0
	for neighbor in [slot - 1, slot + 1]:
		if neighbor >= 0 and neighbor < state.cells.size() and state.cells[neighbor].construct != null: count += 1
	return count


func _adjacent_links(slot: int) -> int:
	return state.adjacent_chain_links + 1 if state.last_placement_slot >= 0 and absi(slot - state.last_placement_slot) == 1 else 0


func next_round_error() -> String:
	if not errors.is_empty():
		return "Round content is not ready."
	if state.phase == &"won":
		return "Run complete."
	if state.phase == &"roomComplete":
		return "" if state.pending_animal.is_empty() and state.reward_pool_id <= catalog.max_playable_pool else "Checkpoint complete: the next pool is not enabled yet."
	if state.phase != &"roundComplete":
		return "Finish the current round first."
	if not state.pending_animal.is_empty():
		return "Resolve the animal capacity decision first."
	if state.animal_round_pending and not catalog.animals_enabled:
		return "Slice complete: the next round awards an animal."
	if state.reward_pool_id > catalog.max_playable_pool:
		return "Slice complete: the next content pool is not enabled yet."
	return ""


func start_next_round() -> String:
	var problem: String = next_round_error()
	if not problem.is_empty():
		return problem
	if state.phase == &"roomComplete":
		state.bridge_progress -= int(catalog.config.rooms[state.room_index].requiredProgress)
		state.room_index += 1
		while state.room_index < catalog.config.rooms.size() - 1 and state.bridge_progress >= int(catalog.config.rooms[state.room_index].requiredProgress):
			var room: Dictionary = catalog.config.rooms[state.room_index]
			state.room_clear_events.append({"roomId": room.id, "roomNumber": state.room_index + 1, "roundNumber": state.round_number, "progress": state.bridge_progress})
			state.bridge_progress -= int(room.requiredProgress)
			state.room_index += 1
		state.room_round_number = 0
	state.round_number += 1
	state.room_round_number += 1
	state.reward_round_type = &"animal" if state.animal_round_pending else &"construct"
	ConstructOffers.sync_pool(state, catalog)
	if state.reward_round_type == &"animal":
		animals.prepare_offers()
	state.phase = &"roundChoice" if state.reward_round_type == &"animal" else &"playing"
	state.constructs_placed_this_round = 0
	state.round_instance_plays.clear()
	state.support_used_this_round = false
	state.reinforce_played_this_round = false
	state.supported_instance_ids.clear()
	state.construct_resolution.clear()
	_reset_round_hazards()
	state.selected_animal_id = ""
	state.pending_habitat_id = ""
	state.round_result.clear()
	state.purchased_draws_this_round = 0
	state.next_hit_reduction = 0
	state.placement_bonuses.clear()
	state.pending_choice.clear()
	state.animal_effects.clear()
	for held: CardInstance in state.hand:
		held.power_bonus += held.next_round_power
		held.next_round_power = 0
		held.has_next_round_power = false
	var hand_limit: int = int(catalog.config.handLimit)
	while state.hand.size() > hand_limit:
		state.discard_pile.append(state.hand.pop_back().plain_copy())
	CardZones.draw(state, int(catalog.config.drawPerRound), hand_limit)
	if state.reward_round_type == &"construct":
		state.animal_offers.clear()
		state.resume_construct_offers = false
	RunSetup.initialize_intent(state, catalog)
	RunSetup.initialize_habitat(state, catalog)
	_update_attack()
	state.note("Round %d begins." % state.round_number)
	return ""


func _placed_card(instance_id: String) -> CardInstance:
	for cell: Dictionary in state.cells:
		if cell.construct != null and cell.construct.instance_id == instance_id:
			return cell.construct
	return null


func _complete_progress() -> void:
	state.phase = &"roundComplete"
	var target: int = 0
	for room: Dictionary in catalog.config.rooms:
		target += int(room.requiredProgress)
	if state.bridge_progress >= int(catalog.config.rooms[state.room_index].requiredProgress):
		state.room_clear_events.append({
			"roomId": catalog.config.rooms[state.room_index].id, "roomNumber": state.room_index + 1,
			"roundNumber": state.round_number, "progress": state.bridge_progress,
		})
		state.phase = &"won" if total_progress() >= target else &"roomComplete"
	if state.phase != &"won" and state.round_number >= state.round_limit:
		state.phase = &"lost"
		state.loss_reason = "Round limit reached: %d / %d bridge progress in %d rounds." % [total_progress(), target, state.round_limit]
		state.note(state.loss_reason)


func play_error(instance_id: String, slot_index: int) -> String:
	if not errors.is_empty():
		return "Round content is not ready."
	if not state.pending_choice.is_empty():
		return "Resolve the current choice first."
	if state.phase != &"playing":
		return "Choose the round's reward first." if state.phase == &"roundChoice" else "The round has ended."
	if _hand_index(instance_id) < 0:
		return "Card is not in your hand."
	if slot_index < 0 or slot_index >= state.cells.size():
		return "Choose a valid slot."
	if state.cells[slot_index].construct != null:
		return "That slot is occupied."
	return ""


func hand_power(instance_id: String) -> int:
	var index: int = _hand_index(instance_id)
	if index < 0:
		return 0
	var card: CardInstance = state.hand[index]
	return card_power(card)


func card_power(card: CardInstance) -> int:
	if card.zero_integrity_this_round: return 0
	return card.power if card is PlacedConstruct else maxi(0, int(catalog.cards[card.card_id].baseIntegrity) + card.permanent_power_bonus + card.power_bonus + int(catalog.cards[card.card_id].get("reinforce", 0)) * state.instance_play_counts.get(card.instance_id, 0) - card.weakness)


func contribution(instance_id: String, slot_index: int) -> int:
	if not play_error(instance_id, slot_index).is_empty():
		return 0
	var held: CardInstance = state.hand[_hand_index(instance_id)]
	var card: Dictionary = catalog.cards[held.card_id]
	if held.card_id == "debris" or held.zero_integrity_this_round: return 0
	var gain: int = int(card.baseIntegrity) + held.permanent_power_bonus + held.power_bonus + int(card.get("reinforce", 0)) * state.instance_play_counts.get(instance_id, 0) - held.weakness
	if card.get("integrityFormula", {}).get("type", "") == "priorConstructs":
		gain += state.constructs_placed_this_round * int(card.integrityFormula.amount)
	if card.get("integrityFormula", {}).get("type", "") == "adjacentChain":
		gain += _adjacent_links(slot_index) * int(card.integrityFormula.amount)
	gain = maxi(0, gain) + held.next_placement_bonus
	if card.get("integrityFormula", {}).get("type", "") == "adjacentReinforce":
		for neighbor in [slot_index - 1, slot_index + 1]:
			if neighbor >= 0 and neighbor < state.cells.size():
				var placed: PlacedConstruct = state.cells[neighbor].construct
				if placed != null and catalog.cards[placed.card_id].get("reinforce", 0) > 0: gain += int(card.integrityFormula.amount)
	for neighbor in [slot_index - 1, slot_index + 1]:
		if neighbor >= 0 and neighbor < state.cells.size() and state.cells[neighbor].construct != null:
			gain += state.cells[neighbor].construct.neighbor_integrity_bonus + state.cells[neighbor].construct.neighbor_permanent_bonus
	for bonus: Dictionary in state.placement_bonuses:
		if _condition(bonus.get("condition", ""), slot_index) > 0:
			gain += int(bonus.amount) * (int(bonus.used) + 1 if bonus.get("escalating", false) else 1) * (_condition("perAdjacentSlotOccupied", slot_index) if bonus.get("condition", "") == "perNeighbor" else 1)
	if card.has("positionEffect"):
		var condition: String = card.positionEffect.condition
		var matches: int = _condition(condition, slot_index, card.positionEffect.params)
		if held.satisfy_neighbor_conditions and condition in ["adjacentSlotOccupied", "leftOccupied", "rightOccupied", "emptyNeighbors", "bothNeighborsOccupied", "perAdjacentSlotOccupied"]:
			matches = 2 if condition == "perAdjacentSlotOccupied" else 1
		var positional_bonus: int = int(card.positionEffect.get("supportedIntegrityBonus", card.positionEffect.integrityBonus)) if state.support_used_this_round else int(card.positionEffect.integrityBonus)
		gain += matches * positional_bonus
	var multiplier: float = held.next_placement_multiplier * held.permanent_integrity_multiplier
	for bonus: Dictionary in state.placement_bonuses:
		if _condition(bonus.get("condition", ""), slot_index) > 0: multiplier *= float(bonus.get("multiplier", 1.0))
	gain = int(ceil(gain * multiplier))
	for penalty: Dictionary in _attack.get("slotPenalties", []):
		if int(penalty.slotIndex) == slot_index and not (penalty.get("once", false) and state.intent.get("usedSlotPenalties", []).has(slot_index)):
			gain -= int(penalty.amount)
	for penalty: Dictionary in _attack.get("placementPenalties", []):
		if int(penalty.count) == state.constructs_placed_this_round + 1:
			gain -= int(penalty.amount)
	return maxi(0, gain)


func _condition(condition: String, slot: int, params: Dictionary = {}) -> int:
	var left: bool = slot > 0 and state.cells[slot - 1].construct != null
	var right: bool = slot + 1 < state.cells.size() and state.cells[slot + 1].construct != null
	match condition:
		"", "perNeighbor": return 1
		"evenSlot": return int((slot + 1) % 2 == 0)
		"bothNeighborsOccupied": return int(left and right)
		"adjacentReinforce":
			for neighbor in [slot - 1, slot + 1]:
				if neighbor >= 0 and neighbor < state.cells.size():
					var placed: PlacedConstruct = state.cells[neighbor].construct
					if placed != null and catalog.cards[placed.card_id].get("reinforce", 0) > 0: return 1
			return 0
		"adjacentSlotOccupied": return int(left or right)
		"leftOccupied": return int(left)
		"rightOccupied": return int(right)
		"perAdjacentSlotOccupied": return int(left) + int(right)
		"emptyNeighbors": return int(not left and not right)
		"nthConstructPlacedThisRound": return int(state.constructs_placed_this_round + 1 == int(params.get("n", 0)))
		"firstPlayedThisRound": return int(state.constructs_placed_this_round == 0)
		"centerSlot": return int(slot == int(floor(state.cells.size() / 2.0)))
		"endSlot": return int(slot == 0 or slot == state.cells.size() - 1)
		"lastPlacementThisRound":
			return int(state.hand.size() == 1 or state.cells[slot].construct == null and state.cells.filter(func(cell: Dictionary) -> bool: return cell.construct == null).size() == 1)
		"lastEmptySlot":
			var empty: int = 0
			for cell: Dictionary in state.cells:
				empty += int(cell.construct == null)
			return int(empty == 1 and state.cells[slot].construct == null)
	return 0

func play_card(instance_id: String, slot_index: int) -> String:
	var problem: String = play_error(instance_id, slot_index)
	if not problem.is_empty():
		return problem
	# Contribution is evaluated against the pre-placement board.
	var gain: int = contribution(instance_id, slot_index)
	var index: int = _hand_index(instance_id)
	var card: CardInstance = state.hand[index]
	var definition: Dictionary = catalog.cards[card.card_id]
	var power: int = hand_power(instance_id)
	var should_draw: bool = definition.has("draw") and _draw_matches(definition.draw.trigger, instance_id, slot_index)
	for bonus: Dictionary in state.placement_bonuses:
		if _condition(bonus.get("condition", ""), slot_index) > 0:
			state.next_hit_reduction += int(bonus.get("block", 0))
			bonus.used += 1
			if bonus.remaining > 0: bonus.remaining -= 1
	state.placement_bonuses = state.placement_bonuses.filter(func(bonus: Dictionary) -> bool: return bonus.remaining != 0)
	for neighbor in [slot_index - 1, slot_index + 1]:
		if neighbor >= 0 and neighbor < state.cells.size() and state.cells[neighbor].construct != null:
			var source: PlacedConstruct = state.cells[neighbor].construct
			var upgrade: int = source.neighbor_permanent_bonus
			if upgrade > 0:
				CardUpgrades.add_power(state, card, upgrade)
			source.neighbor_permanent_bonus = 0
			source.neighbor_integrity_bonus = 0
	power = hand_power(instance_id)
	card.next_placement_bonus = 0
	card.next_placement_multiplier = 1.0
	card.satisfy_neighbor_conditions = false
	state.adjacent_chain_links = _adjacent_links(slot_index)
	state.last_placement_slot = slot_index
	state.hand.remove_at(index)
	state.cells[slot_index].construct = PlacedConstruct.new(card, power, gain)
	state.integrity += gain
	var placement_gold: int = int(definition.get("placementGold", 0))
	if placement_gold > 0 and not state.placement_gold_paid.has(instance_id):
		state.placement_gold_paid.append(instance_id)
	else:
		placement_gold = 0
	if definition.has("placementGoldBonus") and not state.placement_gold_bonus_paid.has(instance_id):
		var bonus: Dictionary = definition.placementGoldBonus
		for other_id: String in state.placement_gold_earned:
			if other_id != instance_id and int(state.placement_gold_earned[other_id]) >= int(bonus.minimumOther):
				placement_gold += int(bonus.amount)
				state.placement_gold_bonus_paid.append(instance_id)
				break
	if placement_gold > 0:
		state.gold += placement_gold
		state.placement_gold_earned[instance_id] = int(state.placement_gold_earned.get(instance_id, 0)) + placement_gold
		state.note("Placement: +%d Gold." % placement_gold)
	state.play_counts[card.card_id] = state.play_counts.get(card.card_id, 0) + 1
	state.instance_play_counts[instance_id] = state.instance_play_counts.get(instance_id, 0) + 1
	state.round_instance_plays[instance_id] = state.round_instance_plays.get(instance_id, 0) + 1
	state.note("%s: +%d Integrity (%d total)." % [definition.name, gain, state.integrity])
	state.reinforce_played_this_round = state.reinforce_played_this_round or definition.get("reinforce", 0) > 0
	for penalty: Dictionary in _attack.get("slotPenalties", []):
		if int(penalty.slotIndex) == slot_index and penalty.get("once", false):
			if not state.intent.has("usedSlotPenalties"): state.intent.usedSlotPenalties = []
			state.intent.usedSlotPenalties.append(slot_index)
	if should_draw:
		state.note("Draw: %d card(s)." % CardZones.draw(state, int(definition.draw.amount)))
	state.construct_resolution = {"slot": slot_index, "full": _board_full(), "effects": definition.get("effects", []).duplicate(true)}
	_continue_construct()
	return ""


func _resolve_hits() -> void:
	for index in range(_attack.hits.size()):
		var key: String = str(index)
		if state.intent.resolvedHitKeys.has(key):
			continue
		var hit: Dictionary = _attack.hits[index]
		var occupied: int = 0
		for cell: Dictionary in state.cells:
			occupied += int(cell.construct != null)
		var due: bool = occupied == state.cells.size() if hit.when.type == "fullBoard" else occupied == int(hit.when.count)
		if not due:
			continue
		state.intent.resolvedHitKeys.append(key)
		var damage: int = int(hit.damage) + state.next_forest_damage_bonus
		if state.next_forest_damage_bonus > 0:
			if not state.intent.has("hitDamageBonuses"): state.intent.hitDamageBonuses = {}
			state.intent.hitDamageBonuses[key] = state.next_forest_damage_bonus
		state.next_forest_damage_bonus = 0
		if hit.has("conditionalReduction"):
			var reduction: Dictionary = hit.conditionalReduction
			if _reduction_applies(reduction):
				damage -= int(reduction.amount)
		damage = maxi(0, damage - state.next_hit_reduction)
		state.next_hit_reduction = 0
		for cap: int in state.half_next_hit:
			damage -= mini(cap, int(floor(damage / 2.0)))
		state.half_next_hit.clear()
		for ward: Dictionary in state.hit_protection:
			damage -= int(ward.amount)
		damage = maxi(0, damage)
		var without_shared: int = damage
		damage = maxi(0, damage - state.shared_protection)
		state.shared_protection = maxi(0, state.shared_protection - without_shared)
		for ward: Dictionary in state.hit_protection:
			if int(ward.remaining) > 0: ward.remaining -= 1
		state.hit_protection = state.hit_protection.filter(func(ward: Dictionary) -> bool: return int(ward.remaining) != 0)
		var grace: Dictionary = state.grace.pop_front() if damage > state.integrity and not state.grace.is_empty() else {}
		var fatal: bool = damage > state.integrity and grace.is_empty()
		state.forest_impact_sequence += 1
		if state.forest_impacts.size() == 12:
			state.forest_impacts.pop_front()
		state.forest_impacts.append({
			"id": state.forest_impact_sequence, "attackName": _attack.name,
			"damage": damage, "before": state.integrity,
			"after": int(grace.amount) if not grace.is_empty() else maxi(0, state.integrity - damage), "fatal": fatal,
		})
		if fatal:
			# The prototype preserves the pre-hit pool/board in a defeated snapshot.
			state.phase = &"lost"
			state.pending_habitat_id = ""
			state.loss_reason = "%s, hit %d: %d damage exceeds %d Integrity." % [
				_attack.name, index + 1, damage, state.integrity,
			]
			state.note(state.loss_reason)
			return
		state.integrity = int(grace.amount) if not grace.is_empty() else state.integrity - damage
		if not grace.is_empty():
			state.note("Grace: survived the lethal hit with %d Integrity." % grace.amount)
			CardZones.draw(state, int(grace.get("drawOnTrigger", 0)))
			if grace.has("nextPlacementBonus"):
				state.placement_bonuses.append({"amount": int(grace.nextPlacementBonus), "remaining": 1, "used": 0})
		state.note("%s: -%d Integrity (%d remaining)." % [_attack.name, damage, state.integrity])


func _finish_round() -> void:
	state.intent.resolved = true
	var incomplete: bool = state.intent.resolvedHitKeys.size() != _attack.hits.size()
	var progress_percent: int = 0
	for bonus: Dictionary in state.progress_bonuses:
		if not bonus.get("requiresFullBoard", false) or _board_full(): progress_percent += int(bonus.percent)
	var progress: int = int(ceil(state.integrity * (1.0 + progress_percent / 100.0)))
	state.bridge_progress += progress
	state.integrity = 0
	for cell: Dictionary in state.cells:
		if cell.construct != null:
			var card: CardInstance = cell.construct
			state.discard_pile.append(card.plain_copy())
		cell.construct = null
	var retained: Array[CardInstance] = []
	for card: CardInstance in state.hand:
		if card.retain_next_round:
			var copy: CardInstance = card.plain_copy()
			copy.held_turns = card.held_turns + 1
			retained.append(copy)
		else:
			state.discard_pile.append(card.plain_copy())
	state.hand = retained
	for zone: Array[CardInstance] in [state.draw_pile, state.discard_pile, state.deck, state.exiled]:
		for card: CardInstance in zone:
			card.next_round_power = 0
			card.has_next_round_power = false
	for zone: Array[CardInstance] in [state.hand, state.draw_pile, state.discard_pile, state.deck, state.exiled]:
		for card: CardInstance in zone:
			card.power_bonus = 0
	_reset_round_hazards()
	state.next_hit_reduction = 0
	state.placement_bonuses.clear()
	state.round_result = {"progress": progress, "earnedCardId": null, "trialIncomplete": incomplete, "goldPayout": 0}
	state.note("Round %d: %d Integrity converted to bridge progress." % [state.round_number, progress])
	state.note("Round ended: %d Gold carried forward." % state.gold)
	_complete_progress()
	if state.phase != &"lost" and not incomplete and not state.pending_habitat_id.is_empty():
		state.habitat_batch.append(state.pending_habitat_id)
		state.habitat_history.append({"round": state.round_number, "habitatId": state.pending_habitat_id})
		if state.habitat_batch.size() == 3:
			state.animal_round_pending = true
	if state.phase != &"lost" and not incomplete and state.reward_round_type == &"animal" and not state.selected_animal_id.is_empty():
		animals.acquire()
		state.round_result.earnedAnimalId = state.selected_animal_id
	if not incomplete:
		for key: String in ["wet", "windy"]:
			state.weather[key] = mini(int(catalog.config.weatherCap), int(state.weather[key]) + int(_attack.weatherDelta[key]))
	state.pending_habitat_id = ""
	if state.phase != &"lost":
		ConstructOffers.sync_pool(state, catalog)


func _hand_index(instance_id: String) -> int:
	for index in range(state.hand.size()):
		if state.hand[index].instance_id == instance_id:
			return index
	return -1


func _board_full() -> bool:
	for cell: Dictionary in state.cells:
		if cell.construct == null:
			return false
	return true




func total_progress() -> int:
	var progress: int = state.bridge_progress
	for index in range(state.room_index):
		progress += int(catalog.config.rooms[index].requiredProgress)
	return progress


func _reduction_applies(reduction: Dictionary) -> bool:
	match reduction.type:
		"supportUsed": return state.support_used_this_round
		"reinforcePlayed": return state.reinforce_played_this_round
		"copyReplayed": return state.round_instance_plays.values().any(func(count: int) -> bool: return count >= 2)
	var required: Array = [state.cells[int(state.cells.size() / 2.0)].construct] if reduction.type == "centerContributionAtLeast" else [state.cells[0].construct, state.cells[-1].construct]
	for placed: PlacedConstruct in required:
		if placed == null: return false
		var value: int = placed.power if reduction.type == "endPowerAtLeast" else placed.integrity_added
		if value < int(reduction.minimum): return false
	return true


func _construct_targets(effect: Dictionary, source_slot: int) -> Array[String]:
	var ids: Array[String] = []
	var lowest: int = 2147483647
	for cell: Dictionary in state.cells:
		var placed: PlacedConstruct = cell.construct
		if placed == null or cell.slotIndex == source_slot: continue
		if effect.type == "bounce" and catalog.cards[placed.card_id].get("cantBounce", false): continue
		if effect.target in ["adjacent", "adjacentOne", "adjacentAll"] and absi(cell.slotIndex - source_slot) != 1: continue
		if effect.target == "left" and cell.slotIndex != source_slot - 1: continue
		if effect.target == "edge" and cell.slotIndex != 0 and cell.slotIndex != state.cells.size() - 1: continue
		if effect.target == "playedTwice" and state.round_instance_plays.get(placed.instance_id, 0) < 2: continue
		if effect.target == "lowest":
			if placed.power > lowest: continue
			if placed.power < lowest: ids.clear()
			lowest = placed.power
		ids.append(placed.instance_id)
	return ids


func _support(id: String, effect: Dictionary) -> void:
	var placed: PlacedConstruct = _placed_card(id)
	var amount: int = int(effect.reinforceAmount) if effect.has("reinforceAmount") and catalog.cards[placed.card_id].get("reinforce", 0) > 0 else int(effect.amount)
	if effect.has("supportedAmount") and state.supported_instance_ids.has(id): amount = int(effect.supportedAmount)
	if effect.has("bouncedAmount") and state.bounced_instance_ids.has(id): amount = int(effect.bouncedAmount)
	if effect.has("replayedAmount") and state.round_instance_plays.get(id, 0) >= 2: amount = int(effect.replayedAmount)
	if effect.has("placementBonus") and state.constructs_placed_this_round + 1 == int(effect.placementBonus.count): amount = int(effect.placementBonus.amount)
	placed.power += amount
	state.integrity += amount
	state.support_used_this_round = true
	if not state.supported_instance_ids.has(id): state.supported_instance_ids.append(id)
	state.note("Support: %s +%d power and Integrity." % [catalog.cards[placed.card_id].name, amount])


func _bounce(id: String) -> void:
	for cell: Dictionary in state.cells:
		if cell.construct != null and cell.construct.instance_id == id and state.hand.size() < int(catalog.config.handLimit):
			if catalog.cards[cell.construct.card_id].get("cantBounce", false): return
			if not state.bounced_instance_ids.has(id): state.bounced_instance_ids.append(id)
			state.hand.append(cell.construct.plain_copy())
			cell.construct = null
			state.note("Bounce: %s returned; Integrity kept." % id)
			return


func _continue_construct() -> void:
	while not state.construct_resolution.effects.is_empty():
		var effect: Dictionary = state.construct_resolution.effects.pop_front()
		var slot: int = state.construct_resolution.slot
		match effect.type:
			"gold":
				state.gold += int(effect.amount)
				state.note("Gain %d Gold." % effect.amount)
			"nextAdjacentIntegrity": state.cells[slot].construct.neighbor_integrity_bonus += int(effect.amount)
			"nextAdjacentPermanent": state.cells[slot].construct.neighbor_permanent_bonus += int(effect.amount)
			"nextForestDamage": state.next_forest_damage_bonus += int(effect.amount)
			"support", "bounce":
				var ids: Array[String] = _construct_targets(effect, slot)
				if effect.type == "support" and (effect.target == "adjacentAll" or ids.size() == 1):
					for id: String in ids: _support(id, effect)
				elif not ids.is_empty() and (effect.type != "bounce" or (not state.construct_resolution.full and state.hand.size() < int(catalog.config.handLimit))):
					state.pending_choice = {"kind": "construct", "ids": ids, "effect": effect, "optional": effect.type == "bounce", "title": "Choose %s target" % effect.type, "remaining": 1, "selected": [], "flairMode": false}
					return
	var full: bool = state.construct_resolution.full
	state.construct_resolution.clear()
	state.constructs_placed_this_round += 1
	ForestEffects.tick_rain(state)
	_resolve_hits()
	if state.phase == &"lost": return
	ForestEffects.resolve(state, catalog, _attack)
	if full or state.hand.is_empty(): _finish_round()


func _resolve_construct_choice(id: String) -> String:
	var choice: Dictionary = state.pending_choice
	if state.phase != &"playing" or state.construct_resolution.is_empty(): return "No Construct choice is active."
	if id == "toggle-flair":
		var source: PlacedConstruct = state.cells[state.construct_resolution.slot].construct
		if choice.effect.type != "bounce" or source.flair_spent or catalog.cards[source.card_id].get("flair", {}).get("type", "") != "bounce" or choice.ids.size() < 2 or state.hand.size() > int(catalog.config.handLimit) - 2:
			return "Bounce Flair needs two targets and two free hand spaces."
		choice.flairMode = not choice.flairMode
		choice.selected.clear()
		choice.remaining = 2 if choice.flairMode else 1
		return ""
	if id == "confirm-flair":
		if not choice.flairMode or choice.selected.size() != 2: return "Select exactly two targets."
		var source: PlacedConstruct = state.cells[state.construct_resolution.slot].construct
		source.flair_spent = true
		for card: CardInstance in state.deck:
			if card.instance_id == source.instance_id: card.flair_spent = true
		for target: String in choice.selected: _bounce(target)
		CardZones.draw(state, int(choice.effect.get("drawOnBounce", 0)))
	elif id.is_empty():
		if not choice.optional: return "Choose a Support target."
	elif not choice.ids.has(id): return "That target is unavailable."
	elif choice.flairMode:
		if choice.selected.has(id): choice.selected.erase(id)
		elif choice.selected.size() < 2: choice.selected.append(id)
		choice.remaining = 2 - choice.selected.size()
		return ""
	elif choice.effect.type == "support": _support(id, choice.effect)
	else:
		_bounce(id)
		CardZones.draw(state, int(choice.effect.get("drawOnBounce", 0)))
		if int(choice.effect.get("count", 1)) > 1:
			var again: Dictionary = choice.effect.duplicate()
			again.count -= 1
			state.construct_resolution.effects.push_front(again)
	state.pending_choice.clear()
	_continue_construct()
	return ""


func _reset_round_hazards() -> void:
	state.placement_gold_paid.clear()
	state.placement_gold_earned.clear()
	state.placement_gold_bonus_paid.clear()
	state.bounced_instance_ids.clear()
	state.next_forest_damage_bonus = 0
	state.last_placement_slot = -1
	state.adjacent_chain_links = 0
	state.rain_slots.clear()
	state.half_next_hit.clear()
	state.hit_protection.clear()
	state.shared_protection = 0
	state.grace.clear()
	state.progress_bonuses.clear()
	state.prevent_destruction = false
	for zone: Array[CardInstance] in [state.hand, state.draw_pile, state.discard_pile, state.deck, state.exiled]:
		for card: CardInstance in zone:
			card.weakness = 0
			card.zero_integrity_this_round = false


func _draw_matches(trigger: String, instance_id: String, slot: int) -> bool:
	match trigger:
		"onPlacement": return true
		"supportUsedThisRound": return state.support_used_this_round
		"anotherSupportedThisRound": return state.supported_instance_ids.any(func(id: String) -> bool: return id != instance_id)
		"adjacentReinforce":
			for neighbor in [slot - 1, slot + 1]:
				if neighbor >= 0 and neighbor < state.cells.size():
					var placed: PlacedConstruct = state.cells[neighbor].construct
					if placed != null and catalog.cards[placed.card_id].get("reinforce", 0) > 0: return true
	return false
