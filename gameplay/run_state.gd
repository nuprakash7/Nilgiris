class_name RunState
extends RefCounted
## Mutable run data. Rules own updates; presentation reads it without mutation.

var phase: StringName = &"playing"
var room_index: int = 0
var round_number: int = 1
var room_round_number: int = 1
var round_limit: int = 24
var integrity: int = 0
var bridge_progress: int = 0
var gold: int = 3
var purchased_draws_this_round: int = 0
var weather: Dictionary = {"wet": 0, "windy": 0}
var deck: Array[CardInstance] = []
var hand: Array[CardInstance] = []
var draw_pile: Array[CardInstance] = []
var discard_pile: Array[CardInstance] = []
var next_instance_id: int = 1
var next_offer_id: int = 1
var reward_pool_id: int = 0
var construct_offer_pool_id: int = 0
var reward_pool: Array[String] = []
var reward_offers: Array[Dictionary] = []
var reward_round_type: StringName = &"construct"
var intent: Dictionary = {}
var cells: Array[Dictionary] = []
var random: RunRandom
var constructs_placed_this_round: int = 0
var placement_gold_paid: Array[String] = []
var placement_gold_earned: Dictionary = {}
var placement_gold_bonus_paid: Array[String] = []
var bounced_instance_ids: Array[String] = []
var play_counts: Dictionary[String, int] = {}
var instance_play_counts: Dictionary[String, int] = {}
var round_instance_plays: Dictionary[String, int] = {}
var pending_habitat_id: String = ""
var habitat_batch: Array[String] = []
var habitat_history: Array[Dictionary] = []
var round_result: Dictionary = {}
var loss_reason: String = ""
var log: Array[String] = []
var forest_impacts: Array[Dictionary] = []
var forest_impact_sequence: int = 0
var animal_round_pending: bool = false
var room_clear_events: Array[Dictionary] = []


func note(message: String) -> void:
	if log.size() == 80:
		log.pop_front()
	log.append(message)

var animals: Array[Dictionary] = []
var animal_capacity: int = 4
var next_animal_instance_id: int = 1
var pending_animal: Dictionary = {}
var animal_offers: Array[Dictionary] = []
var selected_animal_id: String = ""
var resume_construct_offers: bool = false
var animal_encounters: Array[String] = []
var sightings: Array[Dictionary] = []
var next_hit_reduction: int = 0
var next_forest_damage_bonus: int = 0
var last_placement_slot: int = -1
var adjacent_chain_links: int = 0
var placement_bonuses: Array[Dictionary] = []
var pending_choice: Dictionary = {}
var animal_effects: Array[Dictionary] = []

var support_used_this_round: bool = false
var reinforce_played_this_round: bool = false
var supported_instance_ids: Array[String] = []
var construct_resolution: Dictionary = {}

var exiled: Array[CardInstance] = []
var rain_slots: Array[int] = []
var half_next_hit: Array[int] = []
var hit_protection: Array[Dictionary] = []

var shared_protection: int = 0
var grace: Array[Dictionary] = []
var progress_bonuses: Array[Dictionary] = []

var prevent_destruction: bool = false
