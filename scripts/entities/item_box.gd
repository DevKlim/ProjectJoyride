class_name ItemBox
extends Area3D

var available_items: Array[ItemResource] = []
var respawn_time: float = 3.0
var is_active: bool = true
var rotation_speed: float = 2.0

@onready var visual = $MeshInstance3D

func _ready() -> void:
	add_to_group("item_boxes")
	body_entered.connect(_on_body_entered)
	_load_items()

func _load_items() -> void:
	var path = "res://resources/items/"
	if DirAccess.dir_exists_absolute(path):
		var dir = DirAccess.open(path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".tres") or file_name.ends_with(".res"):
					var res = load(path + file_name) as ItemResource
					if res: available_items.append(res)
				file_name = dir.get_next()

func _process(delta: float) -> void:
	if is_active and visual:
		visual.rotate_y(rotation_speed * delta)
		visual.rotate_x(rotation_speed * 0.5 * delta)
		
func _on_body_entered(body: Node3D) -> void:
	if not is_active or available_items.is_empty(): return
	var item_comp = body.get_node_or_null("ItemComponent")
	if item_comp and not item_comp.has_item():
		var random_item = available_items[randi() % available_items.size()]
		item_comp.give_item(random_item)
		_deactivate()

func _deactivate() -> void:
	is_active = false
	if visual: visual.visible = false
	await get_tree().create_timer(respawn_time).timeout
	is_active = true
	if visual: visual.visible = true

