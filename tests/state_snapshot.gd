extends RefCounted
## Test-only translation to the TypeScript boundary schema.


static func capture(state: RunState) -> Dictionary:
	var cells: Array = []
	for cell: Dictionary in state.cells:
		var construct: Variant = null
		if cell.construct != null:
			var placed: PlacedConstruct = cell.construct
			construct = _card(placed)
			construct.power = placed.power
			construct.integrityAdded = placed.integrity_added
			if placed.neighbor_integrity_bonus != 0:
				construct.neighborIntegrityBonus = placed.neighbor_integrity_bonus
		cells.append({"slotIndex": cell.slotIndex, "construct": construct})
	return {
		"animals": state.animals.duplicate(true), "animalCapacity": state.animal_capacity,
		"nextAnimalInstanceId": state.next_animal_instance_id, "pendingAnimal": state.pending_animal if not state.pending_animal.is_empty() else null,
		"animalOffers": state.animal_offers.duplicate(true), "selectedAnimalId": state.selected_animal_id if not state.selected_animal_id.is_empty() else null,
		"resumeConstructOffers": state.resume_construct_offers, "animalEncounters": state.animal_encounters.duplicate(), "sightings": state.sightings.duplicate(true),
		"nextHitReduction": state.next_hit_reduction, "placementBonuses": state.placement_bonuses.duplicate(true),
		"choice": _choice(state),
		"phase": String(state.phase), "roomIndex": state.room_index,
		"roundNumber": state.round_number, "roomRoundNumber": state.room_round_number,
		"roundLimit": state.round_limit, "integrity": state.integrity,
		"bridgeProgress": state.bridge_progress, "gold": state.gold,
		"purchasedDrawsThisRound": state.purchased_draws_this_round,
		"weather": state.weather.duplicate(), "deck": _cards(state.deck),
		"hand": _cards(state.hand), "drawPile": _cards(state.draw_pile),
		"discardPile": _cards(state.discard_pile),
		"nextInstanceId": state.next_instance_id, "nextOfferId": state.next_offer_id,
		"rewardPoolId": state.reward_pool_id, "constructOfferPoolId": state.construct_offer_pool_id,
		"rewardPool": state.reward_pool.duplicate(), "rewardOffers": state.reward_offers.duplicate(true),
		"rewardRoundType": String(state.reward_round_type), "intent": state.intent.duplicate(true),
		"cells": cells, "randomSeed": state.random.seed,
		"constructsPlacedThisRound": state.constructs_placed_this_round,
		"playCounts": state.play_counts.duplicate(), "instancePlayCounts": state.instance_play_counts.duplicate(),
		"roundInstancePlays": state.round_instance_plays.duplicate(),
		"selectedReward": state.selected_reward.duplicate() if not state.selected_reward.is_empty() else null,
		"pendingHabitatId": state.pending_habitat_id if not state.pending_habitat_id.is_empty() else null,
		"habitatBatch": state.habitat_batch.duplicate(), "habitatHistory": state.habitat_history.duplicate(true),
		"roundResult": state.round_result.duplicate() if not state.round_result.is_empty() else null,
		"lossReason": state.loss_reason if not state.loss_reason.is_empty() else null,
		"log": state.log.duplicate(), "forestImpacts": state.forest_impacts.duplicate(true),
		"forestImpactSequence": state.forest_impact_sequence, "animalRoundPending": state.animal_round_pending,
		"roomClearEvents": state.room_clear_events.duplicate(true),
	}


static func normalize(value: Variant) -> Variant:
	# Godot parses JSON numbers as floats; state fields here are integer-valued.
	if value is float and floor(value) == value:
		return int(value)
	if value is Array:
		var result: Array = []
		for item: Variant in value:
			result.append(normalize(item))
		return result
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value:
			result[key] = normalize(value[key])
		return result
	return value


static func differences(actual: Dictionary, expected: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for key: String in expected:
		if not actual.has(key) or normalize(actual[key]) != normalize(expected[key]):
			result.append(key)
	return result


static func _cards(cards: Array[CardInstance]) -> Array:
	var result: Array = []
	for card: CardInstance in cards:
		result.append(_card(card))
	return result


static func _card(card: CardInstance) -> Dictionary:
	var result: Dictionary = {"instanceId": card.instance_id, "cardId": card.card_id, "heldTurns": card.held_turns}
	if card.power_bonus != 0:
		result.powerBonus = card.power_bonus
	if card.next_round_power != 0 or card.has_next_round_power:
		result.nextRoundPower = card.next_round_power
	if card.retain_next_round:
		result.retainNextRound = true
	if card.flair_spent:
		result.flairSpent = true
	return result

static func _choice(state: RunState) -> Variant:
	if state.pending_choice.is_empty():
		return null
	return {"ids": state.pending_choice.ids.duplicate(), "remaining": state.pending_choice.remaining, "selected": state.pending_choice.selected.duplicate(), "optional": state.pending_choice.optional, "effect": state.pending_choice.effect.duplicate(true), "title": state.pending_choice.title}
