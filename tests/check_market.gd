extends SceneTree
## Five focused market/economy cases. No run sweep.
var catalog: SetupCatalog
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func expect(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)
func fresh() -> RoundRules:
	return RoundRules.new(catalog, RunSetup.create(catalog, 42))
func _run() -> void:
	catalog = FullRun.create_catalog(SetupCatalog.load_directory())
	if "--wallet-only" in OS.get_cmdline_user_args():
		bounce_and_carry()
		print("Wallet carry: one focused case; failures=", failures)
		quit(1 if failures else 0)
		return
	setup_contract()
	placement_and_purchases()
	bounce_and_carry()
	draws_and_full_hand()
	habitats_and_pools()
	print("Market: five focused cases; failures=", failures)
	quit(1 if failures else 0)
func setup_contract() -> void:
	var rules := fresh()
	expect(rules.errors.is_empty() and rules.state.phase == &"playing" and rules.state.hand.size() == 7 and rules.state.deck.size() == 20 and rules.state.gold == 3, "Twenty starters, seven opening cards, original starting wallet, no free choice")
	var expected := [4,5,6,7,4,4,5,4,5,10,4,4,4,5,4]
	var ids: Array = catalog.pool(1).cardIds
	var valid: bool = true
	for index in range(ids.size()):
		valid = valid and int(catalog.cards[ids[index]].baseIntegrity) == expected[index] and not catalog.cards[ids[index]].has("flair") and int(catalog.cards[ids[index]].purchasePrice) > 0
	for entry: Dictionary in catalog.config.starterDeck: valid = valid and not catalog.cards[entry.cardId].has("flair") and int(entry.copies) == 5
	expect(valid and rules.state.reward_offers.size() == 4, "Pool 1 Integrity retained, no routine Flair and four priced offers")
func placement_and_purchases() -> void:
	var rules := fresh()
	var state: RunState = rules.state
	state.gold = 5
	state.reward_offers[0] = {"offerId":"target-eight", "cardId":"guide-beam", "price":8}
	var other: Array = state.reward_offers.slice(1).duplicate(true)
	var weak: CardInstance = CardZones.acquire(state, "starter-timber-plank")
	var owned: int = state.deck.size()
	expect(rules.play_card(weak.instance_id, 0).is_empty() and state.gold == 8 and state.integrity == 2, "5 Gold plus weak placement's 3 buys an 8-Gold card")
	catalog.cards["guide-beam"].purchasePrice = 99
	expect(rules.purchase_market("target-eight").is_empty() and state.gold == 0 and state.deck.size() == owned + 1 and state.hand.back().card_id == "guide-beam", "Displayed price fixed; one charge and one owned live copy")
	catalog.cards["guide-beam"].purchasePrice = 8
	expect(state.reward_offers.slice(1) == other and state.reward_offers[0].offerId != "target-eight" and state.forest_impact_sequence == 0, "Only purchased slot refills; purchases never resolve Forest")
	expect(not rules.purchase_market("target-eight").is_empty() and state.deck.size() == owned + 1 and state.gold == 0, "Stale/repeated action cannot charge or grant twice")
	state.gold = 100
	var cost: int = state.reward_offers[0].price
	var id: String = state.reward_offers[0].offerId
	expect(rules.purchase_market(id).is_empty() and state.gold == 100 - cost, "Replacement immediately purchasable in same round")
	cost = state.reward_offers[0].price
	var wallet: int = state.gold
	expect(rules.purchase_market(state.reward_offers[0].offerId).is_empty() and state.gold == wallet - cost and state.deck.size() == owned + 3 and state.reward_offers.slice(1) == other, "Multiple same-round purchases preserve three other offers")
func bounce_and_carry() -> void:
	var rules := fresh()
	var state: RunState = rules.state
	var weak: CardInstance = state.hand[0]
	weak.card_id = "starter-timber-plank"
	state.gold = 0
	expect(not rules.play_card(weak.instance_id, -1).is_empty() and state.gold == 0, "Invalid play pays nothing")
	rules.play_card(weak.instance_id, 0)
	rules._bounce(weak.instance_id)
	rules.play_card(weak.instance_id, 0)
	expect(state.gold == 3, "Bounce/replay cannot farm placement Gold")
	var offers: Array = state.reward_offers.duplicate(true)
	state.integrity = 10
	state.intent.resolvedHitKeys.assign(["0"])
	rules._finish_round()
	expect(state.gold == 3 and state.round_result.goldPayout == 0, "Round end preserves wallet and pays nothing")
	expect(rules.start_next_round().is_empty() and state.phase == &"playing" and state.gold == 3 and state.reward_offers == offers and state.placement_gold_paid.is_empty(), "Next round starts directly; wallet persists; bounty eligibility resets")
func draws_and_full_hand() -> void:
	var rules := fresh()
	var state: RunState = rules.state
	state.gold = 100
	var expected := [1,3,5,7]
	var valid := true
	for cost: int in expected:
		valid = valid and rules.purchased_draw_cost() == cost and rules.purchase_draw().is_empty()
	expect(valid and state.gold == 84, "Paid draws share wallet and retain 1/3/5/7 schedule")
	while state.hand.size() < 12: CardZones.draw(state, 1)
	var owned: int = state.deck.size()
	var discarded: int = state.discard_pile.size()
	var price: int = state.reward_offers[0].price
	expect(rules.purchase_market(state.reward_offers[0].offerId).is_empty() and state.hand.size() == 12 and state.discard_pile.size() == discarded + 1 and state.deck.size() == owned + 1 and state.gold == 84 - price, "Full-hand purchase grants one owned copy to discard")
	state.gold = 0
	owned = state.deck.size()
	expect(not rules.purchase_market(state.reward_offers[1].offerId).is_empty() and state.deck.size() == owned and state.phase == &"playing", "Unaffordable market does not block continued building")
func habitats_and_pools() -> void:
	var rules := fresh()
	var state: RunState = rules.state
	var offers: Array = state.reward_offers.duplicate(true)
	for _round in range(3):
		state.integrity = 1
		state.intent.resolvedHitKeys.clear()
		for index in range(rules.attack_definition().hits.size()): state.intent.resolvedHitKeys.append(str(index))
		rules._finish_round()
		rules.start_next_round()
	expect(state.habitat_batch.size() == 3 and state.reward_round_type == &"animal" and state.phase == &"roundChoice" and state.animal_offers.size() == 4 and state.reward_offers == offers, "Habitats/animal trial progress without purchases; market stays visible and stable")
	state.bridge_progress = 60
	ConstructOffers.sync_pool(state, catalog)
	expect(state.construct_offer_pool_id == 2 and state.reward_offers.all(func(offer: Dictionary) -> bool: return catalog.pool(2).cardIds.has(offer.cardId) and int(offer.price) > 0), "Pool transition refreshes priced market independently of animal choice")
