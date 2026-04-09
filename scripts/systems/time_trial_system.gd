class_name TimeTrialSystem
extends Node

signal race_started
signal race_finished(total_time: float)
signal new_best_lap(time: float)
signal countdown_tick(tick: int)

enum State { PRE_RACE, COUNTDOWN, RACING, FINISHED }
var state: State = State.PRE_RACE

var player_lap_tracker: LapTrackerComponent
var total_time: float = 0.0
var best_lap_time: float = 99999.0
var countdown_timer: float = 4.0

func initialize(tracker: LapTrackerComponent) -> void:
	player_lap_tracker = tracker
	player_lap_tracker.lap_completed.connect(_on_lap_completed)
	player_lap_tracker.race_finished.connect(_on_race_finished)

func begin_countdown() -> void:
	state = State.COUNTDOWN
	countdown_timer = 4.0

func start_race() -> void:
	state = State.RACING
	total_time = 0.0
	if player_lap_tracker:
		player_lap_tracker.is_active = true
	race_started.emit()

func _process(delta: float) -> void:
	if state == State.COUNTDOWN:
		var prev_tick = int(ceil(countdown_timer))
		countdown_timer -= delta
		var curr_tick = int(ceil(countdown_timer))
		
		if curr_tick != prev_tick:
			countdown_tick.emit(curr_tick)
			
		if countdown_timer <= 0:
			start_race()
			
	elif state == State.RACING:
		total_time += delta

func _on_lap_completed(lap: int, time: float) -> void:
	if time < best_lap_time:
		best_lap_time = time
		new_best_lap.emit(best_lap_time)

func _on_race_finished() -> void:
	state = State.FINISHED
	race_finished.emit(total_time)
