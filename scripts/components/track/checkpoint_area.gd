class_name CheckpointArea
extends Area3D

@export var checkpoint_index: int = 0
@export var debug_visuals: bool = true

func _ready() -> void:
	add_to_group("checkpoints")
	body_entered.connect(_on_body_entered)
	
	var shape_size = Vector3(120, 40, 10) # default fallback size for 10x scale
	
	var coll = get_node_or_null("CollisionShape3D")
	if not coll:
		coll = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = shape_size
		coll.shape = shape
		add_child(coll)
	elif coll.shape is BoxShape3D:
		shape_size = coll.shape.size
		
	if debug_visuals:
		_create_debug_visuals(shape_size)

func _create_debug_visuals(size: Vector3) -> void:
	# Translucent box shading
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.0, 1.0, 0.8, 0.3) # Cyan-ish glass
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	box.material = mat
	mesh_inst.mesh = box
	add_child(mesh_inst)
	
	# Number label above checkpoint
	var label = Label3D.new()
	label.text = str(checkpoint_index)
	label.pixel_size = 0.2  # Large enough to see from afar
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1, 1, 0, 1) # Yellow
	label.outline_render_priority = 1
	label.outline_modulate = Color(0, 0, 0, 1)
	label.font_size = 120
	label.position = Vector3(0, (size.y / 2) + 10, 0)
	add_child(label)

func _on_body_entered(body: Node3D) -> void:
	var tracker = body.get_node_or_null("LapTrackerComponent")
	if tracker:
		tracker.pass_checkpoint(checkpoint_index)