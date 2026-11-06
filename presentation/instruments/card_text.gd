class_name CardText
extends RefCounted
## Presentation copy derived from authored mechanics; no effect execution.
static func compact(card: Dictionary) -> String:
	var text: String = card.get("effectText", "")
	var opening := RegEx.new()
	opening.compile("^(Adds [0-9]+ Integrity[.,]|Base [0-9]+ power\\.)\\s*")
	text = opening.sub(text, "")
	if text == "No abilities.": text = ""
	if text.begins_with("plus "): text = "+" + text.trim_prefix("plus ")
	if text.begins_with("Adds ") and card.get("positionEffect", {}).get("condition", "") == "evenSlot":
		text = "Even-numbered slot: +%d Integrity" % card.positionEffect.integrityBonus
	if card.get("integrityFormula", {}).get("type", "") == "adjacentChain": text = "+2 per consecutive adjacent link."
	if card.get("effects", []).any(func(effect: Dictionary) -> bool: return effect.type == "nextAdjacentPermanent"): text = "Next adjacent: +1 Integrity permanently."
	if card.has("flair"):
		var flair: Dictionary = card.flair
		var labels: Dictionary = {"integrity": "+%d Integrity", "draw": "Draw %d", "gold": "+%d Gold", "bounce": "Bounce %d", "supportAll": "Support all +%d", "permanentIntegrity": "This copy permanently +%d", "drawPerNeighbor": "Draw %d per occupied neighbour", "discardDraw": "Discard 1 → Draw %d", "recoverLast": "Recover last %d discards"}
		var label: String = "Borrow a random hand card's Integrity; its placement adds 0 this round" if flair.type == "randomHandIntegrity" else String(labels.get(flair.type, "%d")) % int(flair.get("amount", flair.get("count", 0)))
		text += ("\n" if not text.is_empty() else "") + "Flair · " + label
	return text.strip_edges()
