class_name GameManager
extends Node

@export var starting_character_id: String = "driver_default"
@export var starting_track_id: String = "figure_8"

@onready var level_system: LevelSystem = $LevelSystem
@onready var time_trial_system: TimeTrialSystem = $TimeTrialSystem
@onready var shop_system: ShopSystem = $ShopSystem
@onready var relocation_system: RelocationSystem = $RelocationSystem
@onready var camera_system: CameraSystem = $CameraSystem
@onready var hud = $HUD

var player_kart: Node3D
var accelerate_start_time: float = 0.0
var checking_start_boost: bool = false

func _ready() -> void:
	_initialize_game()

func _initialize_game() -> void:
	level_system.load_level(starting_track_id)
	
	var kart_scene = load("res://scenes/kart.tscn") as PackedScene
	player_kart = kart_scene.instantiate()
	add_child(player_kart)

	var start_positions = get_tree().get_nodes_in_group("start_position")
	if start_positions.size() > 0:
		player_kart.global_position = start_positions[0].global_position
		
	# Find Checkpoint 0 and orient the player towards it
	var cps = get_tree().get_nodes_in_group("checkpoints")
	var cp0 = null
	for cp in cps:
		if cp.checkpoint_index == 0:
			cp0 = cp
			break
			
	if cp0:
		var target_pos = cp0.global_position
		target_pos.y = player_kart.global_position.y
		player_kart.look_at(target_pos, Vector3.UP)

	var char_path = "res://resources/characters/" + starting_character_id + ".tres"
	var stats_comp = player_kart.get_node("StatsComponent")
	if ResourceLoader.exists(char_path) and stats_comp:
		var character_res = load(char_path) as CharacterResource
		if character_res.stats:
			for stat_key in character_res.stats:
				if stat_key in stats_comp:
					stats_comp.set(stat_key, character_res.stats[stat_key])

	camera_system.target = player_kart

	var lap_tracker = player_kart.get_node("LapTrackerComponent")
	var off_track = player_kart.get_node("OffTrackDetectorComponent")
	var item_comp = player_kart.get_node("ItemComponent")
	
	time_trial_system.initialize(lap_tracker)
	time_trial_system.race_started.connect(_on_race_started)
	time_trial_system.countdown_tick.connect(hud.update_countdown)
	
	lap_tracker.lap_completed.connect(_on_lap_completed)
	lap_tracker.checkpoint_passed.connect(hud.update_debug_checkpoints)
	
	off_track.went_off_track.connect(_on_kart_went_off_track)
	shop_system.coins_changed.connect(hud.update_coins)
	
	item_comp.item_obtained.connect(hud.start_item_roulette)
	item_comp.item_ready.connect(hud.set_ready_item)
	item_comp.item_used.connect(hud.clear_item)
	
	hud.upgrade_selected.connect(_on_upgrade_selected)

	call_deferred("_start_pre_race_selection")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# DEBUG: Add Lap
		if event.keycode == KEY_F1:
			var tracker = player_kart.get_node_or_null("LapTrackerComponent")
			if tracker: tracker.debug_add_lap()
			
		# DEBUG: Clear Race
		if event.keycode == KEY_F2:
			var tracker = player_kart.get_node_or_null("LapTrackerComponent")
			if tracker:
				tracker.current_lap = tracker.max_laps
				tracker.debug_add_lap()

func _process(delta: float) -> void:
	if time_trial_system.state == TimeTrialSystem.State.COUNTDOWN:
		var input_accel = Input.get_axis("accelerate", "brake")
		if input_accel > 0:
			if not checking_start_boost:
				checking_start_boost = true
				accelerate_start_time = time_trial_system.countdown_timer
		else:
			checking_start_boost = false
			
	if time_trial_system.state == TimeTrialSystem.State.RACING:
		hud.update_time(time_trial_system.total_time)
		
		var phys = player_kart.get_node_or_null("KartPhysicsComponent")
		if phys:
			var intensity = 1.0 if phys.boost_time > 0.0 else 0.0
			hud.set_speedlines_intensity(intensity)

func _start_pre_race_selection() -> void:
	get_tree().paused = true
	var choices = shop_system.get_random_upgrades(3)
	hud.show_upgrades(choices)

func _on_upgrade_selected(id: String) -> void:
	for u in shop_system.available_upgrades:
		if u.id == id:
			var us = $UpgradeSystem
			us.target_kart = player_kart
			us.apply_upgrade(u)
			break
			
	if time_trial_system.state == TimeTrialSystem.State.PRE_RACE:
		get_tree().paused = false
		time_trial_system.begin_countdown()
	else:
		get_tree().paused = false

func _on_race_started() -> void:
	hud.on_race_started()
	if checking_start_boost:
		if accelerate_start_time <= 2.2 and accelerate_start_time >= 0.5:
			var quality = (2.2 - accelerate_start_time) * 1.5
			player_kart.get_node("KartPhysicsComponent").apply_start_boost(quality)

func _on_lap_completed(lap: int, time: float) -> void:
	hud.update_lap(lap, time)
	if lap <= 3:
		var choices = shop_system.get_random_upgrades(3)
		hud.show_upgrades(choices)

func _on_kart_went_off_track(safe_pos: Vector3, safe_rot: Vector3) -> void:
	relocation_system.relocate_entity(player_kart, safe_pos, safe_rot)

