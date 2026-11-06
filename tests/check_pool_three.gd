extends SceneTree
## Six small mechanic scenarios; no exhaustive parity or seed sweeps.
var catalog: SetupCatalog
var failures: int = 0

func _initialize() -> void:
	catalog = PoolThree.create_catalog(SetupCatalog.load_directory())
	if "--destroyed-reward-only" in OS.get_cmdline_user_args():
		destroyed_reward()
		print("Destroyed provisional reward: %d failures." % failures)
		quit(1 if failures else 0)
		return
	rain()
	destruction()
	weakening()
	construct_effects()
	animal_blocks()
	animal_card_choices()
	print("Pool 3: six focused scenarios, %d failures." % failures)
	quit(1 if failures else 0)

func expect(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func fresh(attack: String) -> RoundRules:
	var state := RunSetup.create(catalog, 42)
	state.phase = &"playing"
	state.hand.clear()
	state.integrity = 100
	state.intent.attackId = attack
	var rules := RoundRules.new(catalog, state)
	expect(rules.errors.is_empty(), str(rules.errors))
	return rules

func add(rules: RoundRules, id: String, card: String = "heavy-girder") -> void:
	rules.state.hand.append(CardInstance.new(id, card))

func own(rules: RoundRules, id: String) -> void:
	rules.state.animals.append({"instanceId": id, "animalId": id, "nextEligibleRound": 1, "lastActivationRound": null, "effectState": {"activations": 0}})

func rain() -> void:
	var rules := fresh("reward-31-rain-finds-a-gap")
	for id: String in ["a", "b", "c", "spare"]: add(rules, id)
	rules.play_card("a", 2)
	rules.play_card("b", 0)
	expect(rules.state.cells[2].construct.power == 17 and rules.state.rain_slots == [2], "Rain starts after the marking placement")
	rules.play_card("c", 4)
	expect(rules.state.cells[2].construct.power == 16 and rules.state.cells[2].construct.integrity_added == 17 and rules.state.integrity == 150, "Later rain reduces live power/pool, preserving Added")

func destruction() -> void:
	var rules := fresh("reward-35-elephant-at-the-worksite")
	add(rules, "a")
	add(rules, "spare")
	rules.play_card("a", 0)
	own(rules, "elephant-mother-and-calf")
	rules.activate_animal("elephant-mother-and-calf")
	rules.resolve_choice("a")
	var before: int = rules.state.integrity
	ForestEffects._charge(rules.state, catalog)
	expect(rules.state.cells[0].construct.card_id == "heavy-girder" and rules.state.cells[0].construct.destruction_protection == 0, "Protect consumes one destruction attempt without retargeting")
	ForestEffects._charge(rules.state, catalog)
	expect(rules.state.cells[0].construct.card_id == "debris" and rules.state.exiled[0].instance_id == "a" and rules.state.integrity == before, "Charge exiles exact copy, adds occupied Debris and keeps Integrity")

func weakening() -> void:
	var rules := fresh("reward-39-shifting-soil")
	for id: String in ["a", "b", "c", "spare"]: add(rules, id)
	rules.play_card("a", 0)
	rules.play_card("b", 1)
	expect(rules.hand_power("c") == 16 and rules.state.hand[0].weakness == 1, "Shaky Ground weakens only current hand")
	add(rules, "fresh")
	expect(rules.hand_power("fresh") == 17, "Later cards are not weakened retroactively")
	rules._finish_round()
	expect(rules.state.discard_pile.all(func(card: CardInstance) -> bool: return card.weakness == 0), "Weakness clears at round end")

func construct_effects() -> void:
	var rules := fresh("reward-31-rain-finds-a-gap")
	add(rules, "a")
	add(rules, "b", "load-sharing-frame")
	add(rules, "c", "travelling-crane")
	add(rules, "spare")
	rules.play_card("a", 0)
	rules.play_card("b", 1)
	var before: int = rules.state.cells[0].construct.power
	rules.activate_flair("b")
	expect(rules.state.cells[0].construct.power == before + 2 and rules.state.cells[1].construct.flair_spent, "Support-all Flair supports other copies")
	rules.play_card("c", 4)
	rules.resolve_choice("a")
	expect(not rules.state.pending_choice.is_empty(), "Two-Bounce card opens its second choice")
	rules.resolve_choice("b")
	expect(rules.state.cells[0].construct == null and rules.state.cells[1].construct == null and rules.state.pending_choice.is_empty(), "Both optional bounces finish before the placement settles")

func animal_blocks() -> void:
	var rules := fresh("reward-34-deepening-downpour")
	for id: String in ["a", "b", "c", "spare"]: add(rules, id)
	own(rules, "bengal-monitor")
	own(rules, "elephant-herd")
	rules.activate_animal("bengal-monitor")
	rules.activate_animal("elephant-herd")
	rules.play_card("a", 0)
	rules.play_card("b", 1)
	rules.play_card("c", 3)
	expect(rules.state.forest_impacts.back().damage == 2 and rules.state.half_next_hit.is_empty() and rules.state.hit_protection.size() == 1, "Half-next-hit applies before persistent per-hit Block")
	expect(not rules.activate_animal("bengal-monitor").is_empty(), "Animal cannot be reused in the same round")

func animal_card_choices() -> void:
	var rules := fresh("reward-31-rain-finds-a-gap")
	add(rules, "a")
	add(rules, "spare")
	rules.play_card("a", 0)
	own(rules, "giant-squirrel-pair")
	rules.activate_animal("giant-squirrel-pair")
	rules.resolve_choice("a")
	expect(rules.contribution("a", 0) == 20, "Squirrel Bounce grants a one-placement bonus")
	rules.state.discard_pile.append(CardInstance.new("recover", "heavy-girder"))
	own(rules, "stripe-necked-mongoose")
	rules.activate_animal("stripe-necked-mongoose")
	rules.resolve_choice("recover")
	expect(rules.hand_power("recover") == 17, "Mongoose recovers a discard card")
	rules.state.draw_pile.clear()
	rules.state.draw_pile.append(CardInstance.new("search", "heavy-girder"))
	rules.state.draw_pile.append(CardInstance.new("spent", "heavy-girder"))
	rules.state.draw_pile[-1].flair_spent = true
	own(rules, "asian-fairy-bluebird")
	rules.activate_animal("asian-fairy-bluebird")
	expect(rules.state.pending_choice.ids == ["search"], "Bluebird filters unused Flair")
	rules.resolve_choice("search")
	expect(rules.hand_power("search") == 17 and rules.state.pending_choice.is_empty(), "Search moves the chosen card without shuffling")

func destroyed_reward() -> void:
	var rules := fresh("reward-35-elephant-at-the-worksite")
	for id: String in ["trial", "b", "c", "d", "e", "spare"]: add(rules, id)
	rules.state.selected_reward = {"cardId": "heavy-girder", "instanceId": "trial"}
	rules.state.random = RunRandom.new(1)
	rules.play_card("trial", 0)
	rules.play_card("b", 1)
	expect(rules.state.exiled[0].instance_id == "trial", "Seeded Charge destroys the provisional copy")
	rules.play_card("c", 2)
	rules.play_card("d", 3)
	rules.play_card("e", 4)
	expect(rules.state.phase != &"playing" and rules.state.round_result.earnedCardId == "heavy-girder" and not rules.state.deck.any(func(card: CardInstance) -> bool: return card.instance_id == "trial"), "A successful trial never resurrects its destroyed reward")
	expect(rules.state.discard_pile.any(func(card: CardInstance) -> bool: return card.card_id == "debris"), "Replacement Debris survives cleanup")
