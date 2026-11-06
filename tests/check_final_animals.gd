extends SceneTree
## Six focused cases for final roster and small gameplay-completeness fixes.
var catalog: SetupCatalog
var failures: int = 0
func _initialize() -> void:
	catalog = FullRun.create_catalog(SetupCatalog.load_directory())
	marten_search()
	marten_pair()
	rusty_sequence()
	panther_mark()
	rani_protection()
	content_contract()
	print("Final animals: six focused cases, %d failures." % failures)
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
	for slot in range(int(rules.attack_definition().get("boardSize", 5))): state.cells.append({"slotIndex": slot, "construct": null})
	return rules

func add(rules: RoundRules, id: String, definition: String = "monolithic-pier") -> void:
	rules.state.hand.append(CardInstance.new(id, definition))

func own(rules: RoundRules, id: String) -> void:
	rules.state.animals.append({"instanceId": id, "animalId": id, "nextEligibleRound": 1, "lastActivationRound": null, "effectState": {"activations": 0}})

func marten_search() -> void:
	var rules := fresh()
	add(rules, "spare")
	rules.state.draw_pile.clear()
	rules.state.draw_pile.append(CardInstance.new("a", "monolithic-pier"))
	rules.state.draw_pile.append(CardInstance.new("b", "mountain-abutment"))
	own(rules, "nilgiri-marten")
	rules.activate_animal("nilgiri-marten")
	rules.resolve_choice("a")
	rules.resolve_choice("b")
	expect(rules.contribution("a", 0) == 28 and rules.contribution("b", 0) == 32 and rules.state.pending_choice.is_empty(), "Marten searches two cards and grants each a next-placement +4")

func marten_pair() -> void:
	var rules := fresh()
	for id: String in ["a", "b", "spare"]: add(rules, id)
	own(rules, "nilgiri-marten-pair")
	rules.activate_animal("nilgiri-marten-pair")
	rules.resolve_choice("a")
	rules.resolve_choice("b")
	expect(rules.contribution("a", 0) == 48 and rules.contribution("b", 0) == 48 and rules.contribution("spare", 0) == 24, "Pair doubles exactly the two selected copies")
	rules.play_card("a", 0)
	expect(rules.state.cells[0].construct.next_placement_multiplier == 1.0, "Next-placement multiplier is consumed")

func rusty_sequence() -> void:
	var rules := fresh()
	add(rules, "placed")
	add(rules, "spare")
	rules.play_card("placed", 0)
	rules.state.draw_pile.clear()
	rules.state.draw_pile.append(CardInstance.new("found", "mountain-abutment"))
	var gold: int = rules.state.gold
	own(rules, "rusty-spotted-cat")
	rules.activate_animal("rusty-spotted-cat")
	rules.resolve_choice("placed")
	expect(rules.state.pending_choice.effect.action == "search" and rules.state.gold == gold, "Rusty Cat pauses its sequence at Search")
	rules.resolve_choice("found")
	expect(rules.hand_power("placed") == 24 and rules.hand_power("found") == 28 and rules.state.gold == gold + 1 and rules.state.animal_effects.is_empty(), "Bounce, Search and Gold settle in order")

func panther_mark() -> void:
	var rules := fresh()
	add(rules, "marked")
	add(rules, "other")
	own(rules, "ghost-of-the-nilgiris-black-panther")
	rules.activate_animal("ghost-of-the-nilgiris-black-panther")
	rules.resolve_choice("marked")
	expect(rules.contribution("marked", 0) == 36 and rules.contribution("other", 0) == 24 and rules.hand_power("marked") == 24, "Panther's 1.5 multiplier changes contribution of one physical copy")
	rules.play_card("marked", 0)
	rules._bounce("marked")
	expect(rules.contribution("marked", 0) == 36, "Permanent mark survives board-to-hand copying")
	rules._finish_round()
	var copy: CardInstance = CardZones.find_live(rules.state, "marked")
	expect(copy.permanent_integrity_multiplier == 1.5, "Mark survives round cleanup")
	rules.start_next_round()
	expect(not rules.activate_animal("ghost-of-the-nilgiris-black-panther").is_empty(), "Once-per-run Panther cannot be reactivated next round")

func rani_protection() -> void:
	var rules := fresh("reward-75-nilgiri-thunderstorm", 0)
	add(rules, "zero-a", "debris")
	add(rules, "zero-b", "debris")
	for id: String in ["c", "d", "e", "f", "g", "spare"]: add(rules, id, "mountain-abutment")
	own(rules, "rani-with-her-cubs")
	rules.activate_animal("rani-with-her-cubs")
	rules.play_card("zero-a", 0)
	rules.play_card("zero-b", 1)
	expect(rules.state.integrity == 1 and rules.state.grace.is_empty(), "Rani's Grace leaves 1 after the first lethal hit")
	for slot in range(2, 7): rules.play_card(["c", "d", "e", "f", "g"][slot - 2], slot)
	expect(rules.state.intent.lightningStrikes == 2 and rules.state.exiled.is_empty() and rules.state.phase != &"lost", "Rani prevents both seeded Lightning destruction attempts")
	expect(not rules.state.prevent_destruction, "Round-long protection clears at cleanup")

func content_contract() -> void:
	expect(catalog.cards.size() == 80 and catalog.attacks.size() == 75 and catalog.wildlife.animals.size() == 75 and RoundContent.validate(catalog).is_empty(), "Complete 80-card/75-attack/75-animal content is enabled and accepted")
	var altered: SetupCatalog = FullRun.create_catalog(SetupCatalog.load_directory())
	altered.cards.debris.unsupportedMechanic = true
	expect(not RoundContent.validate(altered).is_empty(), "Special Debris content fails closed on unsupported rules")
