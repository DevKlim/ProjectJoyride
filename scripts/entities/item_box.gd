class_name ItemBox
extends Area3D

@export var item_pools: Array[ItemPoolResource] = []

var available_items: Array[ItemResource] = []
var respawn_time: float = 3.0
var is_active: bool = true
var rotation_speed: float = 2.0

var visual: Node3D

func _ready() -> void:
	add_to_group("item_boxes")
	body_entered.connect(_on_body_entered)
	
	visual = get_node_or_null("MeshInstance3D")
	if not visual:
		_create_default_visuals()
		
	_load_items()

func _create_default_visuals() -> void:
	var coll = get_node_or_null("CollisionShape3D")
	if not coll:
		coll = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(2, 2, 2)
		coll.shape = shape
		add_child(coll)
		
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.5, 1.5, 1.5)
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0, 0.5, 1, 0.6)
	mat.emission_enabled = true
	mat.emission = Color(0, 0.5, 1, 1)
	box.material = mat
	
	mesh_inst.mesh = box
	mesh_inst.name = "MeshInstance3D"
	add_child(mesh_inst)
	visual = mesh_inst

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
	if not is_active: return
	var item_comp = body.get_node_or_null("ItemComponent")
	if item_comp and not item_comp.has_item():
		var random_item = _roll_random_item()
		if random_item:
			item_comp.give_item(random_item)
			_deactivate()

func _roll_random_item() -> ItemResource:
	if item_pools.size() > 0:
		var total_pool_w = 0.0
		for p in item_pools:
			if p: total_pool_w += p.pool_weight
			
		var r_pool = randf() * total_pool_w
		var chosen_pool = item_pools[0]
		for p in item_pools:
			if not p: continue
			r_pool -= p.pool_weight
			if r_pool <= 0:
				chosen_pool = p
				break
				
		if chosen_pool and chosen_pool.items.size() > 0:
			var total_item_w = 0.0
			for w in chosen_pool.items.values():
				total_item_w += float(w)
			var r_item = randf() * total_item_w
			for item_id in chosen_pool.items.keys():
				r_item -= float(chosen_pool.items[item_id])
				if r_item <= 0:
					return _get_item_res(item_id)
			return _get_item_res(chosen_pool.items.keys()[0])
			
	if available_items.size() > 0:
		return available_items[randi() % available_items.size()]
	return null

func _get_item_res(id: String) -> ItemResource:
	for res in available_items:
		if res.id == id: return res
	return null

func _deactivate() -> void:
	is_active = false
	if visual: visual.visible = false
	await get_tree().create_timer(respawn_time).timeout
	is_active = true
	if visual: visual.visible = true
