extends SceneTree
## Two focused cases for changed Pool 2 behaviour.
var catalog: SetupCatalog
var failures := 0
func _initialize() -> void:
	catalog = FullRun.create_catalog(SetupCatalog.load_directory())
	support_history()
	seventh_placement()
	bounce_draw()
	print("Pool 5 revision: three focused cases; failures=", failures)
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
func support_history() -> void:
	var rules := fixture()
	rules.state.cells[0].construct = PlacedConstruct.new(CardInstance.new("target","starter-timber-plank"),2,2)
	add(rules,"framework","pool-5-seasoned-framework")
	rules.play_card("framework",1)
	expect(rules.state.cells[0].construct.power == 8, "First Support grants six, not ten")
	rules._bounce("framework")
	rules.play_card("framework",1)
	expect(rules.state.cells[0].construct.power == 18, "Already supported target receives ten on later placement")
	expect(rules.state.gold == 10, "Framework replay does not duplicate placement Gold")
func seventh_placement() -> void:
	var rules := fixture()
	add(rules,"keystone","final-keystone")
	rules.state.constructs_placed_this_round = 5
	expect(rules.contribution("keystone",0) == 11, "Sixth placement has no Keystone bonus")
	rules.state.constructs_placed_this_round = 6
	expect(rules.contribution("keystone",0) == 27, "Seventh placement grants sixteen, independent of physical slot")
	for slot in [1,3]: rules.state.cells[slot].construct = PlacedConstruct.new(CardInstance.new("target%d" % slot,"starter-timber-plank"),2,2)
	add(rules,"truss","crowning-truss")
	rules.play_card("truss",2)
	expect(rules.state.cells[1].construct.power == 14 and rules.state.cells[3].construct.power == 14, "Seventh Truss grants twelve to each adjacent Construct")
func bounce_draw() -> void:
	var rules := fixture()
	for entry in [["immune","return-gantry",0],["immune2","reconstruction-crane",1],["a","starter-timber-plank",2],["b","starter-timber-plank",3]]:
		rules.state.cells[entry[2]].construct = PlacedConstruct.new(CardInstance.new(entry[0],entry[1]),2,2)
	expect(rules._construct_targets({"type":"bounce","target":"any"},4) == ["a","b"] and rules.animals.targets({"action":"bounce"}).size() == 2, "Both new immune cards excluded from Construct and animal Bounce")
	# Keep an empty slot so placement does not complete the board before optional Bounce.
	rules.state.cells[1].construct = null
	add(rules,"crane","reconstruction-crane")
	for index in range(3): rules.state.draw_pile.append(CardInstance.new("draw%d" % index,"starter-iron-spike"))
	rules.play_card("crane",4)
	expect(rules.resolve_choice("a").is_empty() and rules.state.draw_pile.size() == 2, "First return draws exactly one")
	expect(rules.resolve_choice("b").is_empty() and rules.state.draw_pile.size() == 1 and rules.state.pending_choice.is_empty(), "Second return draws exactly one and ends selection")
	rules._bounce("crane")
	expect(rules.state.cells[4].construct != null, "Crane immunity enforced at mutation")
