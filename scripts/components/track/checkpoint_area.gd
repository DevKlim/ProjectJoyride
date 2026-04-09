class_name CheckpointArea
extends Area3D

@export var checkpoint_index: int = 0

func _ready() -> void:
	add_to_group("checkpoints")
	body_entered.connect(_on_body_entered)
	
	# Generate collision if used dynamically without an editor shape
	if get_child_count() == 0:
		var coll = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(20, 10, 2)
		coll.shape = shape
		add_child(coll)

func _on_body_entered(body: Node3D) -> void:
	var tracker = body.get_node_or_null("LapTrackerComponent")
	if tracker:
		tracker.pass_checkpoint(checkpoint_index)
		