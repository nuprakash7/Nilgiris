extends SceneTree
## Three focused payout cases for the user's updated economy.
var catalog: SetupCatalog
var failures: int = 0
func _initialize() -> void:
	catalog = FullRun.create_catalog(SetupCatalog.load_directory())
	ordinary_round()
	overflow_round()
	incomplete_round()
	print("Round Gold: three focused cases, %d failures." % failures)
	quit(1 if failures else 0)

func expect(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func fresh() -> RoundRules:
	var state := RunSetup.create(catalog, 42)
	state.phase = &"playing"
	state.hand.clear()
	state.integrity = 0
	state.intent.attackId = "reward-47-cloud-wall"
	var rules := RoundRules.new(catalog, state)
	for index in range(6): state.hand.append(CardInstance.new("test-%d" % index, "pool-4-heavy-girder"))
	return rules

func fill(rules: RoundRules) -> void:
	for slot in range(5): rules.play_card("test-%d" % slot, slot)

func ordinary_round() -> void:
	var rules := fresh()
	fill(rules)
	expect(rules.state.phase == &"roundComplete" and rules.state.round_result.progress == 27, "95 added minus 68 damage leaves 27 without clearing the room")
	expect(rules.state.gold == 8 and rules.state.round_result.goldPayout == 5, "Ordinary round awards floor(27 / 5) Gold")
	rules.start_next_round()
	expect(rules.state.gold == 8, "Starting the next round neither resets nor repeats payout")

func overflow_round() -> void:
	var rules := fresh()
	rules.state.bridge_progress = 140
	rules.state.progress_bonuses.append({"percent": 20})
	fill(rules)
	expect(rules.state.round_result.progress == 33 and rules.state.gold == 8 and rules.state.round_result.goldPayout == 5, "Progress multipliers and multiple room clears do not multiply Gold")
	rules.start_next_round()
	expect(rules.state.room_index == 3 and rules.state.gold == 8, "Overflow room transitions do not pay again")

func incomplete_round() -> void:
	var rules := fresh()
	rules.state.integrity = 4
	rules._finish_round()
	expect(rules.state.round_result.trialIncomplete and rules.state.round_result.goldPayout == 0 and rules.state.gold == 3, "Incomplete rounds use the same formula and round fractions down")
