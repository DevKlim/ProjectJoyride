extends Control

@onready var time_label = $BottomLeftContainer/VBox/TimeLabel
@onready var lap_label = $BottomLeftContainer/VBox/LapLabel
@onready var coin_label = $BottomLeftContainer/VBox/CoinLabel
@onready var countdown_label = $CountdownLabel
@onready var debug_label = $DebugLabel

@onready var item_icon = $ItemContainer/Center/ItemIcon
@onready var speedlines_rect = $SpeedLinesLayer/SpeedLinesRect

@onready var upgrade_panel = $UpgradePanel
@onready var upgrade_container = $UpgradePanel/HBoxContainer

@onready var track_name_container = $TrackNameContainer
@onready var track_name_label = $TrackNameContainer/TrackNameLabel

signal upgrade_selected(upgrade_id: String)

var is_rouletting: bool = false
var roulette_timer: float = 0.0
var available_icons: Array[Texture2D] = []

func _ready() -> void:
	upgrade_panel.hide()
	countdown_label.hide()
	debug_label.text = "Checkpoints: "
	item_icon.texture = null
	track_name_container.modulate.a = 0.0
	set_speedlines_intensity(0.0)
	_load_all_item_icons()

func _load_all_item_icons() -> void:
	var path = "res://resources/items/"
	if DirAccess.dir_exists_absolute(path):
		var dir = DirAccess.open(path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".tres") or file_name.ends_with(".res"):
					var res = load(path + file_name) as ItemResource
					if res and res.icon:
						available_icons.append(res.icon)
				file_name = dir.get_next()

func _process(delta: float) -> void:
	if is_rouletting and available_icons.size() > 0:
		roulette_timer -= delta
		if roulette_timer <= 0.0:
			item_icon.texture = available_icons[randi() % available_icons.size()]
			roulette_timer = 0.05 # Swap icon 20 times a second

func update_countdown(tick: int) -> void:
	if tick > 0 and tick <= 3:
		countdown_label.text = str(tick)
		countdown_label.show()
	elif tick == 0:
		countdown_label.text = "GO!"
		countdown_label.show()
	else:
		countdown_label.hide()

func show_track_name(track_name: String) -> void:
	track_name_label.text = track_name
	var tween = create_tween()
	tween.tween_property(track_name_container, "modulate:a", 1.0, 0.5)
	tween.tween_interval(3.0)
	tween.tween_property(track_name_container, "modulate:a", 0.0, 1.0)

func on_race_started() -> void:
	countdown_label.hide()
	time_label.text = " Time: 0.00"
	lap_label.text = " Lap: 1/3"

func update_time(time: float) -> void:
	time_label.text = " Time: %.2f" % time

func update_lap(lap: int, _lap_time: float) -> void:
	lap_label.text = " Lap: %d/3" % lap

func update_coins(coins: int) -> void:
	coin_label.text = " Coins: %d" % coins

func start_item_roulette(item: ItemResource) -> void:
	is_rouletting = true

func set_ready_item(item: ItemResource) -> void:
	is_rouletting = false
	item_icon.texture = item.icon

func clear_item() -> void:
	is_rouletting = false
	item_icon.texture = null

func set_speedlines_intensity(intensity: float) -> void:
	var mat = speedlines_rect.material as ShaderMaterial
	if mat: mat.set_shader_parameter("intensity", intensity)

func update_debug_checkpoints(visited: Array[bool]) -> void:
	var s = "Checkpoints: "
	for i in visited.size():
		if visited[i]: s += "[%d] " % i
	debug_label.text = s

func show_upgrades(upgrades: Array) -> void:
	upgrade_panel.show()
	for child in upgrade_container.get_children():
		child.queue_free()
		
	for i in upgrades.size():
		var u = upgrades[i]
		var btn = Button.new()
		btn.text = "%d: %s\nTop Spd: +%.1f\nAccel: +%.1f" % [
			i + 1, u.upgrade_name,
			u.modifiers.get("top_speed", 0.0),
			u.modifiers.get("acceleration", 0.0)
		]
		btn.custom_minimum_size = Vector2(150, 100)
		btn.pressed.connect(_on_upgrade_chosen.bind(u.id))
		btn.set_meta("id", u.id)
		upgrade_container.add_child(btn)

func _on_upgrade_chosen(id: String) -> void:
	upgrade_panel.hide()
	upgrade_selected.emit(id)

func _input(event: InputEvent) -> void:
	if upgrade_panel.visible:
		if event is InputEventKey and event.pressed:
			var num = event.keycode - KEY_1
			if num >= 0 and num < upgrade_container.get_child_count():
				_on_upgrade_chosen(upgrade_container.get_child(num).get_meta("id", ""))

