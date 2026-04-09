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

@onready var input: KartInputComponent = $"../KartInputComponent"
@onready var stats: StatsComponent = $"../StatsComponent"

func _physics_process(delta: float) -> void:
	if not kart_body or not input or not stats: return
	
	# Gravity
	if not kart_body.is_on_floor():
		y_velocity -= gravity * delta
	else:
		y_velocity = -0.1
		
	# Acceleration
	var target_speed = input.accelerate * stats.top_speed
	if boost_time > 0:
		target_speed = stats.top_speed * 1.5
		boost_time -= delta
		
	current_speed = move_toward(current_speed, target_speed, stats.acceleration * delta)
	
	# Steering & Drifting
	var turn = input.steer
	var turn_speed = stats.handling
	
	if kart_body.is_on_floor():
		if input.drift and current_speed > 10.0:
			if not is_drifting: # Initiate hop
				y_velocity = jump_force
				is_drifting = true
				drift_dir = sign(turn) if turn != 0 else 1
			
			turn_speed = stats.handling * 1.5
			drift_time += delta
			turn = clamp(turn + drift_dir * 0.4, -1.0, 1.0) # Restrict steering inward based on drift dir
		else:
			if is_drifting: # Release for Mini-Turbo
				_apply_drift_boost()
			is_drifting = false
			drift_time = 0.0
			
		kart_body.rotate_y(turn * turn_speed * delta)
		
	# Apply Movement
	forward_velocity = -kart_body.global_transform.basis.z * current_speed
	kart_body.velocity = forward_velocity + Vector3.UP * y_velocity
	kart_body.move_and_slide()

func _apply_drift_boost() -> void:
	if drift_time >= drift_boost_thresholds[2]: boost_time = 2.0     # Purple spark
	elif drift_time >= drift_boost_thresholds[1]: boost_time = 1.0   # Orange spark
	elif drift_time >= drift_boost_thresholds[0]: boost_time = 0.5   # Blue spark
