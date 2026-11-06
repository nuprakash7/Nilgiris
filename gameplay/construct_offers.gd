class_name ConstructOffers
extends RefCounted
## Four persistent priced market offers; only purchases/pool changes replace slots.


static func sync_pool(state: RunState, catalog: SetupCatalog) -> void:
	var active: Array[Dictionary] = []
	for pool: Dictionary in catalog.config.rewardPools:
		if pool.id > 0 and not pool.cardIds.is_empty():
			active.append(pool)
	var progress: int = state.bridge_progress
	for index in range(state.room_index):
		progress += int(catalog.config.rooms[index].requiredProgress)
	var pool: Dictionary = active[mini(int(floor(float(progress) / 50)), active.size() - 1)]
	state.reward_pool_id = int(pool.id)
	if state.construct_offer_pool_id == int(pool.id):
		return
	state.construct_offer_pool_id = int(pool.id)
	state.reward_pool.assign(state.random.shuffled(pool.cardIds))
	state.reward_offers.clear()
	for index in range(int(catalog.config.rewardOfferCount)):
		refill(state, catalog, index)


static func refill(state: RunState, catalog: SetupCatalog, index: int, excluded: String = "") -> void:
	var occupied: Array[String] = []
	if not excluded.is_empty():
		occupied.append(excluded)
	for i in range(state.reward_offers.size()):
		if i != index:
			occupied.append(state.reward_offers[i].cardId)
	for i in range(state.reward_pool.size() - 1, -1, -1):
		if occupied.has(state.reward_pool[i]):
			state.reward_pool.remove_at(i)
	if state.reward_pool.is_empty():
		var available: Array[String] = []
		for id: String in catalog.pool(state.construct_offer_pool_id).cardIds:
			if not occupied.has(id):
				available.append(id)
		state.reward_pool.assign(state.random.shuffled(available))
	var offer: Dictionary = {
		"offerId": "offer-%d" % state.next_offer_id,
		"cardId": state.reward_pool.pop_front(),
	}
	offer.price = int(catalog.cards[offer.cardId].purchasePrice)
	if index == state.reward_offers.size():
		state.reward_offers.append(offer)
	else:
		state.reward_offers[index] = offer
	state.next_offer_id += 1
