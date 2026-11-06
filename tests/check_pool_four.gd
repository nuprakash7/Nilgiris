extends SceneTree
## Six focused scenarios; no exhaustive parity or seed sweep.
var catalog: SetupCatalog
var failures: int = 0

func _initialize() -> void:
	catalog = PoolFour.create_catalog(SetupCatalog.load_directory())
	escalating_bonus()
	shared_and_counted_block()
	grace_survival()
	progress_rounding()
	debris_removal()
	search_and_retain()
	print("Pool 4: six focused scenarios, %d failures." % failures)
	quit(1 if failures else 0)

func expect(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func fresh(attack: String = "reward-47-cloud-wall", integrity: int = 100) -> RoundRules:
	var state := RunSetup.create(catalog, 42)
	state.phase = &"playing"
	state.hand.clear()
	state.integrity = integrity
	state.intent.attackId = attack
	var rules := RoundRules.new(catalog, state)
	expect(rules.errors.is_empty(), str(rules.errors))
	return rules

func add(rules: RoundRules, id: String, card: String = "pool-4-heavy-girder") -> void:
	rules.state.hand.append(CardInstance.new(id, card))

func own(rules: RoundRules, id: String) -> void:
	rules.state.animals.append({"instanceId": id, "animalId": id, "nextEligibleRound": 1, "lastActivationRound": null, "effectState": {"activations": 0}})

func escalating_bonus() -> void:
	var rules := fresh()
	for id: String in ["a", "b", "spare"]: add(rules, id)
	own(rules, "dhole-pack")
	rules.activate_animal("dhole-pack")
	expect(rules.contribution("a", 0) == 21, "Dhole Pack starts at +2")
	rules.play_card("a", 0)
	expect(rules.contribution("b", 1) == 23, "Dhole Pack grows to +4")
	rules.play_card("b", 1)
	expect(rules.contribution("spare", 2) == 25 and rules.state.placement_bonuses[0].remaining == -1, "Escalation lasts all round")

func shared_and_counted_block() -> void:
	var rules := fresh("reward-49-three-hammers")
	for id: String in ["a", "b", "c", "d", "e", "spare"]: add(rules, id)
	own(rules, "sloth-bear-with-two-cubs")
	own(rules, "indian-crested-porcupine")
	rules.activate_animal("sloth-bear-with-two-cubs")
	rules.activate_animal("indian-crested-porcupine")
	rules.play_card("a", 0)
	expect(rules.state.forest_impacts[-1].damage == 0 and rules.state.shared_protection == 5, "Shared protection spends only the post-Block damage")
	rules.play_card("b", 1)
	rules.play_card("c", 2)
	expect(rules.state.forest_impacts[-1].damage == 12 and rules.state.shared_protection == 0, "Shared protection carries unused amount into the next hit")
	rules.play_card("d", 3)
	rules.play_card("e", 4)
	expect(rules.state.forest_impacts[-1].damage == 24 and rules.state.hit_protection.is_empty(), "Porcupine's third charge is consumed and round clears protection")

func grace_survival() -> void:
	var rules := fresh("reward-49-three-hammers", 0)
	add(rules, "zero", "debris")
	add(rules, "spare")
	own(rules, "porcupine-pair")
	rules.activate_animal("porcupine-pair")
	rules.play_card("zero", 0)
	expect(rules.state.phase == &"playing" and rules.state.integrity == 4 and rules.state.grace.is_empty() and not rules.state.forest_impacts[-1].fatal and rules.state.forest_impacts[-1].after == 4, "Grace consumes once on a lethal hit and preserves the run at 4")

func progress_rounding() -> void:
	var rules := fresh("reward-47-cloud-wall", 0)
	rules.state.bridge_progress = 20
	for id: String in ["a", "b", "c", "d", "e", "spare"]: add(rules, id)
	own(rules, "malabar-grey-hornbill")
	own(rules, "malabar-grey-hornbill-pair")
	rules.activate_animal("malabar-grey-hornbill")
	rules.activate_animal("malabar-grey-hornbill-pair")
	for slot in range(5): rules.play_card(["a", "b", "c", "d", "e"][slot], slot)
	expect(rules.state.round_result.progress == 42 and rules.state.bridge_progress == 62, "Progress adds 20% and 35%, rounding 27 × 1.55 upward")
	expect(rules.state.round_result.goldPayout == 5 and rules.state.gold == 8 and rules.state.progress_bonuses.is_empty(), "Round payout uses floor(unboosted net Integrity / 5), and bonuses expire")

func debris_removal() -> void:
	var rules := fresh()
	var debris := CardInstance.new("debris-copy", "debris")
	rules.state.discard_pile.append(debris)
	rules.state.deck.append(debris.plain_copy())
	add(rules, "spare")
	own(rules, "sloth-bear")
	rules.activate_animal("sloth-bear")
	expect(rules.state.pending_choice.ids == ["debris-copy"], "Bear can select discarded Debris")
	rules.resolve_choice("debris-copy")
	expect(rules.state.discard_pile.is_empty() and rules.state.exiled[-1].instance_id == "debris-copy" and not rules.state.deck.any(func(card: CardInstance) -> bool: return card.instance_id == "debris-copy"), "Debris removal exiles exact copy without a replacement")

func search_and_retain() -> void:
	var rules := fresh()
	add(rules, "a")
	add(rules, "b")
	add(rules, "spare")
	own(rules, "dhole-pair")
	rules.activate_animal("dhole-pair")
	rules.resolve_choice("a")
	rules.resolve_choice("b")
	expect(rules.contribution("a", 0) == 23 and rules.hand_power("a") == 19, "Dhole Pair adds next-placement Integrity without changing power")
	rules.state.draw_pile.clear()
	rules.state.draw_pile.append(CardInstance.new("search", "deep-foundation"))
	own(rules, "black-eagle")
	rules.activate_animal("black-eagle")
	rules.resolve_choice("search")
	expect(rules.contribution("search", 0) == 30, "Black Eagle search grants its copy +4 on next placement")
	own(rules, "tahr-herd")
	rules.activate_animal("tahr-herd")
	rules.resolve_choice("a")
	rules.resolve_choice("b")
	rules._finish_round()
	rules.start_next_round()
	expect(rules.hand_power("a") == 22 and rules.hand_power("b") == 22, "Tahr Herd retains two cards with next-round power")
