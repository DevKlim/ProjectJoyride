@tool
class_name TrackElementBuilder3D
extends Node3D

enum ElementType { FLAT_BOOST_PAD, BOOST_RAMP, JUMP_RAMP, ITEM_BOX, HAZARD, CANNON, WIND_GUST }
enum MovementType { NONE, PENDULUM, HOVER, SPIN, SIDE_TO_SIDE }

@export var element_type: ElementType = ElementType.FLAT_BOOST_PAD:
	set(v): element_type = v; _queue_rebuild()

@export_category("Positioning & Size")
@export var track_offset: float = 0.0: ## Distance along the parent track's curve.
	set(v): track_offset = max(0.0, v); _queue_rebuild()

@export var length: float = 10.0:
	set(v): length = max(1.0, v); _queue_rebuild()

@export var width: float = 10.0:
	set(v): width = max(1.0, v); _queue_rebuild()

@export var match_track_width: bool = false: ## Automatically scales the width to fit the track segment.
	set(v): match_track_width = v; _queue_rebuild()

@export var width_ratio: float = 1.0: ## Scales the matched track width.
	set(v): width_ratio = v; _queue_rebuild()

@export var lateral_offset: float = 0.0: ## Move left or right from the center of the track.
	set(v): lateral_offset = v; _queue_rebuild()

@export var height_offset: float = 0.0:
	set(v): height_offset = v; _queue_rebuild()

@export_category("Movement Dynamics")
@export var movement_type: MovementType = MovementType.NONE
@export var movement_speed: float = 2.0
@export var movement_range: float = 5.0

@export_category("Ramp/Pad Settings")
@export var ramp_height: float = 3.0:
	set(v): ramp_height = v; _queue_rebuild()

@export var ramp_curve: Curve: ## Optional: define a custom easing slope for the ramp!
	set(v): 
		if ramp_curve and ramp_curve.changed.is_connected(_queue_rebuild):
			ramp_curve.changed.disconnect(_queue_rebuild)
		ramp_curve = v
		if ramp_curve:
			ramp_curve.changed.connect(_queue_rebuild)
		_queue_rebuild()

@export var boost_power: float = 25.0
@export var boost_duration: float = 1.5

@export_category("Boost Pad Settings (For Ramps)")
@export var boost_pad_size: Vector2 = Vector2(8.0, 4.0):
	set(v): boost_pad_size = v; _queue_rebuild()
@export var boost_pad_position_ratio: float = 0.5: ## 0.0 = Start of ramp, 1.0 = End of ramp
	set(v): boost_pad_position_ratio = clamp(v, 0.0, 1.0); _queue_rebuild()

@export_category("Item Box Settings")
@export var item_pools: Array[ItemPoolResource] = []

@export_category("Hazard Settings")
@export var hazard_penalty: float = 0.3
@export var hazard_duration: float = 1.5

@export_category("Cannon Settings")
@export var cannon_flight_path: Path3D
@export var cannon_flight_speed: float = 120.0

@export_category("Wind Settings")
@export var wind_upward_force: float = 40.0
@export var wind_constant_lift: bool = true
@export var wind_radius: float = 12.0
@export var wind_height: float = 60.0

@export_category("Visuals")
@export var resolution: float = 1.0:
	set(v): resolution = max(0.5, v); _queue_rebuild()

@export var element_material: Material:
	set(v): element_material = v; _queue_rebuild()


var _is_dirty: bool = false
var _container: Node3D
var _time: float = 0.0

func _ready() -> void:
	var parent_track = get_parent()
	if parent_track and parent_track.has_signal("track_rebuilt") and not parent_track.track_rebuilt.is_connected(_queue_rebuild):
		parent_track.track_rebuilt.connect(_queue_rebuild)
	_queue_rebuild()

