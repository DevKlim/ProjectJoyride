class_name KartPhysicsComponent
extends Node

@export var kart_body: CharacterBody3D
@export var gravity: float = 30.0
@export var jump_force: float = 8.0
@export var drift_boost_thresholds: Array[float] = [1.5, 3.0, 5.0]

var current_speed: float = 0.0
var forward_velocity: Vector3 = Vector3.ZERO
var y_velocity: float = 0.0

var is_drifting: bool = false
var drift_dir: int = 0
var drift_time: float = 0.0

var boost_time: float = 0.0
var boost_multiplier: float = 1.0

var has_tricked: bool = false

@onready var input: KartInputComponent = $"../KartInputComponent"
@onready var stats: StatsComponent = $"../StatsComponent"
@onready var anim_player: AnimationPlayer = $"../AnimationPlayer"

func _physics_process(delta: float) -> void:
	if not kart_body or not input or not stats: return
	
	# Gravity & Tricking
	if not kart_body.is_on_floor():
		y_velocity -= gravity * delta
		
		# Mid-air Tricking (Spins car and readies a landing boost)
		if input.drift_just_pressed and not has_tricked:
			has_tricked = true
			if anim_player:
				anim_player.stop()
				anim_player.play("trick_spin")
	else:
		if has_tricked:
			has_tricked = false
			apply_item_boost(1.5, 1.3) # Trick boost landing
		y_velocity = -0.1
		
	# Acceleration & Boosting
	var target_speed = input.accelerate * stats.top_speed
	
	if boost_time > 0:
		target_speed = stats.top_speed * boost_multiplier
		boost_time -= delta
		if boost_time <= 0:
			boost_multiplier = 1.0 # Reset when done
		
	current_speed = move_toward(current_speed, target_speed, stats.acceleration * delta)
	
	# Steering & Drifting
	var turn = input.steer
	var turn_speed = stats.handling
	
	# Restrict turning when standing still
	var speed_ratio = clamp(abs(current_speed) / 10.0, 0.0, 1.0)
	
	if kart_body.is_on_floor():
		# Tiny hop on tap, prevents re-hopping if held
		if input.drift_just_pressed and abs(current_speed) > 10.0:
			y_velocity = jump_force * 0.6
			is_drifting = true
			drift_dir = sign(turn) if turn != 0 else 1
			
		# Continues drift if held
		if input.drift and is_drifting:
			turn_speed = stats.handling * 1.5
			drift_time += delta
			turn = clamp(turn + drift_dir * 0.4, -1.0, 1.0)
		else:
			if is_drifting:
				_apply_drift_boost()
			is_drifting = false
			drift_time = 0.0
			
		kart_body.rotate_y(turn * turn_speed * speed_ratio * delta)
		
	# Apply Movement
	forward_velocity = -kart_body.global_transform.basis.z * current_speed
	kart_body.velocity = forward_velocity + Vector3.UP * y_velocity
	kart_body.move_and_slide()

func apply_item_boost(duration: float, strength: float) -> void:
	boost_time = max(boost_time, duration)
	boost_multiplier = max(boost_multiplier, strength)

func _apply_drift_boost() -> void:
	if drift_time >= 3.0: apply_item_boost(2.0, 1.3)
	elif drift_time >= 1.5: apply_item_boost(1.0, 1.25)
	elif drift_time >= 0.5: apply_item_boost(0.5, 1.2)

func apply_start_boost(quality: float) -> void:
	apply_item_boost(quality, 1.4)

