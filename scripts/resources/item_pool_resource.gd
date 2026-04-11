extends Resource
class_name ItemPoolResource

@export var pool_name: String = "Default Pool"
@export var pool_weight: float = 1.0

## Dictionary mapping item IDs (String) to drop weight (float)
## Example: {"nitro_capsule": 10.0, "plasma_drive": 2.5}
@export var items: Dictionary = {}

func _init() -> void:
	pass
	