func _process(delta: float) -> void:
	if not is_instance_valid(_container): return
	
	if movement_type == MovementType.NONE:
		if element_type in [ElementType.ITEM_BOX, ElementType.HAZARD, ElementType.CANNON, ElementType.WIND_GUST]:
			_container.transform = _get_base_transform()
		else:
			_container.transform = Transform3D.IDENTITY
		return
		
	_time += delta
	var t = Transform3D.IDENTITY
	
	if element_type in [ElementType.ITEM_BOX, ElementType.HAZARD, ElementType.CANNON, ElementType.WIND_GUST]:
		t = _get_base_transform()
		
	var offset_t = Transform3D.IDENTITY
	match movement_type:
		MovementType.PENDULUM:
			offset_t = offset_t.rotated(Vector3.FORWARD, sin(_time * movement_speed) * (movement_range * 0.1))
		MovementType.HOVER:
			offset_t.origin.y = sin(_time * movement_speed) * movement_range
		MovementType.SPIN:
			offset_t = offset_t.rotated(Vector3.UP, _time * movement_speed)
		MovementType.SIDE_TO_SIDE:
			offset_t.origin.x = sin(_time * movement_speed) * movement_range
			
	_container.transform = t * offset_t

func _get_base_transform() -> Transform3D:
	var parent_track = get_parent()
	if not parent_track or not "curve" in parent_track or not parent_track.curve: return Transform3D.IDENTITY
	var curve = parent_track.curve
	var track_len = curve.get_baked_length()
	if track_offset > track_len: return Transform3D.IDENTITY
	
	var trans = curve.sample_baked_with_rotation(track_offset)
	trans.origin += trans.basis.x * lateral_offset
	trans.origin += trans.basis.y * height_offset
	return trans

func _queue_rebuild() -> void:
	if not _is_dirty:
		_is_dirty = true
		call_deferred("_rebuild")

