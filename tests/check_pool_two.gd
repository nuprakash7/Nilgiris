extends SceneTree
## Seven focused cases; deliberately no exhaustive parity or seed sweep.
var catalog: SetupCatalog
var failures: int = 0

func _initialize() -> void:
	catalog = PoolTwo.create_catalog(SetupCatalog.load_directory())
	if "--bounce-only" in OS.get_cmdline_user_args():
		case_bounce()
	else:
		case_reinforce()
		case_support()
		case_bounce()
		case_flair()
		case_attacks()
		case_transition()
		case_boundary()
	print("Pool 2 focused checks: %d failures." % failures)
	quit(1 if failures else 0)

func expect(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func fresh() -> RoundRules:
	var state := RunSetup.create(catalog, 42)
	state.phase = &"playing"
	state.hand.clear()
	state.integrity = 100
	state.intent.attackId = catalog.attacks[0].id
	var rules := RoundRules.new(catalog, state)
	expect(rules.errors.is_empty(), str(rules.errors))
	return rules

func add(rules: RoundRules, id: String, definition: String) -> void:
	rules.state.hand.append(CardInstance.new(id, definition))

func case_reinforce() -> void:
	var rules := fresh()
	add(rules, "a", "tempered-beam")
	add(rules, "spare", "timber-plank")
	rules.state.instance_play_counts.a = 3
	expect(rules.hand_power("a") == 12, "Reinforce uses this exact copy's prior plays")
	rules.play_card("a", 0)
	expect(rules.state.cells[0].construct.power == 12 and rules.state.reinforce_played_this_round, "Reinforce placement snapshots power before increment")

func case_support() -> void:
	var rules := fresh()
	add(rules, "a", "seasoned-pier")
	add(rules, "b", "timber-plank")
	add(rules, "s", "training-scaffold")
	add(rules, "spare", "timber-plank")
	rules.play_card("a", 0)
	rules.play_card("b", 4)
	var earned: int = rules.state.cells[0].construct.integrity_added
	rules.play_card("s", 2)
	expect(not rules.state.pending_choice.is_empty() and rules.state.constructs_placed_this_round == 2, "Support pauses placement resolution")
	rules.resolve_choice("a")
	expect(rules.state.cells[0].construct.power == 13 and rules.state.cells[0].construct.integrity_added == earned and rules.state.support_used_this_round, "Training Support changes live power and pool, preserving Added")

func case_bounce() -> void:
	var rules := fresh()
	add(rules, "a", "seasoned-pier")
	add(rules, "b", "inspection-gantry")
	add(rules, "spare", "timber-plank")
	rules.play_card("a", 0)
	rules.play_card("b", 1)
	var integrity: int = rules.state.integrity
	rules.resolve_choice("a")
	expect(rules.state.cells[0].construct == null and rules.state.integrity == integrity and rules.hand_power("a") == 8, "Bounce keeps earned Integrity and Reinforce history")
	rules.play_card("a", 0)
	expect(rules.state.round_instance_plays.a == 2, "Bounced copy replay is tracked")

func case_flair() -> void:
	var rules := fresh()
	for id: String in ["a", "b", "spare"]: add(rules, id, "timber-plank")
	add(rules, "d", "travelling-derrick")
	rules.play_card("a", 0)
	rules.play_card("b", 1)
	rules.play_card("d", 3)
	rules.resolve_choice("toggle-flair")
	rules.resolve_choice("a")
	rules.resolve_choice("b")
	rules.resolve_choice("confirm-flair")
	expect(rules.state.cells[0].construct == null and rules.state.cells[1].construct == null and rules.state.cells[3].construct.flair_spent, "Derrick Flair returns exactly two targets and is spent")

func case_attacks() -> void:
	var rules := fresh()
	rules.state.support_used_this_round = true
	rules.state.reinforce_played_this_round = true
	rules.state.round_instance_plays.a = 2
	expect(rules._reduction_applies({"type": "supportUsed"}) and rules._reduction_applies({"type": "reinforcePlayed"}) and rules._reduction_applies({"type": "copyReplayed"}), "Pool 2 history-based reductions")
	for slot: int in [0, 4]: rules.state.cells[slot].construct = PlacedConstruct.new(CardInstance.new(str(slot), "timber-plank"), 6, 1)
	expect(rules._reduction_applies({"type": "endPowerAtLeast", "minimum": 6}), "End reduction uses live power rather than Added")

func case_transition() -> void:
	var rules := fresh()
	rules.state.phase = &"roomComplete"
	rules.state.bridge_progress = int(catalog.config.rooms[0].requiredProgress) + 4
	ConstructOffers.sync_pool(rules.state, catalog)
	var total: int = rules.total_progress()
	expect(rules.start_next_round().is_empty() and rules.state.room_index == 1 and rules.state.bridge_progress == 4 and rules.total_progress() == total and rules.state.reward_pool_id == 2, "Room transition preserves overflow and starts Pool 2")

func case_boundary() -> void:
	var rules := fresh()
	rules.state.phase = &"roundComplete"
	rules.state.reward_pool_id = 3
	expect(not rules.start_next_round().is_empty() and rules.state.round_number == 1, "Pool 3 remains locked")
