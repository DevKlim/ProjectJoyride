@tool
extends Resource
class_name RoadProfileResource

@export var profile_name: String = "Default Road"
@export var road_width: float = 50.0
@export var road_depth: float = 10.0

@export var generate_walls: bool = true
@export var wall_height: float = 8.0
@export var wall_thickness: float = 2.0

@export var road_material: Material
@export var wall_material: Material

func _init() -> void:
	changed.emit()
