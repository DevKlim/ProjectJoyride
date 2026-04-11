class_name BoostPadComponent
extends Area3D

@export var boost_duration: float = 1.5
@export var boost_power: float = 25.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	var physics = body.get_node_or_null("KartPhysicsComponent")
	if physics and physics.has_method("apply_item_boost"):
		physics.apply_item_boost(boost_duration, boost_power)
		