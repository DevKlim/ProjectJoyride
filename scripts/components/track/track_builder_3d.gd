@tool
class_name TrackBuilder3D
extends Path3D

signal track_rebuilt

@export_category("Track Design")
@export var profile: TrackProfileResource: ## Master track profile. Tweaking this resource updates the mesh in real-time.
	set(v):
		if profile and profile.changed.is_connected(_queue_rebuild):
			profile.changed.disconnect(_queue_rebuild)
		profile = v
		if profile:
			profile.changed.connect(_queue_rebuild)
		_queue_rebuild()

@export var resolution: float = 2.0: ## Length of each track segment. Lower = smoother turns but more polygons.
	set(v): resolution = max(0.5, v); _queue_rebuild()

@export var uv_scale: Vector2 = Vector2(1, 1): ## Adjusts texture tiling.
	set(v): uv_scale = v; _queue_rebuild()

@export var road_material: Material:
	set(v): road_material = v; _queue_rebuild()

@export var wall_material: Material:
	set(v): wall_material = v; _queue_rebuild()

@export_category("Global Tunnel Lighting")
@export var generate_lights: bool = false
@export var light_color: Color = Color(1.0, 0.9, 0.7)
@export var light_energy: float = 2.0
@export var light_spacing: float = 30.0
@export var light_height: float = 6.0

@export_category("Multi-Road Segments")
@export var multi_road: bool = false: ## Enables per-segment tracking using the Segments array.
	set(v): multi_road = v; _queue_rebuild()

@export var update_segments_array: bool = false: ## Click this to automatically resize the segments array to match the path length!
	set(v):
		if v: _sync_segments_array()
		update_segments_array = false

@export var segments: Array[TrackSegmentResource] = []: ## Applies specific Profile/Material per segment
	set(v): 
		segments = v
		for s in segments:
			if s and not s.changed.is_connected(_queue_rebuild):
				s.changed.connect(_queue_rebuild)
		_queue_rebuild()

@export_category("Face Visibility")
@export var path_closed: bool = false: ## Connects the end of the curve back to the start.
	set(v): path_closed = v; _queue_rebuild()

@export var generate_front_face: bool = false:
	set(v): generate_front_face = v; _queue_rebuild()

@export var generate_back_face: bool = false:
	set(v): generate_back_face = v; _queue_rebuild()

@export_category("Physics & Connectivity")
@export var generate_collision: bool = true:
	set(v): generate_collision = v; _queue_rebuild()
	
@export var is_wall_ride: bool = false:
	set(v): is_wall_ride = v; _queue_rebuild()
	
@export var is_anti_gravity: bool = false:
	set(v): is_anti_gravity = v; _queue_rebuild()

@export_category("Branching & Modding Tools")
@export var branch_from_point: int = -1: ## Type a point index here to automatically generate a branched TrackBuilder sub-node at that point!
	set(v):
		if v >= 0: call_deferred("_create_branch", v)
		branch_from_point = -1

var _is_dirty: bool = false

func _ready() -> void:
	add_to_group("track_path")
	
	if not curve_changed.is_connected(_queue_rebuild):
		curve_changed.connect(_queue_rebuild)
	
	if profile and not profile.changed.is_connected(_queue_rebuild):
		profile.changed.connect(_queue_rebuild)
		
	_queue_rebuild()

func get_track_width_at_offset(offset: float) -> float:
	if not curve or curve.get_point_count() < 2:
		return profile.road_width if profile else 40.0
		
	var track_len = curve.get_baked_length()
	if offset > track_len: offset = track_len
	
	var point_count = curve.get_point_count()
	var segment_count = point_count - 1
	if path_closed: segment_count += 1
	
	for seg in range(segment_count):
		var start_offset = 0.0
		var end_offset = 0.0

		if seg < point_count - 1:
			start_offset = curve.get_closest_offset(curve.get_point_position(seg))
			end_offset = curve.get_closest_offset(curve.get_point_position(seg + 1))
		else:
			start_offset = curve.get_closest_offset(curve.get_point_position(seg))
			end_offset = track_len
			
		if end_offset <= start_offset: end_offset = start_offset + 0.1
		
		if offset >= start_offset and offset <= end_offset:
			var base_width = profile.road_width if profile else 40.0
			if multi_road and seg < segments.size() and segments[seg] != null:
				var s = segments[seg]
				if s.override_profile:
					base_width = s.override_profile.road_width
				if s.override_width:
					var progress = (offset - start_offset) / (end_offset - start_offset)
					return lerp(s.start_width, s.end_width, progress)
			return base_width
			
	return profile.road_width if profile else 40.0

