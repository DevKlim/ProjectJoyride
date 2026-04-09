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

func _ready() -> void:
	_initialize_game()

func _initialize_game() -> void:
	# 1. Load Track
	level_system.load_level(starting_track_id)
	
	# 2. Spawn Universal Kart
	var kart_scene = load("res://scenes/kart.tscn") as PackedScene
	if kart_scene:
		player_kart = kart_scene.instantiate()
		add_child(player_kart)
	else:
		printerr("Kart scene missing!")
		return

	# 3. Position Kart on the Track's Start Position
	var start_positions = get_tree().get_nodes_in_group("start_position")
	if start_positions.size() > 0:
		player_kart.global_position = start_positions[0].global_position
		player_kart.rotation = start_positions[0].rotation
	else:
		player_kart.global_position = Vector3(0, 2, 0)

	# 4. Apply Character Stats
	var char_path = "res://resources/characters/" + starting_character_id + ".tres"
	var stats_comp = player_kart.get_node("StatsComponent")
	if ResourceLoader.exists(char_path) and stats_comp:
		var character_res = load(char_path) as CharacterResource
		if character_res.stats:
			for stat_key in character_res.stats:
				if stat_key in stats_comp:
					stats_comp.set(stat_key, character_res.stats[stat_key])

	# 5. Inject Camera 
	camera_system.target = player_kart

	# 6. Setup ECS Links
	var lap_tracker = player_kart.get_node("LapTrackerComponent")
	var off_track = player_kart.get_node("OffTrackDetectorComponent")
	
	time_trial_system.initialize(lap_tracker)
	time_trial_system.race_started.connect(hud.on_race_started)
	
	lap_tracker.lap_completed.connect(hud.update_lap)
	off_track.went_off_track.connect(_on_kart_went_off_track)
	shop_system.coins_changed.connect(hud.update_coins)

	# 7. Start Race
	time_trial_system.start_race()

func _process(_delta: float) -> void:
	if time_trial_system.is_racing:
		hud.update_time(time_trial_system.total_time)

func _on_kart_went_off_track(safe_pos: Vector3, safe_rot: Vector3) -> void:
	relocation_system.relocate_entity(player_kart, safe_pos, safe_rot)
