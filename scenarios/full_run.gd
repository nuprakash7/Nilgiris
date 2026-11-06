class_name FullRun
extends RefCounted
## All authored pools and wildlife, with original rarity weights and definitions.
static func create_catalog(source: SetupCatalog) -> SetupCatalog:
	if not source.errors.is_empty(): return source
	var result := SetupCatalog.from_data({"cards": source.cards.values(), "forestAttacks": source.attacks, "config": source.config, "wildlife": source.wildlife})
	result.animals_enabled = true
	result.max_playable_pool = 5
	return result