func _sync_segments_array() -> void:
	if not curve: return
	var point_count = curve.get_point_count()
	var target_count = max(0, point_count - 1)
	if path_closed and point_count > 1:
		target_count += 1
		
	if segments.size() == target_count:
		print("Segments array is already up to date! (Count: ", target_count, ")")
		return
		
	var new_segments: Array[TrackSegmentResource] = []
	for i in range(target_count):
		if i < segments.size():
			new_segments.append(segments[i])
		else:
			new_segments.append(TrackSegmentResource.new())
			
	segments = new_segments
	print("Segments array updated to size: ", target_count)
	_queue_rebuild()

func _queue_rebuild() -> void:
	if not _is_dirty:
		_is_dirty = true
		call_deferred("_rebuild_meshes")

func _rebuild_meshes() -> void:
	_is_dirty = false
	
	for child in get_children():
		if child.name.begins_with("GeneratedTrackMesh") or child.name.begins_with("TrackLights"):
			child.name = "Deleted_" + child.name
			child.queue_free()
			
	if not curve or curve.get_point_count() < 2 or curve.get_baked_length() <= 0: return

	var lights_container = Node3D.new()
	lights_container.name = "TrackLights"
	add_child(lights_container)

	var base_v_coord = 0.0
	var point_count = curve.get_point_count()
	var segment_count = point_count - 1
	if path_closed: segment_count += 1

	for seg in range(segment_count):
		var start_offset = 0.0
		var end_offset = 0.0

		if seg < point_count - 1:
			start_offset = curve.get_closest_offset(curve.get_point_position(seg))
			end_offset = curve.get_closest_offset(curve.get_point_position(seg + 1))
		else:
			start_offset = curve.get_closest_offset(curve.get_point_position(seg))
			end_offset = curve.get_baked_length()

		if end_offset <= start_offset: end_offset = start_offset + 0.1

		var seg_length = end_offset - start_offset
		var steps = int(max(1, ceil(seg_length / resolution)))
		var actual_res = seg_length / steps

		var active_profile = profile
		var active_mat = road_material
		var active_wall_mat = wall_material
		var gen_front = false
		var gen_back = false
		
		var has_width_override = false
		var s_start_width = 40.0
		var s_end_width = 40.0
		
		var do_lights = generate_lights
		var l_col = light_color
		var l_en = light_energy
		var l_spc = light_spacing
		var l_hgt = light_height

		if multi_road and seg < segments.size() and segments[seg] != null:
			var s = segments[seg]
			if s.override_profile: active_profile = s.override_profile
			if s.override_material: active_mat = s.override_material
			if s.override_wall_material: active_wall_mat = s.override_wall_material
			gen_front = s.generate_front_face
			gen_back = s.generate_back_face
			
			if s.override_width:
				has_width_override = true
				s_start_width = s.start_width
				s_end_width = s.end_width
			
			if s.generate_lights:
				do_lights = true
				l_col = s.light_color
				l_en = s.light_energy
				l_spc = s.light_spacing
				l_hgt = s.light_height
		else:
			gen_front = generate_front_face if seg == 0 else false
			gen_back = generate_back_face if seg == segment_count - 1 else false

		if not active_profile:
			active_profile = TrackProfileResource.new()

		if do_lights and active_profile.shape_type == TrackProfileResource.ProfileType.TUNNEL:
			var dist = l_spc * 0.5
			while dist < seg_length:
				var c_offset = start_offset + dist
				var t = curve.sample_baked_with_rotation(c_offset)
				
				var light = OmniLight3D.new()
				light.name = "TunnelLight_" + str(seg) + "_" + str(int(dist))
				light.light_color = l_col
				light.light_energy = l_en
				light.shadow_enabled = true
				light.omni_range = l_spc * 1.5
				
				var local_pos = Vector3(0, active_profile.wall_height - 1.0, 0)
				light.position = t * local_pos
				lights_container.add_child(light)
				
				dist += l_spc

		var base_profile_width = s_start_width if has_width_override else active_profile.road_width
		var profile_lines = active_profile.get_profile_points(base_profile_width)
		if profile_lines.size() < 3: continue

		var sweep_lines = profile_lines.duplicate()
		sweep_lines.append(profile_lines[0])
		var cols = sweep_lines.size()

		var st_road = SurfaceTool.new()
		st_road.begin(Mesh.PRIMITIVE_TRIANGLES)
		if active_mat: st_road.set_material(active_mat)

		var st_wall = SurfaceTool.new()
		st_wall.begin(Mesh.PRIMITIVE_TRIANGLES)
		if active_wall_mat: st_wall.set_material(active_wall_mat)
		elif active_mat: st_wall.set_material(active_mat)

		var u_coords = [0.0]
		var current_u = 0.0
		for i in range(1, cols):
			current_u += sweep_lines[i].distance_to(sweep_lines[i-1])
			u_coords.append(current_u)

		var idx_road = 0
		var idx_wall = 0

		for c in range(cols - 1):
			var c_next = c + 1
			var p1_base = sweep_lines[c]
			var p2_base = sweep_lines[c_next]
			var dir = (p2_base - p1_base).normalized()
			
			# Extract 2D Normal to dynamically determine if this segment is ROAD or WALL
			var n2d = Vector2(-dir.y, dir.x)
			var is_road = n2d.y > 0.5 
			
			var target_st = st_road if is_road else st_wall
			
			for r in range(steps):
				var r0_offset = start_offset + (r * actual_res)
				var r1_offset = start_offset + ((r + 1) * actual_res)
				if r == steps - 1: r1_offset = end_offset
				
				var t0 = curve.sample_baked_with_rotation(r0_offset)
				var t1 = curve.sample_baked_with_rotation(r1_offset)
				
				if path_closed and r == steps - 1 and seg == segment_count - 1:
					t1 = curve.sample_baked_with_rotation(0.0)
					
				var w0 = base_profile_width
				var w1 = base_profile_width
				if has_width_override:
					w0 = lerp(s_start_width, s_end_width, float(r) / steps)
					w1 = lerp(s_start_width, s_end_width, float(r + 1) / steps)
					
				var pl0 = active_profile.get_profile_points(w0)
				var pl1 = active_profile.get_profile_points(w1)
				
				var p0_c = pl0[c]
				var p0_n = pl0[c_next] if c_next < pl0.size() else pl0[0]
				var p1_c = pl1[c]
				var p1_n = pl1[c_next] if c_next < pl1.size() else pl1[0]
				
				var v0 = t0 * Vector3(p0_c.x, p0_c.y, 0)
				var v1 = t0 * Vector3(p0_n.x, p0_n.y, 0)
				var v2 = t1 * Vector3(p1_c.x, p1_c.y, 0)
				var v3 = t1 * Vector3(p1_n.x, p1_n.y, 0)
				
				var u0 = u_coords[c] * uv_scale.x
				var u1 = u_coords[c_next] * uv_scale.x
				var v_uv0 = (base_v_coord + (r * actual_res)) * uv_scale.y
				var v_uv1 = (base_v_coord + ((r + 1) * actual_res)) * uv_scale.y
				
				var current_idx = idx_road if is_road else idx_wall
				
				target_st.set_uv(Vector2(u0, v_uv0)); target_st.add_vertex(v0)
				target_st.set_uv(Vector2(u1, v_uv0)); target_st.add_vertex(v1)
				target_st.set_uv(Vector2(u0, v_uv1)); target_st.add_vertex(v2)
				target_st.set_uv(Vector2(u1, v_uv1)); target_st.add_vertex(v3)
				
				target_st.add_index(current_idx + 0)
				target_st.add_index(current_idx + 2)
				target_st.add_index(current_idx + 1)
				
				target_st.add_index(current_idx + 1)
				target_st.add_index(current_idx + 2)
				target_st.add_index(current_idx + 3)
				
				if is_road: idx_road += 4
				else: idx_wall += 4

		base_v_coord += seg_length

		# Face Caps automatically pushed to the wall geometry handler
		if gen_front:
			var indices = Geometry2D.triangulate_polygon(profile_lines)
			if indices.size() > 0:
				var w0 = s_start_width if has_width_override else base_profile_width
				var pl0 = active_profile.get_profile_points(w0)
				var t0 = curve.sample_baked_with_rotation(start_offset)
				
				var cap_start = idx_wall
				for i in range(pl0.size()):
					st_wall.set_uv(Vector2(pl0[i].x, pl0[i].y) * uv_scale)
					st_wall.add_vertex(t0 * Vector3(pl0[i].x, pl0[i].y, 0))
				for i in range(0, indices.size(), 3):
					st_wall.add_index(cap_start + indices[i+2])
					st_wall.add_index(cap_start + indices[i+1])
					st_wall.add_index(cap_start + indices[i])
                
				idx_wall += pl0.size()

		if gen_back:
			var indices = Geometry2D.triangulate_polygon(profile_lines)
			if indices.size() > 0:
				var w1 = s_end_width if has_width_override else base_profile_width
				var pl1 = active_profile.get_profile_points(w1)
				var t1 = curve.sample_baked_with_rotation(end_offset)
				
				var cap_start = idx_wall
				for i in range(pl1.size()):
					st_wall.set_uv(Vector2(pl1[i].x, pl1[i].y) * uv_scale)
					st_wall.add_vertex(t1 * Vector3(pl1[i].x, pl1[i].y, 0))
				for i in range(0, indices.size(), 3):
					st_wall.add_index(cap_start + indices[i])
					st_wall.add_index(cap_start + indices[i+1])
					st_wall.add_index(cap_start + indices[i+2])
					
				idx_wall += pl1.size()

		var seg_mesh = ArrayMesh.new()

		if idx_road > 0:
			st_road.generate_normals()
			st_road.generate_tangents()
			st_road.commit(seg_mesh)

		if idx_wall > 0:
			st_wall.generate_normals()
			st_wall.generate_tangents()
			st_wall.commit(seg_mesh)

		var mesh_inst = MeshInstance3D.new()
		mesh_inst.name = "GeneratedTrackMesh_Seg_" + str(seg)
		mesh_inst.mesh = seg_mesh
		add_child(mesh_inst)

		if generate_collision:
			var static_body = StaticBody3D.new()
			static_body.name = "TrackCollision_Seg_" + str(seg)
			static_body.add_to_group("road")
			
			var seg_wall = is_wall_ride
			var seg_ag = is_anti_gravity
			
			if multi_road and seg < segments.size() and segments[seg] != null:
				if segments[seg].is_wall_ride: seg_wall = true
				if segments[seg].is_anti_gravity: seg_ag = true
				
			if seg_wall: static_body.add_to_group("wall_ride")
			if seg_ag: static_body.add_to_group("anti_gravity")
				
			var coll = CollisionShape3D.new()
			coll.shape = seg_mesh.create_trimesh_shape()
			static_body.add_child(coll)
			mesh_inst.add_child(static_body)
			
	track_rebuilt.emit()

