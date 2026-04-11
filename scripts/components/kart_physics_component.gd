class_name KartPhysicsComponent
extends Node

@export var kart_body: CharacterBody3D
@export var gravity: float = 28.0
@export var jump_force: float = 12.0

var current_speed: float = 0.0
var forward_velocity: Vector3 = Vector3.ZERO
var y_velocity: float = 0.0

var is_drifting: bool = false
var drift_dir: int = 0
var drift_time: float = 0.0

var boost_time: float = 0.0
var boost_power: float = 0.0

var hazard_time: float = 0.0
var hazard_penalty: float = 1.0

var has_tricked: bool = false
var perfect_trick: bool = false
var trick_spin_timer: float = 0.0

var air_time: float = 0.0
var on_ramp: bool = false
var time_since_ramp: float = 999.0

var is_stunned: bool = false
var stun_time: float = 0.0
var spin_angle: float = 0.0

var is_grounded: bool = false
var was_grounded: bool = false

var surface_normal: Vector3 = Vector3.UP
var ground_ray: RayCast3D

var base_visual_y: float = -0.5
var initial_visual_basis: Basis = Basis.IDENTITY
var base_wheel_y: float = 0.0
var visual_hop_offset: float = 0.0
var hop_tween: Tween

var wall_bump_cooldown: float = 0.0

var is_in_cannon: bool = false
var cannon_path: Path3D = null
var cannon_speed: float = 0.0
var cannon_offset: float = 0.0
var cannon_entry_speed: float = 0.0

@onready var input: KartInputComponent = $"../KartInputComponent"
@onready var stats: StatsComponent = $"../StatsComponent"
@onready var anim_player: AnimationPlayer = $"../AnimationPlayer"
@onready var visual_model: Node3D = $"../VisualModel"
@onready var wheels_component: Node3D = $"../WheelsComponent"
@onready var vfx = $"../KartVFXComponent"

func _ready() -> void:
	if kart_body:
		kart_body.floor_max_angle = deg_to_rad(85.0)
		kart_body.floor_snap_length = 0.5
		
		ground_ray = RayCast3D.new()
		ground_ray.target_position = Vector3(0, -1.5, 0)
		ground_ray.collision_mask = 1 
		kart_body.call_deferred("add_child", ground_ray)
		
	if visual_model: 
		base_visual_y = visual_model.position.y
		initial_visual_basis = visual_model.transform.basis
		
	if wheels_component: base_wheel_y = wheels_component.position.y

