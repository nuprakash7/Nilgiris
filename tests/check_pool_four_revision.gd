extends SceneTree
## Two focused cases for changed Pool 2 behaviour.
var catalog: SetupCatalog
var failures := 0
func _initialize() -> void:
	catalog = FullRun.create_catalog(SetupCatalog.load_directory())
	gold_bonus()
	conditional_integrity()
	bounce_rules()
	print("Pool 4 revision: three focused cases; failures=", failures)
	quit(1 if failures else 0)
func expect(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func fixture() -> RoundRules:
	var state := RunSetup.create(catalog)
	state.hand.clear()
	state.draw_pile.clear()
	state.discard_pile.clear()
	state.integrity = 100
	var rules := RoundRules.new(catalog, state)
	rules._attack = {"name":"Test", "hits":[{"damage":0,"when":{"type":"fullBoard"}}],"weatherDelta":{"wet":0,"windy":0}}
	state.intent = {"resolvedHitKeys":[],"resolved":false}
	state.hand.append(CardInstance.new("spare", "starter-timber-plank"))
	expect(rules.errors.is_empty(), "Full catalog accepts edge Support")
	return rules
func add(rules: RoundRules, id: String, card_id: String) -> void:
	rules.state.hand.append(CardInstance.new(id, card_id))
func gold_bonus() -> void:
	var rules := fixture()
	add(rules,"earner","supply-platform")
	add(rules,"girder","pool-4-heavy-girder")
	rules.play_card("earner",0)
	rules.play_card("girder",1)
	expect(rules.state.gold == 15, "Seven placement Gold enables Girder base three plus two")
	rules._bounce("girder")
	rules.play_card("girder",1)
	expect(rules.state.gold == 15, "Replay cannot farm base or conditional Gold")
	rules._reset_round_hazards()
	expect(rules.state.placement_gold_earned.is_empty() and rules.state.placement_gold_bonus_paid.is_empty(), "Gold history resets each round")
	var early := fixture()
	add(early,"girder","pool-4-heavy-girder")
	early.play_card("girder",0)
	expect(early.state.gold == 6, "Girder cannot qualify itself or use the wallet as placement history")
func conditional_integrity() -> void:
	var rules := fixture()
	for slot in [1,3]: rules.state.cells[slot].construct = PlacedConstruct.new(CardInstance.new("reinforced%d" % slot,"tempered-column"),14,14)
	add(rules,"column","tempered-column")
	expect(rules.contribution("column",2) == 18, "Adjacent Reinforce bonus applies once even with two neighbours")
	var closing := fixture()
	for slot in range(4): closing.state.cells[slot].construct = PlacedConstruct.new(CardInstance.new("built%d" % slot,"starter-timber-plank"),2,2)
	add(closing,"arch","closing-arch")
	expect(closing.contribution("arch",4) == 20, "Closing Arch normal last-slot bonus is eight")
	closing.state.support_used_this_round = true
	expect(closing.contribution("arch",4) == 24, "Earlier Support replaces eight with twelve")
func bounce_rules() -> void:
	var rules := fixture()
	for entry in [["immune","recovery-derrick",0],["immune2","dismantling-gantry",1],["ordinary","starter-timber-plank",2]]:
		rules.state.cells[entry[2]].construct = PlacedConstruct.new(CardInstance.new(entry[0],entry[1]),2,2)
	expect(rules._construct_targets({"type":"bounce","target":"any"},4) == ["ordinary"], "Construct Bounce excludes both immune cards")
	expect(rules.animals.targets({"action":"bounce"}).size() == 1 and rules.animals.targets({"action":"protect"}).size() == 3, "Animal Bounce excludes immune cards but protection still works")
	rules._bounce("immune")
	expect(rules.state.cells[0].construct != null, "Direct Bounce also enforces immunity")
	rules._bounce("ordinary")
	rules.play_card("ordinary",2)
	rules._support("ordinary",{"amount":4,"bouncedAmount":8})
	expect(rules.state.cells[2].construct.power == 10, "Bounced and replayed target receives eight Support")
	rules._reset_round_hazards()
	expect(rules.state.bounced_instance_ids.is_empty(), "Bounce history expires with round")
