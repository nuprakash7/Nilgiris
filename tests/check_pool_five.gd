extends SceneTree
## Seven small scenarios; no exhaustive parity or seed sweep.
var catalog: SetupCatalog
var failures: int = 0
func _initialize() -> void:
	catalog = PoolFive.create_catalog(SetupCatalog.load_directory())
	seventh_placement()
	multipliers()
	neighbor_override()
	distinct_search()
	grace_followup()
	lightning_and_win()
	adjacent_draw()
	print("Pool 5: seven focused scenarios, %d failures." % failures)
	quit(1 if failures else 0)

func expect(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func fresh(attack: String = "reward-61-the-mountain-roars", integrity: int = 100) -> RoundRules:
	var state := RunSetup.create(catalog, 42)
	state.phase = &"playing"
	state.hand.clear()
	state.integrity = integrity
	state.intent.attackId = attack
	var rules := RoundRules.new(catalog, state)
	expect(rules.errors.is_empty(), str(rules.errors))
	state.cells.clear()
	for slot in range(int(rules.attack_definition().get("boardSize", 5))):
		state.cells.append({"slotIndex": slot, "construct": null})
	return rules

func add(rules: RoundRules, id: String, card: String = "monolithic-pier") -> void:
	rules.state.hand.append(CardInstance.new(id, card))

func own(rules: RoundRules, id: String) -> void:
	rules.state.animals.append({"instanceId": id, "animalId": id, "nextEligibleRound": 1, "lastActivationRound": null, "effectState": {"activations": 0}})

func seventh_placement() -> void:
	var rules := fresh()
	add(rules, "keystone", "final-keystone")
	add(rules, "truss", "crowning-truss")
	add(rules, "spare")
	rules.state.constructs_placed_this_round = 6
	rules.state.cells[2].construct = PlacedConstruct.new(CardInstance.new("left", "monolithic-pier"), 24, 24)
	rules.state.cells[4].construct = PlacedConstruct.new(CardInstance.new("right", "monolithic-pier"), 24, 24)
	expect(rules.contribution("keystone", 3) == 25, "Seventh-placement Keystone earns +16")
	rules.play_card("truss", 3)
	expect(rules.state.cells[2].construct.power == 36 and rules.state.cells[4].construct.power == 36, "Seventh-placement Truss Supports each adjacent copy by 12")

func multipliers() -> void:
	var rules := fresh("reward-26-waterlogged-centre")
	add(rules, "a")
	add(rules, "spare")
	own(rules, "male-tiger")
	rules.activate_animal("male-tiger")
	expect(rules.contribution("a", 2) == 45, "Multiplier applies before the one-time slot penalty")
	rules.play_card("a", 2)
	expect(rules.state.cells[2].construct.power == 24 and rules.state.placement_bonuses.is_empty(), "Tiger doubles contribution once, without doubling power")
	own(rules, "leopard")
	rules.activate_animal("leopard")
	rules.resolve_choice("a")
	expect(rules.contribution("a", 2) == 48, "Leopard arms an exact-copy multiplier, preserving spent slot penalty")
	rules.play_card("a", 2)
	expect(rules.state.cells[2].construct.next_placement_multiplier == 1.0, "Exact-copy multiplier is consumed on placement")

func neighbor_override() -> void:
	var rules := fresh()
	add(rules, "arch", "tempered-arch")
	add(rules, "spare")
	own(rules, "leopard-cat")
	rules.activate_animal("leopard-cat")
	rules.resolve_choice("arch")
	expect(rules.contribution("arch", 0) == 19, "Leopard Cat satisfies both-neighbor condition even at an end")
	rules.play_card("arch", 0)
	expect(not rules.state.cells[0].construct.satisfy_neighbor_conditions, "Neighbor override is consumed")

func distinct_search() -> void:
	var rules := fresh()
	add(rules, "spare")
	rules.state.draw_pile.clear()
	rules.state.draw_pile.append(CardInstance.new("a", "monolithic-pier"))
	rules.state.draw_pile.append(CardInstance.new("duplicate", "monolithic-pier"))
	rules.state.draw_pile.append(CardInstance.new("b", "mountain-abutment"))
	own(rules, "lion-tailed-macaque")
	rules.activate_animal("lion-tailed-macaque")
	rules.resolve_choice("a")
	expect(rules.state.pending_choice.ids == ["b"], "Macaque removes all copies of the first selected definition")
	rules.resolve_choice("b")
	expect(rules.state.pending_choice.is_empty() and rules.state.draw_pile[0].instance_id == "duplicate", "Search draws two distinct definitions without shuffling")

func grace_followup() -> void:
	var rules := fresh("reward-69-the-sky-cracks-open", 0)
	add(rules, "zero", "debris")
	add(rules, "spare")
	own(rules, "king-cobra")
	rules.activate_animal("king-cobra")
	rules.play_card("zero", 0)
	expect(rules.state.integrity == 6 and rules.contribution("spare", 1) == 30, "Cobra Grace survives at 6 and queues +6 for next placement")
	var other := fresh("reward-69-the-sky-cracks-open", 0)
	add(other, "zero", "debris")
	add(other, "spare")
	var count: int = other.state.hand.size()
	own(other, "tigress-with-cubs")
	own(other, "indian-rock-python")
	other.activate_animal("tigress-with-cubs")
	other.activate_animal("indian-rock-python")
	other.play_card("zero", 0)
	expect(other.state.forest_impacts[-1].damage == 6 and other.state.integrity == 8 and other.state.hand.size() == count + 1, "Python halves odd damage down in Block; Tigress Grace then draws two")

func lightning_and_win() -> void:
	var rules := fresh("reward-75-nilgiri-thunderstorm", 100)
	rules.state.room_index = 4
	for i in range(8): add(rules, "p%d" % i, "mountain-abutment")
	for slot in range(7): rules.play_card("p%d" % slot, slot)
	expect(rules.state.intent.lightningStrikes == 2 and rules.state.exiled.size() == 2, "Final storm makes two seeded permanent destruction attempts")
	expect(rules.state.phase == &"won" and rules.state.forest_impacts.size() == 4 and rules.state.discard_pile.filter(func(card: CardInstance) -> bool: return card.card_id == "debris").size() == 2, "Seven-slot final storm resolves all hits and reaches the run win flow")

func adjacent_draw() -> void:
	var rules := fresh()
	add(rules, "reinforce", "tempered-arch")
	add(rules, "survey", "survey-platform")
	add(rules, "brace", "great-counterbrace")
	add(rules, "assembly", "pool-5-master-assembly")
	add(rules, "spare")
	rules.play_card("reinforce", 0)
	var hand_count: int = rules.state.hand.size()
	rules.play_card("survey", 1)
	expect(rules.state.hand.size() == hand_count + 1, "Survey Platform draws two beside Reinforce")
	rules.play_card("brace", 2)
	expect(rules.state.cells[1].construct.power == 21 and rules.state.cells[0].construct.power == 9, "Counterbrace Supports only its immediate left")
	rules.state.round_instance_plays.reinforce = 2
	rules.play_card("assembly", 4)
	rules.resolve_choice("reinforce")
	expect(rules.state.cells[0].construct.power == 25, "Master Assembly uses replayed-copy Support amount")
