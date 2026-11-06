class_name ForestSequence
extends HBoxContainer
## Read-only projection of attack timing. Checkpoints are never physical slot labels.
signal detail_requested(title: String, text: String)
signal detail_closed
var _signature: int = 0

func _ready() -> void:
	add_theme_constant_override("separation", 4)
var checkpoints: Array[Dictionary] = []

func present(attack: Dictionary, intent: Dictionary, cells: Array[Dictionary], next_hit_bonus: int = 0) -> void:
	var occupied: int = 0
	for cell: Dictionary in cells: occupied += int(cell.construct != null)
	if intent.get("resolved", false): occupied = -1
	var signature: int = hash([attack, intent, occupied, next_hit_bonus])
	if signature == _signature: return
	_signature = signature
	for child in get_children():
		remove_child(child)
		child.queue_free()
	checkpoints.clear()
	var next_index: int = -1
	var next_count: int = 2147483647
	for index in range(attack.hits.size()):
		var hit: Dictionary = attack.hits[index]
		var timing: int = cells.size() if hit.when.type == "fullBoard" else int(hit.when.count)
		if not intent.resolvedHitKeys.has(str(index)) and timing < next_count:
			next_count = timing
			next_index = index
	for count in range(1, cells.size() + 1):
		var damage: PackedStringArray = []
		var symbols: PackedStringArray = []
		var details: PackedStringArray = ["Checkpoint %d — %d occupied Constructs." % [count, count], "These are attack timing checkpoints, not physical bridge slots."]
		var resolved: bool = false
		for index in range(attack.hits.size()):
			var hit: Dictionary = attack.hits[index]
			var timing: int = cells.size() if hit.when.type == "fullBoard" else int(hit.when.count)
			if timing != count: continue
			var forecast: int = int(hit.damage) + (next_hit_bonus if index == next_index else int(intent.get("hitDamageBonuses", {}).get(str(index), 0)))
			damage.append(str(forecast) if forecast > 0 else "·")
			if index == next_index and next_hit_bonus > 0: details.append("Hefty Pier: +%d on this hit only." % next_hit_bonus)
			var done: bool = intent.resolvedHitKeys.has(str(index))
			resolved = resolved or done
			details.append("%s%d Forest damage%s." % ["Resolved: " if done else "Upcoming: ", forecast, " when all slots are occupied" if hit.when.type == "fullBoard" else ""])
			if hit.has("conditionalReduction"):
				var reduction: Dictionary = hit.conditionalReduction
				var conditions: Dictionary = {"supportUsed": "Support was used this round", "reinforcePlayed": "a Reinforce Construct was played this round", "copyReplayed": "the same physical copy was played twice this round", "endPowerAtLeast": "both end Constructs have at least %d live power" % reduction.get("minimum", 0), "centerContributionAtLeast": "the centre Construct added at least %d Integrity" % reduction.get("minimum", 0), "endContributionsAtLeast": "both end Constructs each added at least %d Integrity" % reduction.get("minimum", 0)}
				details.append("Reduce damage by %d if %s." % [reduction.amount, conditions.get(reduction.type, "the listed condition is met")])
		for index in range(attack.get("midRoundEffects", []).size()):
			var event: Dictionary = attack.midRoundEffects[index]
			if int(event.when.count) != count: continue
			var symbol: String = {"persistentRain": "≋", "shakyGround": "⌁", "elephantCharge": "◆", "lightningStrike": "ϟ"}.get(event.effect.type, "◇")
			symbols.append(symbol)
			var done: bool = intent.get("resolvedEffectKeys", []).has(str(index))
			resolved = resolved or done
			var description: String = ""
			match event.effect.type:
				"persistentRain": description = "Persistent Rain marks slots %s. After subsequent placements, each marked Construct loses 1 power and the shared pool loses the same Integrity." % str(event.effect.slotIndexes.map(func(slot: int) -> int: return slot + 1))
				"shakyGround": description = "Shaky Ground: cards currently in hand lose %d power until round end. Later draws are unaffected." % event.effect.amount
				"elephantCharge": description = "Elephant Charge: permanently destroy a random placed Construct and replace it with Debris. Earned Integrity is kept; protection can prevent the attempt."
				"lightningStrike": description = "Lightning Strike: permanently destroy a random placed Construct and replace it with Debris. Earned Integrity is kept; protection can prevent the attempt. At most two strikes per round."
			details.append(("Resolved: " if done else "Upcoming: ") + description)
		for penalty: Dictionary in attack.get("placementPenalties", []):
			if int(penalty.count) == count:
				symbols.append("−%d" % int(penalty.amount))
				details.append("Placement %d loses %d Integrity (uses total placements, including replayed copies)." % [count, penalty.amount])
		var text: String = "·" if damage.is_empty() else "+".join(damage)
		if not symbols.is_empty(): text += "\n" + " ".join(symbols)
		var button := DiamondCheckpoint.new()
		button.empty_checkpoint = damage.is_empty() and symbols.is_empty()
		button.current = count == occupied
		button.resolved = resolved
		button.damage_text = "" if damage.is_empty() else "+".join(damage)
		button.effect_text = " ".join(symbols)
		button.text = ""
		button.custom_minimum_size = Vector2(44 if cells.size() > 5 else 52, 60)
		button.tooltip_text = "\n".join(details)
		button.add_theme_font_size_override("font_size", 21)
		button.modulate = Color(0.65, 0.75, 0.68) if resolved else Color(0.96, 0.92, 0.79)
		if count == occupied: button.add_theme_color_override("font_color", Color(1, 0.8, 0.4))
		button.focus_entered.connect(detail_requested.emit.bind("Forest checkpoint %d" % count, button.tooltip_text))
		button.focus_exited.connect(detail_closed.emit)
		add_child(button)
		checkpoints.append({"count": count, "text": text, "resolved": resolved, "current": count == occupied, "hint": button.tooltip_text})
