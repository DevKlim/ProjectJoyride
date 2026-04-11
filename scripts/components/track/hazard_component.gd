class_name HazardComponent
extends Area3D

@export var speed_penalty_factor: float = 0.3
@export var duration: float = 1.5

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	var physics = body.get_node_or_null("KartPhysicsComponent")
	if physics and physics.has_method("apply_hazard"):
		physics.apply_hazard(speed_penalty_factor, duration)
		