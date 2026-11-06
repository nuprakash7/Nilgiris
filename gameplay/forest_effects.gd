class_name ForestEffects
extends RefCounted
## Board hazards only; RoundRules owns their ordering after effects and hits.

static func tick_rain(state: RunState) -> void:
	for index: int in state.rain_slots:
		var placed: PlacedConstruct = state.cells[index].construct
		if placed == null: continue
		var loss: int = mini(1, placed.power)
		placed.power -= loss
		state.integrity = maxi(0, state.integrity - loss)
		if loss: state.note("Persistent Rain: slot %d -1 power and Integrity." % (index + 1))

static func resolve(state: RunState, catalog: SetupCatalog, attack: Dictionary) -> void:
	var occupied: int = 0
	for cell: Dictionary in state.cells:
		occupied += int(cell.construct != null)
	var events: Array = attack.get("midRoundEffects", [])
	for index in range(events.size()):
		var event: Dictionary = events[index]
		var key: String = str(index)
		if int(event.when.count) != occupied or state.intent.get("resolvedEffectKeys", []).has(key): continue
		if not state.intent.has("resolvedEffectKeys"): state.intent.resolvedEffectKeys = []
		state.intent.resolvedEffectKeys.append(key)
		match event.effect.type:
			"persistentRain":
				for slot: int in event.effect.slotIndexes:
					if not state.rain_slots.has(slot): state.rain_slots.append(slot)
				state.note("Persistent Rain marks slots %s." % str(event.effect.slotIndexes.map(func(slot: int) -> int: return slot + 1)))
			"shakyGround":
				for held: CardInstance in state.hand: held.weakness += int(event.effect.amount)
				state.note("Shaky Ground: current hand loses %d power until round end." % event.effect.amount)
			"elephantCharge": _charge(state, catalog)
			"lightningStrike":
				if int(state.intent.get("lightningStrikes", 0)) >= 2: continue
				state.intent.lightningStrikes = int(state.intent.get("lightningStrikes", 0)) + 1
				_charge(state, catalog, "Lightning Strike")

static func _charge(state: RunState, catalog: SetupCatalog, label: String = "Elephant Charge") -> void:
	var targets: Array[Dictionary] = []
	for cell: Dictionary in state.cells:
		if cell.construct != null: targets.append(cell)
	if targets.is_empty(): return
	var target: Dictionary = targets[int(floor(state.random.roll() * targets.size()))]
	var placed: PlacedConstruct = target.construct
	if state.prevent_destruction:
		state.note("Rani’s protection prevented destruction in slot %d." % (target.slotIndex + 1))
		return
	if placed.destruction_protection > 0:
		placed.destruction_protection -= 1
		state.note("Protect: prevented destruction in slot %d; no retargeting." % (target.slotIndex + 1))
		return
	state.exiled.append(placed.plain_copy())
	for index in range(state.deck.size() - 1, -1, -1):
		if state.deck[index].instance_id == placed.instance_id: state.deck.remove_at(index)
	var debris := CardInstance.new("card-%d" % state.next_instance_id, "debris")
	state.next_instance_id += 1
	state.deck.append(debris.plain_copy())
	target.construct = PlacedConstruct.new(debris, 0, 0)
	state.note("%s: destroyed %s in slot %d; replaced with Debris. Earned Integrity kept." % [label, catalog.cards[placed.card_id].name, target.slotIndex + 1])
