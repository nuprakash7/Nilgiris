class_name CardUpgrades
extends RefCounted
## Exact-copy permanent upgrades; never change shared card definitions.
static func add_power(state: RunState, target: CardInstance, amount: int) -> void:
	target.permanent_power_bonus += amount
	if target is PlacedConstruct: target.power += amount
	for owned: CardInstance in state.deck:
		if owned.instance_id == target.instance_id and owned != target:
			owned.permanent_power_bonus = target.permanent_power_bonus
