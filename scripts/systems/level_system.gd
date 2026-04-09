class_name LevelSystem
extends Node

signal level_loaded(level_id: String)

@export var levels_dir: String = "res://scenes/tracks/"
var current_level_node: Node3D

func load_level(level_id: String) -> void:
	var path = levels_dir + level_id + ".tscn"
	if ResourceLoader.exists(path):
		if current_level_node:
			current_level_node.queue_free()
			
		var packed = load(path) as PackedScene
		current_level_node = packed.instantiate()
		add_child(current_level_node)
		level_loaded.emit(level_id)
	else:
		printerr("Level system: Track path not found -> ", path)