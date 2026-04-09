class_name RelocationSystem
extends Node

@export var relocation_delay: float = 1.5

func relocate_entity(entity: Node3D, safe_position: Vector3, safe_rotation: Vector3) -> void:
	var physics = entity.get_node_or_null("KartPhysicsComponent")
	if physics:
		physics.set_physics_process(false)
		physics.current_speed = 0.0
		
	if entity is CharacterBody3D:
		entity.velocity = Vector3.ZERO
		
	entity.global_position = safe_position + Vector3(0, 4, 0)
	entity.rotation = safe_rotation
	
	# Simulate Lakitu drop delay
	await get_tree().create_timer(relocation_delay).timeout
	
	if physics:
		physics.set_physics_process(true)
		