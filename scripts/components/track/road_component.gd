class_name RoadComponent
extends Node3D

@export var is_wall_ride: bool = false
@export var is_anti_gravity: bool = false
@export var friction: float = 1.0

func _ready() -> void:
	# Deferring ensures all child nodes are fully initialized before tagging
	call_deferred("_tag_children_as_road", self)

func _tag_children_as_road(node: Node) -> void:
	if node is PhysicsBody3D or node is CSGShape3D:
		# explicitly ignore elements designed exclusively as guardrail walls
		if not node.is_in_group("wall"):
			if not node.is_in_group("road"):
				node.add_to_group("road")
			if is_wall_ride and not node.is_in_group("wall_ride"):
				node.add_to_group("wall_ride")
			if is_anti_gravity and not node.is_in_group("anti_gravity"):
				node.add_to_group("anti_gravity")
			
	for child in node.get_children():
		_tag_children_as_road(child)
