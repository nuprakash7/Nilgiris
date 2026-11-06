class_name FirstRound
extends RefCounted
## Bounded playable scenario. Content values and authored rules are unchanged.

const REWARDS: Array[String] = [
	"timber-plank", "iron-spike", "stone-footing", "steel-girder", "left-brace",
]
const ATTACK: String = "reward-01-first-drizzle"
const ATTACKS: Array[String] = [ATTACK]
const SEED: int = 42


static func create_catalog(source: SetupCatalog, rewards: Array[String] = REWARDS, attacks: Array[String] = ATTACKS) -> SetupCatalog:
	if not source.errors.is_empty():
		return source
	var config: Dictionary = source.config.duplicate(true)
	var first_pool: Dictionary = config.rewardPools[1]
	for id: String in first_pool.cardIds:
		if not rewards.has(id):
			config.rewardCardIds.erase(id)
	first_pool.cardIds = rewards.duplicate()
	first_pool.attackIds = attacks.duplicate()
	return SetupCatalog.from_data({
		"cards": source.cards.values(), "forestAttacks": source.attacks,
		"config": config, "wildlife": source.wildlife,
	})