func _do_visual_hop() -> void:
	if hop_tween and hop_tween.is_valid():
		hop_tween.kill()
	hop_tween = create_tween()
	hop_tween.tween_property(self, "visual_hop_offset", 0.8, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hop_tween.tween_property(self, "visual_hop_offset", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _physics_process(delta: float) -> void:
	if not kart_body or not input or not stats: return
	if not ground_ray or not ground_ray.is_inside_tree(): return
	
	if wall_bump_cooldown > 0:
		wall_bump_cooldown -= delta
		
	if not on_ramp:
		time_since_ramp += delta
	else:
		time_since_ramp = 0.0
		
	if is_stunned:
		stun_time -= delta
		spin_angle += 25.0 * delta
		if stun_time <= 0:
			is_stunned = false
			spin_angle = 0.0
	elif trick_spin_timer > 0:
		trick_spin_timer -= delta
		spin_angle += 12.56 * delta # approximately 2 full rotations
		if trick_spin_timer <= 0:
			spin_angle = 0.0
	
	if is_in_cannon and cannon_path:
		cannon_offset += cannon_speed * delta
		var curve = cannon_path.curve
		if curve and cannon_offset <= curve.get_baked_length():
			var pos = curve.sample_baked(cannon_offset)
			
			var forward_dir = Vector3.FORWARD
			if cannon_offset + 0.1 <= curve.get_baked_length():
				forward_dir = (curve.sample_baked(cannon_offset + 0.1) - pos).normalized()
			else:
				forward_dir = (pos - curve.sample_baked(cannon_offset - 0.1)).normalized()
				
			var global_pos = cannon_path.to_global(pos)
			var global_forward = cannon_path.global_transform.basis * forward_dir
			
			kart_body.global_position = global_pos
			
			if global_forward.length_squared() > 0.01:
				var up_dir = Vector3.UP
				if abs(global_forward.dot(Vector3.UP)) > 0.99: up_dir = Vector3.RIGHT
				var current_scale = kart_body.scale
				kart_body.global_transform.basis = Basis.looking_at(global_forward, up_dir).scaled(current_scale)
					
			if visual_model:
				var visual_scale = visual_model.scale
				visual_model.global_transform.basis = kart_body.global_transform.basis * initial_visual_basis
				visual_model.scale = visual_scale
				visual_model.position.y = base_visual_y
				
			if wheels_component:
				wheels_component.global_transform.basis = kart_body.global_transform.basis.orthonormalized()
				wheels_component.position.y = base_wheel_y + visual_hop_offset
				
			return
		else:
			is_in_cannon = false
			
			var exit_pos = curve.sample_baked(curve.get_baked_length())
			var prev_pos = curve.sample_baked(max(0.0, curve.get_baked_length() - 0.5))
			var exit_dir = (exit_pos - prev_pos).normalized()
			var global_exit_dir = cannon_path.global_transform.basis * exit_dir
			
			y_velocity = global_exit_dir.y * cannon_speed
			
			var target_up = Vector3.UP
			if abs(global_exit_dir.dot(Vector3.UP)) > 0.99: target_up = Vector3.RIGHT
			
			var current_scale = kart_body.scale
			kart_body.global_transform.basis = Basis.looking_at(global_exit_dir, target_up).orthonormalized().scaled(current_scale)
				
			var horizontal_ratio = Vector3(global_exit_dir.x, 0, global_exit_dir.z).length()
			current_speed = max(cannon_entry_speed, cannon_speed * horizontal_ratio)
			
			cannon_path = null

	if hazard_time > 0:
		hazard_time -= delta
		if hazard_time <= 0: hazard_penalty = 1.0
		
	is_grounded = false
	var on_wall_ride = false
	var on_anti_gravity = false
	var track_normal = Vector3.UP
	
	var current_down = -surface_normal
	ground_ray.target_position = current_down * 2.0
	ground_ray.force_raycast_update()
	
	if ground_ray.is_colliding():
		var col = ground_ray.get_collider()
		if col and (col.is_in_group("road") or col.is_in_group("wall_ride") or col.is_in_group("anti_gravity")):
			var n = ground_ray.get_collision_normal()
			var angle = rad_to_deg(acos(n.dot(Vector3.UP)))
			
			if col.is_in_group("anti_gravity") or col.is_in_group("wall_ride") or angle <= 70.0:
				is_grounded = true
				track_normal = n
				if col.is_in_group("wall_ride"): on_wall_ride = true
				if col.is_in_group("anti_gravity"): on_anti_gravity = true

	if not is_grounded and kart_body.get_slide_collision_count() > 0:
		for i in kart_body.get_slide_collision_count():
			var col = kart_body.get_slide_collision(i)
			var collider = col.get_collider()
			if collider and (collider.is_in_group("road") or collider.is_in_group("wall_ride") or collider.is_in_group("anti_gravity")):
				var n = col.get_normal()
				var angle = rad_to_deg(acos(n.dot(Vector3.UP)))
				
				if collider.is_in_group("anti_gravity") or collider.is_in_group("wall_ride") or angle <= 70.0:
					is_grounded = true
					track_normal = n
					if collider.is_in_group("wall_ride"): on_wall_ride = true
					if collider.is_in_group("anti_gravity"): on_anti_gravity = true
					break

	var target_up = track_normal if is_grounded else Vector3.UP
	
	var align_speed = 15.0 if is_grounded else 0.8
	surface_normal = surface_normal.lerp(target_up, delta * align_speed).normalized()
	kart_body.up_direction = surface_normal

	var current_scale = kart_body.scale
	var current_basis = kart_body.global_transform.basis.orthonormalized()
	var target_basis = _align_with_y(current_basis, surface_normal)
	kart_body.global_transform.basis = current_basis.slerp(target_basis, delta * 12.0).scaled(current_scale)

	if is_grounded:
		if has_tricked:
			has_tricked = false
			var pwr = 18.0 if perfect_trick else 10.0
			var dur = 2.0 if perfect_trick else 1.5
			apply_item_boost(dur, pwr) 
			perfect_trick = false
			
		air_time = 0.0
	else:
		air_time += delta

	var slip_velocity = Vector3.ZERO
	var slope_angle = rad_to_deg(acos(track_normal.dot(Vector3.UP)))

	if is_grounded:
		y_velocity = -5.0
		
		if slope_angle > 5.0 and not on_anti_gravity:
			var downhill_dir = (Vector3.DOWN - Vector3.DOWN.project(track_normal)).normalized()
			var grip = clamp(stats.traction, 0.1, 5.0)
			var slide_factor = max(0.0, (1.0 - (grip / 5.0))) * (stats.weight / 100.0)
			
			if on_wall_ride:
				if abs(current_speed) > 10.0:
					y_velocity = -25.0
					slip_velocity = downhill_dir * (slide_factor * 15.0)
				else:
					slip_velocity = downhill_dir * 30.0
			else:
				slip_velocity = downhill_dir * (slide_factor * 8.0)
	else:
		y_velocity -= gravity * delta

	var target_speed = input.accelerate * stats.top_speed * hazard_penalty
	var current_accel = stats.acceleration
	
	if boost_time > 0:
		target_speed = (stats.top_speed + boost_power) * hazard_penalty
		current_accel *= 3.0 
		boost_time -= delta
		if boost_time <= 0: boost_power = 0.0
		
	current_speed = move_toward(current_speed, target_speed, current_accel * delta)
	
	var turn = input.steer
	var turn_speed = stats.handling
	var speed_ratio = clamp(abs(current_speed) / 10.0, 0.0, 1.0)
	
	if input.drift_just_pressed:
		if is_grounded:
			if on_ramp or time_since_ramp < 0.2:
				has_tricked = true
				perfect_trick = (time_since_ramp < 0.15)
				trick_spin_timer = 0.5
				var animator = $"../CharacterAnimatorComponent"
				if animator: animator.play_trick()
				elif anim_player:
					anim_player.stop()
					anim_player.play("trick_spin")
			else:
				is_drifting = true
				drift_dir = sign(turn) 
				_do_visual_hop()
				
		elif not is_grounded and air_time < 0.4 and not has_tricked:
			has_tricked = true
			perfect_trick = (time_since_ramp < 0.2)
			trick_spin_timer = 0.5
			var animator = $"../CharacterAnimatorComponent"
			if animator: animator.play_trick()
			elif anim_player:
				anim_player.stop()
				anim_player.play("trick_spin")
			
	if is_grounded:
		if input.drift and is_drifting:
			if drift_dir == 0 and turn != 0:
				drift_dir = sign(turn)
				
			if drift_dir != 0:
				turn_speed = stats.handling * 1.5
				turn = clamp((drift_dir * 0.6) + (input.steer * 0.8), -1.0, 1.0)
				if sign(input.steer) == drift_dir and input.steer != 0:
					drift_time += 2.0 * delta
				elif input.steer == 0:
					drift_time += 1.0 * delta
				else:
					drift_time += 0.25 * delta 
			else:
				turn = input.steer
				drift_time = 0.0
		else:
			if is_drifting and drift_dir != 0: _apply_drift_boost()
			is_drifting = false
			drift_dir = 0
			drift_time = 0.0
			
		kart_body.rotate_object_local(Vector3.UP, turn * turn_speed * speed_ratio * delta)
		
	var forward_dir = -kart_body.global_transform.basis.z
	forward_velocity = forward_dir * current_speed
	kart_body.velocity = forward_velocity + (surface_normal * y_velocity) + slip_velocity
	kart_body.move_and_slide()
	
	var hit_wall = false
	var wall_normal = Vector3.ZERO
	var wall_dot = 0.0
	
	if is_grounded:
		for i in kart_body.get_slide_collision_count():
			var col = kart_body.get_slide_collision(i)
			var n = col.get_normal()
			var angle = rad_to_deg(acos(n.dot(surface_normal)))
			
			if angle > 70.0 and angle < 110.0:
				var dot = forward_dir.dot(n)
				if dot < wall_dot:
					hit_wall = true
					wall_normal = n
					wall_dot = dot
			
	if hit_wall and current_speed > 5.0:
		if wall_dot < -0.1:
			if wall_bump_cooldown <= 0.0:
				current_speed *= clamp(1.0 - (abs(wall_dot) * 0.7), 0.4, 0.95)
				is_drifting = false
				drift_time = 0.0
				wall_bump_cooldown = 0.3
				
				var push_velocity = wall_normal * (current_speed * abs(wall_dot))
				kart_body.velocity += push_velocity
				
				_do_visual_hop()
			else:
				current_speed -= current_speed * 1.5 * delta

	if is_grounded and not was_grounded and air_time > 0.15:
		if vfx and vfx.has_method("play_landing_vfx"):
			vfx.play_landing_vfx()
			
	was_grounded = is_grounded
	
	if visual_model:
		var visual_basis = kart_body.global_transform.basis.orthonormalized()
		var visual_scale = visual_model.scale
		
		if not is_grounded:
			var physical_pitch = visual_basis.z.y
			if abs(physical_pitch) < 0.3:
				var pitch = clamp(kart_body.velocity.y / -40.0, 0.0, 0.4)
				if pitch > 0.01:
					visual_basis = visual_basis.rotated(visual_basis.x, -pitch)
		
		if wheels_component:
			wheels_component.global_transform.basis = visual_basis
			wheels_component.position.y = base_wheel_y + visual_hop_offset

		var local_spin = initial_visual_basis
		if spin_angle != 0.0:
			local_spin = local_spin.rotated(Vector3.UP, spin_angle)

		visual_model.global_transform.basis = visual_basis * local_spin
		visual_model.scale = visual_scale 
		visual_model.position.y = base_visual_y + visual_hop_offset

func start_cannon_flight(path: Path3D, speed: float) -> void:
	is_in_cannon = true
	cannon_path = path
	cannon_speed = speed
	cannon_offset = 0.0
	is_grounded = false
	has_tricked = false
	drift_time = 0.0
	is_drifting = false
	boost_time = 0.0
	y_velocity = 0.0
	
	cannon_entry_speed = current_speed
	current_speed = 0.0
	
	if path.curve:
		var local_pos = path.to_local(kart_body.global_position)
		cannon_offset = path.curve.get_closest_offset(local_pos)

func apply_upward_launch(force: float) -> void:
	y_velocity = max(y_velocity, force)
	is_grounded = false
	has_tricked = false
	kart_body.global_position.y += 0.5

func apply_item_boost(duration: float, power: float) -> void:
	boost_time = max(boost_time, duration)
	boost_power = max(boost_power, power)
	current_speed = max(current_speed, stats.top_speed + power)

func apply_hazard(penalty: float, duration: float) -> void:
	hazard_time = max(hazard_time, duration)
	hazard_penalty = penalty
	
	is_stunned = true
	stun_time = duration
	current_speed *= 0.2
	
	var animator = $"../CharacterAnimatorComponent"
	if animator: animator.play_stun()
	elif anim_player:
		anim_player.stop()
		anim_player.play("trick_spin")

func _apply_drift_boost() -> void:
	if drift_time >= 4.5: apply_item_boost(2.5, 18.0)  
	elif drift_time >= 2.5: apply_item_boost(1.5, 12.0)
	elif drift_time >= 1.0: apply_item_boost(0.8, 6.0)

func apply_start_boost(quality: float) -> void:
	apply_item_boost(quality, 12.0)

func _align_with_y(basis: Basis, new_y: Vector3) -> Basis:
	new_y = new_y.normalized()
	var x = (-basis.z).cross(new_y)
	if x.length_squared() < 0.001: 
		x = basis.x
	x = x.normalized()
	var z = x.cross(new_y).normalized()
	return Basis(x, new_y, z).orthonormalized()

