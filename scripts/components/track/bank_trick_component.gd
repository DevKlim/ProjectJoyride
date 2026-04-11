class_name BankTrickComponent
extends Area3D

@export var launch_force: float = 15.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	var phys = body.get_node_or_null("KartPhysicsComponent")
	if phys and phys.has_method("apply_bank_trick"):
		phys.apply_bank_trick(launch_force)

