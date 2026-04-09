class_name OffTrackDetectorComponent
extends Node

signal went_off_track(last_safe_position: Vector3, safe_rotation: Vector3)

var last_safe_position: Vector3
var last_safe_rotation: Vector3
var safe_timer: float = 0.0

func _physics_process(delta: float) -> void:
	var kart = get_parent() as CharacterBody3D
	if not kart: return
	
	if kart.is_on_floor(): # In real-world, also check ground type (exclude lava/void)
		safe_timer += delta
		if safe_timer > 1.0:
			last_safe_position = kart.global_position
			last_safe_rotation = kart.rotation
			safe_timer = 0.0

func trigger_off_track() -> void:
	went_off_track.emit(last_safe_position, last_safe_rotation)
	