func _rebuild() -> void:
	_is_dirty = false
	
	for child in get_children():
		child.name = "Deleted_" + child.name
		child.queue_free()
		
	var parent_track = get_parent()
	if not parent_track or not "curve" in parent_track or not parent_track.curve or parent_track.curve.get_baked_length() == 0:
		return
		
	var curve = parent_track.curve
	var track_len = curve.get_baked_length()
	if track_offset >= track_len: return
	
	_container = Node3D.new()
	_container.name = "ElementContainer"
	add_child(_container)

	# --- MESH BASED ELEMENTS (RAMPS & BOOST PADS) ---
	if element_type in [ElementType.FLAT_BOOST_PAD, ElementType.BOOST_RAMP, ElementType.JUMP_RAMP]:
		var actual_length = min(length, track_len - track_offset)
		var steps = int(max(1, ceil(actual_length / resolution)))
		var actual_res = actual_length / steps
		
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		
		var mat = element_material
		if not mat:
			mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0, 1, 0) if element_type != ElementType.JUMP_RAMP else Color(1, 0.5, 0)
		st.set_material(mat)
			
		for r in range(steps + 1):
			var t_dist = track_offset + (r * actual_res)
			var progress_ratio = float(r) / float(steps)
			var trans = curve.sample_baked_with_rotation(t_dist)
			
			var current_w = width
			if match_track_width and parent_track.has_method("get_track_width_at_offset"):
				current_w = parent_track.get_track_width_at_offset(t_dist) * width_ratio
				
			var half_w_step = current_w * 0.5
			var h = height_offset + 0.05
			
			if element_type in [ElementType.BOOST_RAMP, ElementType.JUMP_RAMP]:
				var ratio = progress_ratio
				if ramp_curve: ratio = ramp_curve.sample_baked(progress_ratio)
				h = lerp(height_offset + 0.05, height_offset + ramp_height, ratio)
				
			var top_l = trans * Vector3(-half_w_step + lateral_offset, h, 0)
			var top_r = trans * Vector3(half_w_step + lateral_offset, h, 0)
			var bot_l = trans * Vector3(-half_w_step + lateral_offset, height_offset, 0)
			var bot_r = trans * Vector3(half_w_step + lateral_offset, height_offset, 0)
			
			var v_coord = progress_ratio * actual_length
			
			st.set_uv(Vector2(0, v_coord))
			st.add_vertex(top_l)
			st.set_uv(Vector2(1, v_coord))
			st.add_vertex(top_r)
			st.set_uv(Vector2(0, v_coord))
			st.add_vertex(bot_l)
			st.set_uv(Vector2(1, v_coord))
			st.add_vertex(bot_r)
			
		for r in range(steps):
			var v0 = r * 4
			var v1 = v0 + 1
			var v2 = v0 + 2
			var v3 = v0 + 3
			var v4 = (r + 1) * 4
			var v5 = v4 + 1
			var v6 = v4 + 2
			var v7 = v4 + 3
			
			st.add_index(v0); st.add_index(v4); st.add_index(v5)
			st.add_index(v0); st.add_index(v5); st.add_index(v1)
			st.add_index(v2); st.add_index(v3); st.add_index(v7)
			st.add_index(v2); st.add_index(v7); st.add_index(v6)
			st.add_index(v0); st.add_index(v2); st.add_index(v6)
			st.add_index(v0); st.add_index(v6); st.add_index(v4)
			st.add_index(v1); st.add_index(v5); st.add_index(v7)
			st.add_index(v1); st.add_index(v7); st.add_index(v3)
			
		st.add_index(0); st.add_index(1); st.add_index(3)
		st.add_index(0); st.add_index(3); st.add_index(2)
		var b0 = steps * 4
		st.add_index(b0); st.add_index(b0 + 2); st.add_index(b0 + 3)
		st.add_index(b0); st.add_index(b0 + 3); st.add_index(b0 + 1)

		st.generate_normals()
		st.generate_tangents()
		
		var mesh = ArrayMesh.new()
		st.commit(mesh)
		
		var mesh_inst = MeshInstance3D.new()
		mesh_inst.mesh = mesh
		_container.add_child(mesh_inst)
		
		# Generate solid collision for physical presence
		if element_type in [ElementType.JUMP_RAMP, ElementType.BOOST_RAMP]:
			var static_body = StaticBody3D.new()
			static_body.add_to_group("road")
			mesh_inst.add_child(static_body)
			var static_col = CollisionShape3D.new()
			static_col.shape = mesh.create_trimesh_shape()
			static_body.add_child(static_col)
			
		# Generate functional Area3D triggers
		var area: Area3D = null
		if element_type == ElementType.JUMP_RAMP:
			var r_script = load("res://scripts/components/track/ramp_component.gd")
			if r_script: area = r_script.new()
			else: area = Area3D.new()
			
			var area_col = CollisionShape3D.new()
			area_col.shape = mesh.create_trimesh_shape()
			area.add_child(area_col)
			mesh_inst.add_child(area)
			
		elif element_type == ElementType.FLAT_BOOST_PAD:
			var b_script = load("res://scripts/components/track/boost_pad_component.gd")
			if b_script:
				area = b_script.new()
				area.boost_duration = boost_duration
				area.boost_power = boost_power
				
				var area_col = CollisionShape3D.new()
				var box = BoxShape3D.new()
				
				var center_t = track_offset + (actual_length * 0.5)
				var current_w = width
				if match_track_width and parent_track.has_method("get_track_width_at_offset"):
					current_w = parent_track.get_track_width_at_offset(center_t) * width_ratio
					
				box.size = Vector3(current_w, 3.0, actual_length)
				
				var t_trans = curve.sample_baked_with_rotation(center_t)
				t_trans.origin += t_trans.basis.x * lateral_offset
				t_trans.origin += t_trans.basis.y * height_offset
				area.transform = t_trans
				area_col.shape = box
				area.add_child(area_col)
				_container.add_child(area)
				
		elif element_type == ElementType.BOOST_RAMP:
			var b_script = load("res://scripts/components/track/boost_pad_component.gd")
			if b_script:
				area = b_script.new()
				area.boost_duration = boost_duration
				area.boost_power = boost_power
				
				var area_col = CollisionShape3D.new()
				var box = BoxShape3D.new()
				
				var center_t = track_offset + (actual_length * boost_pad_position_ratio)
				var current_w = boost_pad_size.x
				if match_track_width and parent_track.has_method("get_track_width_at_offset"):
					current_w = parent_track.get_track_width_at_offset(center_t) * width_ratio * 0.8
					
				box.size = Vector3(current_w, 3.0, boost_pad_size.y)
				
				var t_trans = curve.sample_baked_with_rotation(center_t)
				
				var ratio = boost_pad_position_ratio
				if ramp_curve: ratio = ramp_curve.sample_baked(boost_pad_position_ratio)
				var h = lerp(height_offset + 0.05, height_offset + ramp_height, ratio)
				
				# Execute position offset cleanly on the unmodified rotational axis
				t_trans.origin += t_trans.basis.x * lateral_offset
				t_trans.origin += t_trans.basis.y * (h + 0.15) 
				
				# Pitch the box upward so it matches the ramp incline loosely
				var pitch_angle = atan2(ramp_height, actual_length)
				t_trans.basis = t_trans.basis.rotated(t_trans.basis.x.normalized(), pitch_angle)
				
				area.transform = t_trans
				area_col.shape = box
				area.add_child(area_col)
				_container.add_child(area)
				
				# Create isolated visual overlay specifically for the boost pad 
				var visual_pad = MeshInstance3D.new()
				var p_mesh = BoxMesh.new()
				p_mesh.size = Vector3(current_w, 0.2, boost_pad_size.y)
				visual_pad.mesh = p_mesh
				
				var boost_mat = load("res://resources/materials/track_element_boost.tres")
				if boost_mat: visual_pad.material_override = boost_mat
				visual_pad.transform = t_trans
				_container.add_child(visual_pad)

	# --- SCENE BASED ELEMENTS ---
	elif element_type == ElementType.ITEM_BOX:
		var scene = load("res://scenes/track_elements/item_box.tscn")
		if scene:
			var inst = scene.instantiate()
			inst.set("item_pools", item_pools)
			_container.add_child(inst)

	elif element_type == ElementType.HAZARD:
		var scene = load("res://scenes/track_elements/hazard.tscn")
		if scene:
			var inst = scene.instantiate()
			inst.set("speed_penalty_factor", hazard_penalty)
			inst.set("duration", hazard_duration)
			var w = width
			if match_track_width and parent_track.has_method("get_track_width_at_offset"):
				w = parent_track.get_track_width_at_offset(track_offset) * width_ratio
			inst.scale = Vector3(w / 10.0, 1.0, length / 10.0) 
			_container.add_child(inst)

	elif element_type == ElementType.CANNON:
		var scene = load("res://scenes/track_elements/cannon.tscn")
		if scene:
			var inst = scene.instantiate()
			inst.set("flight_path", cannon_flight_path)
			inst.set("flight_speed", cannon_flight_speed)
			var w = width
			if match_track_width and parent_track.has_method("get_track_width_at_offset"):
				w = parent_track.get_track_width_at_offset(track_offset) * width_ratio
			inst.scale = Vector3(w / 10.0, 1.0, length / 10.0)
			_container.add_child(inst)

	elif element_type == ElementType.WIND_GUST:
		var scene = load("res://scenes/track_elements/wind_gust.tscn")
		if scene:
			var inst = scene.instantiate()
			inst.set("upward_force", wind_upward_force)
			inst.set("constant_lift", wind_constant_lift)
			inst.scale = Vector3(wind_radius / 12.0, wind_height / 60.0, wind_radius / 12.0)
			_container.add_child(inst)
