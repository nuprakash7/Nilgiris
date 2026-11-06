extends SceneTree
## Five focused mechanic cases; no parity or seed sweep.
var catalog: SetupCatalog
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func expect(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)
func fixture() -> RoundRules:
	var run := RunSetup.create(catalog)
	run.phase = &"playing"
	run.selected_reward.clear()
	run.hand.clear()
	run.draw_pile.clear()
	run.discard_pile.clear()
	run.deck.clear()
	run.integrity = 100
	var rules := RoundRules.new(catalog, run)
	rules._attack = {"name": "Test", "hits": [{"damage": 0, "when": {"type": "fullBoard"}}], "weatherDelta": {"wet": 0, "windy": 0}}
	run.intent = {"resolvedHitKeys": [], "resolved": false}
	for index in range(8): run.hand.append(CardInstance.new("filler-%d" % index, "starter-timber-plank"))
	return rules
func add(rules: RoundRules, id: String, name: String) -> CardInstance:
	var card := CardInstance.new(name, id)
	rules.state.hand.push_front(card)
	rules.state.deck.append(card.plain_copy())
	return card
func place(rules: RoundRules, card: CardInstance, slot: int) -> void:
	expect(rules.play_card(card.instance_id, slot).is_empty(), "Fixture placement")
func _run() -> void:
	catalog = FullRun.create_catalog(SetupCatalog.load_directory())
	if "--hefty-only" in OS.get_cmdline_user_args():
		hefty_next_hit()
		print("Hefty targeted check: failures=", failures)
		quit(1 if failures else 0)
		return
	permanent_copies()
	utility_flairs()
	borrow_integrity()
	placement_chain()
	hefty_next_hit()
	print("Pool 1 redesign: five mechanic cases; failures=", failures)
	quit(1 if failures else 0)
func permanent_copies() -> void:
	var rules := fixture()
	expect(rules.errors.is_empty(), "Full catalog accepts redesigned mechanics")
	var card := add(rules, "timber-plank", "enhanced")
	place(rules, card, 0)
	var before: int = rules.state.integrity
	expect(rules.activate_flair(card.instance_id).is_empty() and rules.state.integrity == before + 2 and rules.state.cells[0].construct.power == 6, "Permanent Flair updates current pool and copy")
	expect(not rules.activate_flair(card.instance_id).is_empty(), "Flair remains once per copy")
	var guide := add(rules, "guide-beam", "guide")
	place(rules, guide, 3)
	var target := add(rules, "starter-timber-plank", "upgraded")
	expect(rules.contribution(target.instance_id, 2) == 5 and target.permanent_power_bonus == 0, "Permanent coupon preview does not mutate")
	place(rules, target, 2)
	expect(rules.state.cells[2].construct.power == 5 and rules.state.cells[2].construct.permanent_power_bonus == 1 and rules.state.cells[3].construct.neighbor_permanent_bonus == 0, "Guide permanently upgrades only next adjacent copy")
	rules._bounce(target.instance_id)
	place(rules, target, 2)
	expect(rules.state.cells[2].construct.permanent_power_bonus == 1, "Guide coupon never repeats after bounce")
	rules._finish_round()
	var live: CardInstance = CardZones.find_live(rules.state, card.instance_id)
	var upgraded: CardInstance = CardZones.find_live(rules.state, target.instance_id)
	expect(live.permanent_power_bonus == 2 and live.flair_spent and upgraded.permanent_power_bonus == 1 and catalog.cards["timber-plank"].baseIntegrity == 4, "Cleanup preserves exact-copy upgrades, not definitions")
	CardZones.draw(rules.state, 12)
	expect(rules.card_power(CardZones.find_live(rules.state, card.instance_id)) == 6, "Upgrade survives reshuffle")
