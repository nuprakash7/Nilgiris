class_name CardInstance
extends RefCounted
## One physical copy. Authored rules belong to the content catalog.

var instance_id: String
var card_id: String
var power_bonus: int = 0
var permanent_power_bonus: int = 0
var zero_integrity_this_round: bool = false
var weakness: int = 0
var next_placement_bonus: int = 0
var next_placement_multiplier: float = 1.0
var permanent_integrity_multiplier: float = 1.0
var satisfy_neighbor_conditions: bool = false
# Retain explicitly stores zero too; plain copies omit that zero, as in webtest.
var has_next_round_power: bool = false
var next_round_power: int = 0
var retain_next_round: bool = false
var held_turns: int = 0
var flair_spent: bool = false


func _init(copy_id: String, definition_id: String) -> void:
	instance_id = copy_id
	card_id = definition_id


func plain_copy() -> CardInstance:
	var copy := CardInstance.new(instance_id, card_id)
	copy.flair_spent = flair_spent
	copy.power_bonus = power_bonus
	copy.permanent_power_bonus = permanent_power_bonus
	copy.zero_integrity_this_round = zero_integrity_this_round
	copy.weakness = weakness
	copy.next_placement_bonus = next_placement_bonus
	copy.next_placement_multiplier = next_placement_multiplier
	copy.permanent_integrity_multiplier = permanent_integrity_multiplier
	copy.satisfy_neighbor_conditions = satisfy_neighbor_conditions
	copy.next_round_power = next_round_power
	return copy
