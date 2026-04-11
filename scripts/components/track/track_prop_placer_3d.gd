@tool
class_name TrackPropPlacer3D
extends Node3D

enum MovementType { NONE, PENDULUM, HOVER, SPIN }

@export var track_offset: float = 0.0:
	set(v): track_offset = max(0.0, v); _update_position()

@export var lateral_offset: float = 0.0:
	set(v): lateral_offset = v; _update_position()

@export var height_offset: float = 0.0:
	set(v): height_offset = v; _update_position()
	
@export_group("Movement")
@export var movement_type: MovementType = MovementType.NONE
@export var movement_speed: float = 2.0
@export var movement_range: float = 5.0

var _base_transform: Transform3D
var _time: float = 0.0

func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
	else:
		set_process(movement_type != MovementType.NONE)
	_update_position()

func _process(delta: float) -> void:
	if movement_type == MovementType.NONE: return
	
	_time += delta
	var t = _base_transform
	
	match movement_type:
		MovementType.PENDULUM:
			var offset = sin(_time * movement_speed) * movement_range
			t.origin += t.basis.x * offset
		MovementType.HOVER:
			var offset = sin(_time * movement_speed) * movement_range
			t.origin += t.basis.y * offset
		MovementType.SPIN:
			t.basis = t.basis.rotated(Vector3.UP, _time * movement_speed)
			
	global_transform = t

func _update_position() -> void:
	var parent_track = get_parent()
	if not parent_track or not "curve" in parent_track or not parent_track.curve: return
	
	var curve = parent_track.curve
	if track_offset > curve.get_baked_length(): return
	
	_base_transform = curve.sample_baked_with_rotation(track_offset)
	_base_transform.origin += _base_transform.basis.x * lateral_offset
	_base_transform.origin += _base_transform.basis.y * height_offset
	
	global_transform = _base_transform

