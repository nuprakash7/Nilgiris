class_name RunSetup
extends RefCounted
## Creates a run; does not implement reward choice or play actions.


static func create(catalog: SetupCatalog, seed: int = 42) -> RunState:
	if not catalog.errors.is_empty():
		push_error("Cannot create a run from invalid setup content: %s" % [catalog.errors])
		return null
	var state := RunState.new()
	state.random = RunRandom.new(seed)
	state.gold = int(catalog.config.get("startingGold", 3))
	for entry: Dictionary in catalog.config.starterDeck:
		for _copy in range(int(entry.copies)):
			var copy_id: String = "card-%d" % state.next_instance_id
			state.next_instance_id += 1
			state.deck.append(CardInstance.new(copy_id, entry.cardId))
	# Ownership metadata is distinct from live zone objects, as in TypeScript.
	var live_copies: Array[CardInstance] = []
	for card: CardInstance in state.deck:
		live_copies.append(card.plain_copy())
	state.draw_pile.assign(state.random.shuffled(live_copies))
	state.round_limit = 20 + int(floor(state.random.roll() * 5))

	ConstructOffers.sync_pool(state, catalog)
	CardZones.draw(state, int(catalog.config.get("openingHandSize", 7)), int(catalog.config.handLimit))
	initialize_intent(state, catalog)
	initialize_habitat(state, catalog)
	state.note("Round 1 begins.")
	return state


static func initialize_intent(state: RunState, catalog: SetupCatalog) -> void:
	var pool: Dictionary = catalog.pool(state.reward_pool_id)
	# Catalog order, not pool.attackIds order, determines the selection interval.
	var eligible: Array[Dictionary] = []
	for attack: Dictionary in catalog.attacks:
		if pool.attackIds.has(attack.id) and attack.requires.wet <= state.weather.wet and attack.requires.windy <= state.weather.windy:
			eligible.append(attack)
	var attack_index: int = int(floor(state.random.roll() * eligible.size()))
	var attack: Dictionary = eligible[attack_index]
	state.intent = {
		"attackId": attack.id, "category": attack.category,
		"resolvedHitKeys": [], "resolved": false,
	}
	state.cells.clear()
	for slot_index in range(int(attack.get("boardSize", 5))):
		state.cells.append({"slotIndex": slot_index, "construct": null})


static func initialize_habitat(state: RunState, catalog: SetupCatalog) -> void:
	# Encounters stay round-based, independent of purchase frequency or saving.
	state.pending_habitat_id = catalog.habitat_ids[int(floor(state.random.roll() * catalog.habitat_ids.size()))] if state.reward_round_type == &"construct" else ""
