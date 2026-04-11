class_name CannonComponent
extends Area3D

@export var flight_path: Path3D
@export var flight_speed: float = 120.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node3D) -> void:
	if not flight_path: return
	var physics = body.get_node_or_null("KartPhysicsComponent")
	if physics and physics.has_method("start_cannon_flight"):
		physics.start_cannon_flight(flight_path, flight_speed)