func utility_flairs() -> void:
	var rules := fixture()
	var cross := add(rules, "cross-tie", "cross")
	place(rules, rules.state.hand.back(), 0)
	place(rules, cross, 1)
	place(rules, rules.state.hand.back(), 2)
	for index in range(5): rules.state.draw_pile.append(CardInstance.new("draw%d" % index, "starter-iron-spike"))
	var count: int = rules.state.hand.size()
	expect(rules.activate_flair(cross.instance_id).is_empty() and rules.state.hand.size() == count + 2, "Cross Tie draws once per occupied neighbour")
	var lone := add(rules, "pool-1-lone-pier", "lone")
	place(rules, lone, 4)
	count = rules.state.hand.size()
	expect(rules.activate_flair(lone.instance_id).is_empty() and rules.state.pending_choice.kind == "flairDiscard" and rules.state.hand.size() == count, "Lone Pier opens mandatory discard before draw")
	var discarded: String = rules.state.hand[0].instance_id
	expect(rules.resolve_choice(discarded).is_empty() and rules.state.hand.size() == count + 1 and rules.state.discard_pile.back().instance_id == discarded, "Discard selection then draws two")
	# Open a slot without changing the current round.
	rules._bounce(lone.instance_id)
	var edge := add(rules, "end-bearing", "edge")
	place(rules, edge, 4)
	while rules.state.hand.size() > 9: rules.state.hand.pop_back()
	rules.state.discard_pile.append(CardInstance.new("older", "stone-footing"))
	rules.state.discard_pile.append(CardInstance.new("latest", "steel-girder"))
	expect(rules.activate_flair(edge.instance_id).is_empty() and rules.state.hand[-2].instance_id == "latest" and rules.state.hand[-1].instance_id == "older", "Edge Clasps recovers the two newest discards")
	var draw_rules := fixture()
	var spike := add(draw_rules, "starter-iron-spike", "spike")
	place(draw_rules, spike, 0)
	draw_rules.state.draw_pile.append(CardInstance.new("one", "stone-footing"))
	count = draw_rules.state.hand.size()
	expect(draw_rules.activate_flair(spike.instance_id).is_empty() and draw_rules.state.hand.size() == count + 1, "Starter spike Flair draws one")
func borrow_integrity() -> void:
	var rules := fixture()
	var steel := add(rules, "steel-girder", "steel")
	place(rules, steel, 0)
	rules.state.hand.clear()
	var staging := add(rules, "staging-deck", "borrowed")
	staging.permanent_power_bonus = 2
	var before: int = rules.state.integrity
	expect(rules.activate_flair(steel.instance_id).is_empty() and rules.state.integrity == before + 7 and rules.hand_power(staging.instance_id) == 0, "Borrow current modified Integrity and mark exact hand copy zero")
	rules.state.hand.append(CardInstance.new("keep", "starter-timber-plank"))
	var gold: int = rules.state.gold
	place(rules, staging, 1)
	expect(rules.state.integrity == before + 7 and rules.state.gold == gold + 3 and rules.state.cells[1].construct.integrity_added == 0, "Zero card still resolves Gold, never placement Integrity")
	rules._bounce(staging.instance_id)
	expect(rules.contribution(staging.instance_id, 1) == 0, "Zero follows copy through bounce")
	rules._finish_round()
	expect(not CardZones.find_live(rules.state, staging.instance_id).zero_integrity_this_round and rules.card_power(CardZones.find_live(rules.state, staging.instance_id)) == 7, "Zero expires at cleanup, permanent bonus survives")
func placement_chain() -> void:
	var rules := fixture()
	var span := add(rules, "starter-cross-tie", "span")
	expect(rules.contribution(span.instance_id, 2) == 6 and rules.contribution(span.instance_id, 1) == 3, "Starter Span Support positional bonus")
	place(rules, rules.state.hand.back(), 0)
	place(rules, rules.state.hand.back(), 1)
	var layered := add(rules, "pool-1-layered-support", "layered")
	expect(rules.contribution(layered.instance_id, 2) == 8 and rules.contribution(layered.instance_id, 4) == 4, "Consecutive adjacent chain includes placement link, break resets")
	place(rules, layered, 4)
	expect(rules.state.adjacent_chain_links == 0, "Non-adjacent placement resets chain")
	var close := add(rules, "pool-1-closing-keystone", "close")
	rules.state.hand.assign([close])
	expect(rules.contribution(close.instance_id, 3) == 8, "Closing Keystone recognizes final hand placement")
func hefty_next_hit() -> void:
	var rules := fixture()
	rules._attack.hits = [{"damage": 3, "when": {"type": "slotCount", "count": 2}}, {"damage": 5, "when": {"type": "fullBoard"}}]
	var hefty := add(rules, "centre-pier", "hefty")
	place(rules, hefty, 0)
	expect(rules.state.next_forest_damage_bonus == 4 and rules.state.integrity == 110, "Hefty contributes ten and arms four damage")
	place(rules, rules.state.hand.back(), 1)
	expect(rules.state.forest_impacts.back().damage == 7 and rules.state.next_forest_damage_bonus == 0, "Only next scheduled hit consumes the bonus")
	for index in range(2, 5): place(rules, rules.state.hand.back(), index)
	expect(rules.state.forest_impact_sequence == 2 and rules.state.forest_impacts.back().damage == 5 and rules.state.phase in [&"roundComplete", &"roomComplete"], "Later hit unchanged, cleanup occurs normally")
