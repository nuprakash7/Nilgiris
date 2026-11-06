extends SceneTree

const Snapshot = preload("res://tests/state_snapshot.gd")

var failures: int = 0
var frames_checked: int = 0


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 1:
		printerr("Use node tests/check-round.cjs to generate reference inputs.")
		quit(1)
		return
	var reference: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var catalogs: Array[SetupCatalog] = []
	for source: Dictionary in reference.sources:
		var base := SetupCatalog.from_data(source)
		catalogs.append(PoolOne.create_catalog(base) if reference.get("scenario") == "pool1" else (EarlySlice.create_catalog(base) if reference.get("scenario") == "slice" else FirstRound.create_catalog(base)))
	for case: Dictionary in reference.cases:
		var catalog: SetupCatalog = catalogs[int(case.sourceIndex)]
		var state := RunSetup.create(catalog, int(case.seed))
		var patch: Dictionary = case.get("patch", {})
		if patch.has("roundLimit"):
			state.round_limit = int(patch.roundLimit)
		if patch.has("handSize"):
			var retained: int = int(patch.handSize)
			state.draw_pile = state.hand.slice(retained) + state.draw_pile
			state.hand = state.hand.slice(0, retained)
		if patch.get("forceAnimal", false):
			state.phase = &"roundComplete"
			state.animal_round_pending = true
			state.habitat_batch.assign(["woods", "woods", "canopies"])
			state.hand.clear()
			state.draw_pile.clear()
			state.discard_pile.clear()
			state.deck.clear()
		if patch.has("animals"):
			state.animals.assign(patch.animals.duplicate(true))
		if patch.has("capacity"):
			state.animal_capacity = int(patch.capacity)
		if patch.has("cardId"):
			for card: CardInstance in state.hand:
				if card.instance_id == "card-1":
					card.card_id = patch.cardId
			# The test fixtures put the specified card at the front of the hand.
			if not state.hand.any(func(card: CardInstance) -> bool: return card.instance_id == "card-1"):
				for zone: Array[CardInstance] in [state.draw_pile, state.discard_pile]:
					for card: CardInstance in zone.duplicate():
						if card.instance_id == "card-1":
							zone.erase(card)
							card.card_id = patch.cardId
							state.hand.append(card)
		var rules := RoundRules.new(catalog, state)
		_check(rules.errors.is_empty(), "%s: %s" % [case.name, rules.errors])
		if not rules.errors.is_empty():
			continue
		for frame: Dictionary in case.frames:
			if frame.has("action"):
				var request: Dictionary = frame.action
				var problem: String
				if request.type == "choose":
					problem = rules.choose_reward(request.offerId)
				elif request.type == "play":
					var previews: Array = []
					for index in range(state.cells.size()):
						previews.append(rules.contribution(request.instanceId, index))
					_check(previews == Snapshot.normalize(frame.previews), "%s: contribution previews differ" % case.name)
					problem = rules.play_card(request.instanceId, int(request.slotIndex))
				elif request.type == "buy":
					problem = rules.purchase_draw()
				elif request.type == "flair":
					problem = rules.activate_flair(request.instanceId)
				elif request.type == "animalReward":
					problem = rules.choose_animal_reward(request.offerId)
				elif request.type == "animal":
					problem = rules.activate_animal(request.instanceId)
				elif request.type == "choice":
					problem = rules.resolve_choice(request.get("instanceId", ""))
				elif request.type == "acquire":
					problem = rules.resolve_animal_acquisition(request.get("instanceId", ""))
				elif request.type == "next":
					problem = rules.start_next_round()
				_check(not problem.is_empty() == bool(frame.rejected), "%s: action legality differs" % case.name)
			var differences: Array[String] = Snapshot.differences(Snapshot.capture(state), frame.expected)
			_check(differences.is_empty(), "%s: frame %d differs in %s" % [case.name, frames_checked, differences])
			frames_checked += 1
	for case: Dictionary in reference.unsupported:
		var catalog := FirstRound.create_catalog(SetupCatalog.from_data(case.source))
		var rules := RoundRules.new(catalog, RunSetup.create(catalog))
		_check(not rules.errors.is_empty(), "Reject unsupported %s" % case.name)
		var before: Dictionary = Snapshot.capture(rules.state)
		_check(not rules.choose_reward("offer-1").is_empty(), "Block reward on unsupported content")
		_check(not rules.play_card("card-1", 0).is_empty(), "Block play on unsupported content")
		_check(Snapshot.capture(rules.state) == before, "Unsupported actions do not mutate state")
	for invalid: Dictionary in reference.get("invalidWildlife", []):
		var catalog: SetupCatalog = PoolOne.create_catalog(SetupCatalog.from_data(invalid.source))
		var rules := RoundRules.new(catalog, RunSetup.create(catalog))
		_check(not rules.errors.is_empty(), "Reject invalid wildlife: " + invalid.name)
		var before: Dictionary = Snapshot.capture(rules.state)
		_check(not rules.choose_reward("offer-1").is_empty(), "Invalid wildlife blocks reward choice")
		_check(not rules.activate_animal("animal-test").is_empty(), "Invalid wildlife blocks activation")
		_check(Snapshot.capture(rules.state) == before, "Invalid wildlife never mutates state")
	if failures == 0:
		print("Round checks passed: %d traces, %d state/action frames, %d unsupported-content checks." % [reference.cases.size(), frames_checked, reference.unsupported.size()])
	quit(0 if failures == 0 else 1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		if failures <= 12:
			printerr(message)
