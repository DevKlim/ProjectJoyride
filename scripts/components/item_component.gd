class_name ItemComponent
extends Node

signal item_obtained(item: ItemResource)
signal item_ready(item: ItemResource)
signal item_used()

var current_item: ItemResource
var roulette_timer: float = 0.0

@onready var input: KartInputComponent = $"../KartInputComponent"
@onready var physics: KartPhysicsComponent = $"../KartPhysicsComponent"

func has_item() -> bool:
	return current_item != null or roulette_timer > 0.0

func give_item(item: ItemResource) -> void:
	if not has_item():
		current_item = item
		roulette_timer = 2.0 # 2 seconds of visual roulette
		item_obtained.emit(item)

func _process(delta: float) -> void:
	if roulette_timer > 0:
		roulette_timer -= delta
		if roulette_timer <= 0:
			item_ready.emit(current_item)
			
	if input and input.item_just_pressed and current_item != null and roulette_timer <= 0:
		use_item()

func use_item() -> void:
	var used = current_item
	current_item = null
	
	match used.type:
		"boost":
			if physics:
				var dur = used.attributes.get("boost_duration", 2.0)
				var strength = used.attributes.get("boost_strength", 1.5)
				physics.apply_item_boost(dur, strength)
		"jump":
			if physics and physics.kart_body.is_on_floor():
				physics.y_velocity = physics.jump_force * used.attributes.get("jump_force_multiplier", 1.5)
		"coin":
			var shop = get_tree().get_nodes_in_group("ShopSystem")
			if shop.size() > 0:
				shop[0].add_coins(used.attributes.get("amount", 1))
	
	item_used.emit()

