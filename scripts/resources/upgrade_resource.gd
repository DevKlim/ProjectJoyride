extends Resource
class_name UpgradeResource

enum UpgradeType { STICKERS, STATS, WHEELS, ITEMS }

@export var id: String
@export var upgrade_name: String
@export var type: UpgradeType = UpgradeType.STATS
@export var cost: int = 100
@export var modifiers: Dictionary = {}

# Wheel specific properties
@export var wheel_mesh: Mesh
@export var wheel_radius: float = 0.4
