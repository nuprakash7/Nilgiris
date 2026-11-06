class_name PoolOne
extends RefCounted
## Current Pool 1 definitions and an explicit common-only animal roster.

static func create_catalog(source: SetupCatalog) -> SetupCatalog:
	if not source.errors.is_empty():
		return source
	var wildlife: Dictionary = source.wildlife.duplicate(true)
	wildlife.animals = wildlife.animals.filter(func(animal: Dictionary) -> bool: return animal.rarity == "common")
	var result := SetupCatalog.from_data({"cards": source.cards.values(), "forestAttacks": source.attacks, "config": source.config, "wildlife": wildlife})
	result.animals_enabled = true
	return result
