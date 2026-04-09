class_name LapTrackerComponent
extends Node

signal lap_completed(lap_number: int, lap_time: float)
signal race_finished()

@export var max_laps: int = 3
var total_checkpoints: int = 0

var current_lap: int = 1
var current_checkpoint: int = 0
var current_lap_time: float = 0.0
var is_active: bool = false

func _ready() -> void:
	# Give the scene a moment to load, then count checkpoints dynamically
	call_deferred("_initialize_checkpoints")

func _initialize_checkpoints() -> void:
	total_checkpoints = get_tree().get_nodes_in_group("checkpoints").size()

func _process(delta: float) -> void:
	if is_active: current_lap_time += delta

func pass_checkpoint(cp_index: int) -> void:
	if not is_active or total_checkpoints == 0: return
	
	if cp_index == current_checkpoint + 1:
		current_checkpoint = cp_index
	elif cp_index == 0 and current_checkpoint == total_checkpoints - 1:
		lap_completed.emit(current_lap, current_lap_time)
		current_lap += 1
		current_checkpoint = 0
		current_lap_time = 0.0
		
		if current_lap > max_laps:
			is_active = false
			race_finished.emit()
