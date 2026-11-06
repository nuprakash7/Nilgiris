class_name PoolTwo
extends RefCounted
## Pools 1–2 with the existing common animal roster.

static func create_catalog(source: SetupCatalog) -> SetupCatalog:
	var result := PoolOne.create_catalog(source)
	result.max_playable_pool = 2
	return result
