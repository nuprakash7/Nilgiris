class_name PoolThree
extends RefCounted
## Pools 1–3 and common/uncommon wildlife; authored data stays unchanged.
static func create_catalog(source: SetupCatalog) -> SetupCatalog:
	if not source.errors.is_empty(): return source
	var wildlife: Dictionary = source.wildlife.duplicate(true)
	wildlife.animals = wildlife.animals.filter(func(animal: Dictionary) -> bool: return animal.rarity in ["common", "uncommon"])
	var result := SetupCatalog.from_data({"cards": source.cards.values(), "forestAttacks": source.attacks, "config": source.config, "wildlife": wildlife})
	result.animals_enabled = true
	result.max_playable_pool = 3
	return result
