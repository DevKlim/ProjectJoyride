class_name LapTrackerComponent
extends Node

signal lap_completed(lap_number: int, lap_time: float)
signal race_finished()
signal checkpoint_passed(visited: Array[bool])

@export var max_laps: int = 3
var total_checkpoints: int = 0
var passed_checkpoints: Array[bool] = []

var current_lap: int = 1
var current_checkpoint: int = -1 # Start at -1 so the next expected is 0
var current_lap_time: float = 0.0
var is_active: bool = false

func _ready() -> void:
	call_deferred("_initialize_checkpoints")

func _initialize_checkpoints() -> void:
	var cps = get_tree().get_nodes_in_group("checkpoints")
	total_checkpoints = cps.size()
	passed_checkpoints.resize(total_checkpoints)
	passed_checkpoints.fill(false)

func _process(delta: float) -> void:
	if is_active: current_lap_time += delta

func pass_checkpoint(cp_index: int) -> void:
	if not is_active or total_checkpoints == 0: return
	if cp_index >= total_checkpoints: return
	
	# Determine the required next checkpoint to enforce linear order
	var expected_checkpoint = (current_checkpoint + 1) % total_checkpoints
	
	if cp_index == expected_checkpoint:
		passed_checkpoints[cp_index] = true
		current_checkpoint = cp_index
		checkpoint_passed.emit(passed_checkpoints)
		
		# Detect a successful lap wrap-around
		if cp_index == 0 and passed_checkpoints[total_checkpoints - 1]:
			lap_completed.emit(current_lap, current_lap_time)
			current_lap += 1
			current_lap_time = 0.0
			
			passed_checkpoints.fill(false)
			passed_checkpoints[0] = true
			checkpoint_passed.emit(passed_checkpoints)
			
			if current_lap > max_laps:
				is_active = false
				race_finished.emit()

func debug_add_lap() -> void:
	if not is_active: return
	
	lap_completed.emit(current_lap, current_lap_time)
	current_lap += 1
	current_lap_time = 0.0
	
	passed_checkpoints.fill(false)
	if total_checkpoints > 0:
		passed_checkpoints[0] = true
		current_checkpoint = 0
		checkpoint_passed.emit(passed_checkpoints)
		
	if current_lap > max_laps:
		is_active = false
		race_finished.emit()

