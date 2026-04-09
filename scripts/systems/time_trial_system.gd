class_name TimeTrialSystem
extends Node

signal race_started
signal race_finished(total_time: float)
signal new_best_lap(time: float)

var player_lap_tracker: LapTrackerComponent
var is_racing: bool = false
var total_time: float = 0.0
var best_lap_time: float = 99999.0

func initialize(tracker: LapTrackerComponent) -> void:
	player_lap_tracker = tracker
	player_lap_tracker.lap_completed.connect(_on_lap_completed)
	player_lap_tracker.race_finished.connect(_on_race_finished)

func start_race() -> void:
	is_racing = true
	total_time = 0.0
	if player_lap_tracker:
		player_lap_tracker.is_active = true
	race_started.emit()

func _process(delta: float) -> void:
	if is_racing:
		total_time += delta

func _on_lap_completed(lap: int, time: float) -> void:
	if time < best_lap_time:
		best_lap_time = time
		new_best_lap.emit(best_lap_time)

func _on_race_finished() -> void:
	is_racing = false
	race_finished.emit(total_time)
	
