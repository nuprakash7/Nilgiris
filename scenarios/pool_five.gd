class_name PoolFive
extends RefCounted
## Pools 1–5 and common through very-rare wildlife; authored data stays unchanged.
static func create_catalog(source: SetupCatalog) -> SetupCatalog:
	if not source.errors.is_empty(): return source
	var wildlife: Dictionary = source.wildlife.duplicate(true)
	wildlife.animals = wildlife.animals.filter(func(animal: Dictionary) -> bool: return animal.rarity in ["common", "uncommon", "rare", "veryRare"])
	var result := SetupCatalog.from_data({"cards": source.cards.values(), "forestAttacks": source.attacks, "config": source.config, "wildlife": wildlife})
	result.animals_enabled = true
	result.max_playable_pool = 5
	return result
