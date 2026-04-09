class_name CollectibleCoin
extends Area3D

@export var value: int = 1
var rotation_speed: float = 3.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	# Auto-generate visual and collision 
	if get_child_count() == 0:
		var coll = CollisionShape3D.new()
		var shape = SphereShape3D.new()
		shape.radius = 0.5
		coll.shape = shape
		add_child(coll)
		
		var mesh_inst = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.height = 0.1
		cyl.top_radius = 0.4
		cyl.bottom_radius = 0.4
		mesh_inst.mesh = cyl
		mesh_inst.rotation_degrees = Vector3(90, 0, 0)
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1, 0.8, 0)
		mat.emission_enabled = true
		mat.emission = Color(1, 0.8, 0)
		cyl.material = mat
		add_child(mesh_inst)

func _process(delta: float) -> void:
	rotate_y(rotation_speed * delta)

func _on_body_entered(body: Node3D) -> void:
	if body.name.begins_with("Kart"):
		var shop = get_tree().get_nodes_in_group("ShopSystem")
		if shop.size() > 0:
			shop[0].add_coins(value)
		queue_free()
