@tool
extends Resource
class_name TrackSegmentResource

@export var override_profile: TrackProfileResource
@export var override_material: Material
@export var override_wall_material: Material

@export_group("Width Override")
@export var override_width: bool = false:
	set(v):
		override_width = v
		emit_changed()
@export var start_width: float = 40.0:
	set(v):
		start_width = v
		emit_changed()
@export var end_width: float = 40.0:
	set(v):
		end_width = v
		emit_changed()

@export_group("Physics")
@export var is_anti_gravity: bool = false:
	set(v):
		is_anti_gravity = v
		emit_changed()
		
@export var is_wall_ride: bool = false:
	set(v):
		is_wall_ride = v
		emit_changed()

@export_group("Physics Modifiers")
@export var physics_modifiers: Dictionary = {}

@export_group("Face Toggles")
@export var generate_front_face: bool = false
@export var generate_back_face: bool = false

@export_group("Tunnel Lighting")
@export var generate_lights: bool = false
@export var light_color: Color = Color(1.0, 0.9, 0.7)
@export var light_energy: float = 2.0
@export var light_spacing: float = 20.0
@export var light_height: float = 6.0

func _init() -> void:
	emit_changed()
