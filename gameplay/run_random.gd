class_name RunRandom
extends RefCounted
## The prototype's unsigned 32-bit LCG. One stream per run.

const MASK: int = 0xffffffff
const RANGE: float = 4294967296.0

var seed: int


func _init(initial_seed: int = 42) -> void:
	seed = initial_seed & MASK


func roll() -> float:
	# The largest product fits in GDScript's signed 64-bit integer.
	seed = (1664525 * seed + 1013904223) & MASK
	return float(seed) / RANGE


func shuffled(items: Array) -> Array:
	var result: Array = items.duplicate()
	for index in range(result.size() - 1, 0, -1):
		var other: int = int(floor(roll() * (index + 1)))
		var item: Variant = result[index]
		result[index] = result[other]
		result[other] = item
	return result
