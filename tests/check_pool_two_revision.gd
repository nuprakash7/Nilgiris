extends SceneTree
## Two focused cases for changed Pool 2 behaviour.
var catalog: SetupCatalog
var failures := 0
func _initialize() -> void:
	catalog = FullRun.create_catalog(SetupCatalog.load_directory())
	targeting()
	replay_and_draw()
	print("Pool 2 revision: two focused cases; failures=", failures)
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
func targeting() -> void:
	var rules := fixture()
	for slot in [0,1,4]: rules.state.cells[slot].construct = PlacedConstruct.new(CardInstance.new("built%d" % slot,"starter-timber-plank"),2,2)
	add(rules,"scaffold","training-scaffold")
	expect(rules.play_card("scaffold",2).is_empty() and rules.state.pending_choice.ids == ["built0","built4"], "Scaffold permits exactly the occupied edge slots")
	expect(not rules.resolve_choice("built1").is_empty(), "Interior target rejected without resolving choice")
	expect(rules.resolve_choice("built4").is_empty() and rules.state.cells[4].construct.power == 8, "Chosen edge receives Support 6")
	var left := fixture()
	left.state.cells[1].construct = PlacedConstruct.new(CardInstance.new("left","starter-timber-plank"),2,2)
	left.state.cells[3].construct = PlacedConstruct.new(CardInstance.new("right","starter-timber-plank"),2,2)
	add(left,"assembly","seasoned-assembly")
	expect(left.play_card("assembly",2).is_empty() and left.state.cells[1].construct.power == 6 and left.state.cells[3].construct.power == 2, "Assembly supports left only by four")
func replay_and_draw() -> void:
	var rules := fixture()
	add(rules,"shared","shared-foundation")
	var gold: int = rules.state.gold
	rules.play_card("shared",0)
	rules._bounce("shared")
	expect(rules.hand_power("shared") == 11, "Shared Foundation gains Reinforce 3 on replay")
	rules.play_card("shared",0)
	expect(rules.state.gold == gold + 3, "Replay does not duplicate placement Gold")
	var draw := fixture()
	add(draw,"crew","finishing-crew")
	draw.state.draw_pile.append(CardInstance.new("draw0","starter-iron-spike"))
	draw.state.draw_pile.append(CardInstance.new("draw1","starter-iron-spike"))
	var hand: int = draw.state.hand.size()
	expect(draw.play_card("crew",0).is_empty() and draw.state.hand.size() == hand + 1 and not draw.state.support_used_this_round and draw.state.gold == 5, "Crew draws two and earns two without prior Support")
	var derrick := fixture()
	derrick.state.cells[0].construct = PlacedConstruct.new(CardInstance.new("return","starter-timber-plank"),2,2)
	add(derrick,"derrick","travelling-derrick")
	derrick.state.draw_pile.append(CardInstance.new("stay","starter-iron-spike"))
	derrick.play_card("derrick",2)
	expect(derrick.resolve_choice("return").is_empty() and derrick.state.draw_pile.size() == 1, "Derrick Bounce no longer draws")
