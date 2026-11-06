class_name PlacedConstruct
extends CardInstance
## Board-local values; cleanup restores a plain card instance.

var neighbor_integrity_bonus: int = 0
var neighbor_permanent_bonus: int = 0
var destruction_protection: int = 0
var power: int
var integrity_added: int


func _init(card: CardInstance, live_power: int, contribution: int) -> void:
	super(card.instance_id, card.card_id)
	flair_spent = card.flair_spent
	power_bonus = card.power_bonus
	permanent_power_bonus = card.permanent_power_bonus
	zero_integrity_this_round = card.zero_integrity_this_round
	weakness = card.weakness
	permanent_integrity_multiplier = card.permanent_integrity_multiplier
	next_round_power = card.next_round_power
	power = live_power
	integrity_added = contribution
