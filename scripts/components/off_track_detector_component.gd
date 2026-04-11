class_name OffTrackDetectorComponent
extends Node

signal went_off_track(last_safe_position: Vector3, safe_rotation: Vector3)

var last_safe_position: Vector3 = Vector3.ZERO
var last_safe_rotation: Vector3 = Vector3.ZERO
var safe_timer: float = 0.0

func _physics_process(delta: float) -> void:
	var kart = get_parent() as CharacterBody3D
	if not kart: return
	
	var phys = kart.get_node_or_null("KartPhysicsComponent")
	# Only update the safe position if the physics component actively registers us as grounded
	if phys and phys.is_grounded:
		safe_timer += delta
		if safe_timer > 1.0: # Must be safely driving on the road for 1 full second
			last_safe_position = kart.global_position
			last_safe_rotation = kart.rotation
			safe_timer = 0.0
	else:
		safe_timer = 0.0

func trigger_off_track() -> void:
	var fallback = _get_checkpoint_fallback()
	var final_pos = fallback.pos
	var final_rot = fallback.rot
	var has_valid_track_alignment = false
	
	if last_safe_position != Vector3.ZERO:
		var space_state = get_viewport().world_3d.direct_space_state
		var query = PhysicsRayQueryParameters3D.create(last_safe_position + Vector3(0, 5, 0), last_safe_position + Vector3(0, -10, 0))
		var result = space_state.intersect_ray(query)
		
		if result and result.collider:
			if result.collider.is_in_group("road") or result.collider.is_in_group("wall_ride") or result.collider.is_in_group("anti_gravity"):
				final_pos = result.position
				
				var paths = get_tree().get_nodes_in_group("track_path")
				var closest_path: Path3D = null
				var min_dist = 999999.0
				
				for path in paths:
					if path is Path3D and path.curve:
						var local_pos = path.to_local(final_pos)
						var dist = local_pos.distance_to(path.curve.get_closest_point(local_pos))
						if dist < min_dist:
							min_dist = dist
							closest_path = path
							
				if closest_path:
					var local_pos = closest_path.to_local(final_pos)
					var offset = closest_path.curve.get_closest_offset(local_pos)
					var transform = closest_path.curve.sample_baked_with_rotation(offset)
					
					var world_trans = closest_path.global_transform * transform
					final_pos = Vector3(world_trans.origin.x, final_pos.y, world_trans.origin.z)
					
					var forward_dir = -world_trans.basis.z.normalized()
					forward_dir.y = 0
					forward_dir = forward_dir.normalized()
					if forward_dir.length_squared() > 0.01:
						final_rot = Basis.looking_at(forward_dir, Vector3.UP).get_euler()
						
					has_valid_track_alignment = true

	# If the raycast failed to find road directly underneath, or no curve alignment could be found,
	# we fall back to the exact checkpoint position to ensure safety.
	if not has_valid_track_alignment:
		final_pos = fallback.pos
		final_rot = fallback.rot
		
	went_off_track.emit(final_pos, final_rot)

func _get_checkpoint_fallback() -> Dictionary:
	var kart = get_parent()
	var tracker = kart.get_node_or_null("LapTrackerComponent")
	var pos = kart.global_position
	var rot = kart.rotation
	
	if tracker and tracker.current_checkpoint >= 0:
		var cps = get_tree().get_nodes_in_group("checkpoints")
		var current_cp: CheckpointArea = null
		var next_cp: CheckpointArea = null
		
		var target_idx = tracker.current_checkpoint
		var next_idx = (target_idx + 1) % tracker.total_checkpoints
		
		for cp in cps:
			var cp_node = cp as CheckpointArea
			if cp_node:
				if cp_node.checkpoint_index == target_idx: current_cp = cp_node
				if cp_node.checkpoint_index == next_idx: next_cp = cp_node
				
		if current_cp:
			pos = current_cp.global_position
			
			# Orient the player to explicitly face the NEXT checkpoint
			if next_cp:
				var dir = (next_cp.global_position - pos).normalized()
				if dir.length_squared() > 0.01:
					# Flatten direction to prevent looking up/down
					dir.y = 0
					dir = dir.normalized()
					var look_basis = Basis.looking_at(dir, Vector3.UP)
					rot = look_basis.get_euler()
					
			return {"pos": pos, "rot": rot}
			
	# Absolute fallback: if no checkpoints have been passed yet, send them to the Start Position
	var starts = get_tree().get_nodes_in_group("start_position")
	if starts.size() > 0:
		return {"pos": starts[0].global_position, "rot": starts[0].global_rotation}
		
	return {"pos": pos, "rot": rot}

