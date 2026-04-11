class_name CameraSystem
extends Node3D

@export var target: Node3D
@export var follow_distance: float = 7.5
@export var follow_height: float = 5
@export var smooth_speed: float = 12.0
@export var look_smooth_speed: float = 15.0
@export var fov_base: float = 90.0
@export var fov_max: float = 120.0

@onready var camera: Camera3D = $Camera3D

var current_up: Vector3 = Vector3.UP
var current_look_pos: Vector3 = Vector3.ZERO

func _ready() -> void:
	if target:
		current_look_pos = target.global_position

func _physics_process(delta: float) -> void:
	if not target: return
	
	var target_basis = target.global_transform.basis
	var target_up = target_basis.y
	
	current_up = current_up.lerp(target_up, delta * 5.0).normalized()
	
	# Placing the camera using + target_basis.z places it properly behind the kart
	var target_pos = target.global_position + target_basis.z * follow_distance + current_up * follow_height
	
	global_position = global_position.lerp(target_pos, smooth_speed * delta)
	
	# Compute an ideal look position slightly ahead of the kart
	var ideal_look_pos = target.global_position + current_up * 1.5 + target_basis.z * -5.0
	
	if current_look_pos == Vector3.ZERO:
		current_look_pos = ideal_look_pos
		
	# Smoothly track the look position to prevent jerky camera deflection during wall bumps
	current_look_pos = current_look_pos.lerp(ideal_look_pos, look_smooth_speed * delta)
	
	look_at(current_look_pos, current_up)
	
	if target is CharacterBody3D:
		var speed_ratio = clamp(target.velocity.length() / 40.0, 0.0, 1.0)
		camera.fov = clamp(lerp(camera.fov, fov_base + (fov_max - fov_base) * speed_ratio, delta * 5.0), 1.0, 179.0)
