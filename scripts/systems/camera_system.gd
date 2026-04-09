class_name CameraSystem
extends Node3D

@export var target: Node3D
@export var follow_distance: float = 6.0
@export var follow_height: float = 2.5
@export var smooth_speed: float = 12.0
@export var fov_base: float = 75.0
@export var fov_max: float = 100.0

@onready var camera: Camera3D = $Camera3D

func _physics_process(delta: float) -> void:
	if not target: return
	
	var target_pos = target.global_position - target.global_transform.basis.z * follow_distance
	target_pos.y += follow_height
	
	global_position = global_position.lerp(target_pos, smooth_speed * delta)
	look_at(target.global_position + Vector3.UP * 1.5)
	
	if target is CharacterBody3D:
		var speed_ratio = target.velocity.length() / 40.0
		camera.fov = lerp(camera.fov, fov_base + (fov_max - fov_base) * speed_ratio, delta * 5.0)