func _create_branch(point_idx: int) -> void:
	if not curve or point_idx < 0 or point_idx >= curve.get_point_count(): return

	var script_ref = load("res://scripts/components/track/track_builder_3d.gd")
	var new_node = Path3D.new()
	new_node.set_script(script_ref)
	new_node.name = self.name + "_Branch_" + str(point_idx)

	add_child(new_node)
	if Engine.is_editor_hint() and self.owner:
		new_node.owner = self.owner

	new_node.profile = self.profile.duplicate() if self.profile else null
	new_node.road_material = self.road_material
	new_node.wall_material = self.wall_material

	var c = Curve3D.new()
	var p_pos = curve.get_point_position(point_idx)
	var p_out = curve.get_point_out(point_idx)
	var forward = p_out.normalized()

	if forward.length_squared() < 0.01:
		if point_idx < curve.get_point_count() - 1:
			forward = (curve.get_point_position(point_idx + 1) - p_pos).normalized()
		else:
			forward = Vector3.FORWARD

	c.add_point(p_pos, -forward * 5.0, forward * 5.0)
	c.add_point(p_pos + forward * 30.0, -forward * 5.0, forward * 5.0)
	
	new_node.curve = c
	new_node.generate_front_face = false 
	print("Auto-branched generated at point index: ", point_idx)

