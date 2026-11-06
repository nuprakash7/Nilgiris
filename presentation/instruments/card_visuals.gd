class_name CardVisuals
extends RefCounted
## Shared flat artwork for 2D offers and 3D hand cards; no per-card viewport.
const FACE = preload("res://art/cards/face.svg")
const SPIKE = preload("res://art/cards/illustrations/iron_spike.svg")
const PIER = preload("res://art/cards/illustrations/pier.svg")
const BRACE = preload("res://art/cards/illustrations/brace.svg")
static func illustration(card_id: String) -> Texture2D:
	if "spike" in card_id: return SPIKE
	for word in ["pier", "footing", "bearing", "mount", "keystone", "foundation", "abutment", "column"]:
		if word in card_id: return PIER
	return BRACE
