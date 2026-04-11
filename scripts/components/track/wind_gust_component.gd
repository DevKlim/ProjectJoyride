class_name WindGustComponent
extends Area3D

@export var upward_force: float = 40.0
@export var constant_lift: bool = true

func _ready() -> void:
	if not constant_lift:
		body_entered.connect(_on_body_entered)
		
func _physics_process(delta: float) -> void:
	if constant_lift:
		for body in get_overlapping_bodies():
			var phys = body.get_node_or_null("KartPhysicsComponent")
			if phys and phys.has_method("apply_upward_launch"):
				phys.apply_upward_launch(upward_force)

func _on_body_entered(body: Node3D) -> void:
	if not constant_lift:
		var phys = body.get_node_or_null("KartPhysicsComponent")
		if phys and phys.has_method("apply_upward_launch"):
			phys.apply_upward_launch(upward_force)

