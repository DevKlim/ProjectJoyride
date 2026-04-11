class_name RampComponent
extends Area3D

@export var boost_multiplier: float = 2.0

func _ready() -> void:
	add_to_group("ramps")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	var phys = body.get_node_or_null("KartPhysicsComponent")
	if phys and "on_ramp" in phys:
		phys.on_ramp = true
		phys.time_since_ramp = 0.0
		
func _on_body_exited(body: Node3D) -> void:
	var phys = body.get_node_or_null("KartPhysicsComponent")
	if phys and "on_ramp" in phys:
		phys.on_ramp = false
		phys.time_since_ramp = 0.0

