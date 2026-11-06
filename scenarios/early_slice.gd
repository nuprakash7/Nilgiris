class_name EarlySlice
extends RefCounted
## Early Construct rounds, stopping before animals or the next room.

const REWARDS: Array[String] = [
	"timber-plank", "iron-spike", "stone-footing", "steel-girder", "left-brace", "staging-deck",
]
const ATTACKS: Array[String] = ["reward-01-first-drizzle", "reward-02-passing-shower"]
const SEED: int = 42


static func create_catalog(source: SetupCatalog) -> SetupCatalog:
	return FirstRound.create_catalog(source, REWARDS, ATTACKS)
