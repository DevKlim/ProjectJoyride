class_name OffboundsArea
extends Area3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	var off_track = body.get_node_or_null("OffTrackDetectorComponent")
	if off_track:
		off_track.trigger_off_track()
		