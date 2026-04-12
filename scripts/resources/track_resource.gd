extends Resource
class_name TrackResource

@export var id: String
@export var track_name: String
@export var total_laps: int = 3

@export_group("Physics Modifiers")
@export var physics_modifiers: Dictionary = {
	"speed": 1.0,
	"acceleration": 1.0,
	"handling": 1.0,
	"traction": 1.0,
	"weight": 1.0
}
