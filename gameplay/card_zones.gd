class_name CardZones
extends RefCounted
## Shared draw/reshuffle behavior for setup, cards, Flair, and purchases.


static func draw(state: RunState, count: int, limit: int = 12) -> int:
	var drawn: int = 0
	while drawn < count and state.hand.size() < limit:
		if state.draw_pile.is_empty():
			state.draw_pile.assign(state.random.shuffled(state.discard_pile))
			state.discard_pile.clear()
		if state.draw_pile.is_empty():
			break
		state.hand.append(state.draw_pile.pop_front())
		drawn += 1
	return drawn


static func find_live(state: RunState, instance_id: String) -> CardInstance:
	for zone: Array[CardInstance] in [state.hand, state.draw_pile, state.discard_pile]:
		for card: CardInstance in zone:
			if card.instance_id == instance_id:
				return card
	for cell: Dictionary in state.cells:
		if cell.construct != null and cell.construct.instance_id == instance_id:
			return cell.construct
	return null


static func acquire(state: RunState, card_id: String, hand_limit: int = 12) -> CardInstance:
	var card := CardInstance.new("card-%d" % state.next_instance_id, card_id)
	state.next_instance_id += 1
	state.deck.append(card.plain_copy())
	if state.hand.size() < hand_limit: state.hand.append(card)
	else: state.discard_pile.append(card)
	return card
