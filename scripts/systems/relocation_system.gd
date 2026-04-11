class_name RelocationSystem
extends Node

@export var relocation_delay: float = 1.5

func relocate_entity(entity: Node3D, safe_position: Vector3, safe_rotation: Vector3) -> void:
	var physics = entity.get_node_or_null("KartPhysicsComponent")
	if physics:
		physics.set_physics_process(false)
		physics.current_speed = 0.0
		physics.y_velocity = 0.0
		physics.surface_normal = Vector3.UP
		physics.boost_time = 0.0
		physics.is_drifting = false
		physics.drift_dir = 0
		
	if entity is CharacterBody3D:
		entity.velocity = Vector3.ZERO
		
	# Drop cleanly from above, flattening out X and Z rotation to prevent side-clipping into ground
	entity.global_position = safe_position + Vector3(0, 6, 0)
	entity.global_rotation = Vector3(0, safe_rotation.y, 0)
	
	# Simulate Lakitu drop delay
	await get_tree().create_timer(relocation_delay).timeout
	
	if physics:
		physics.set_physics_process(true)

