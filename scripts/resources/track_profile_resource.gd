@tool
extends Resource
class_name TrackProfileResource

enum ProfileType { FLAT, WALLED, TUNNEL, CUSTOM_ROOF, TUBE, HALF_PIPE }

@export var shape_type: ProfileType = ProfileType.WALLED:
	set(v):
		shape_type = v
		emit_changed()

@export_group("Road Surface")
@export var road_width: float = 40.0:
	set(v):
		road_width = v
		emit_changed()

@export var road_crown: float = 0.0: ## Height offset at the very center of the road.
	set(v):
		road_crown = v
		emit_changed()

@export_group("Walls")
@export var wall_height: float = 8.0:
	set(v):
		wall_height = v
		emit_changed()

@export var wall_thickness: float = 2.0:
	set(v):
		wall_thickness = v
		emit_changed()
		
@export var wall_angle: float = 0.0: ## Degrees to tilt walls outward
	set(v):
		wall_angle = v
		emit_changed()

@export var track_depth: float = 4.0:
	set(v):
		track_depth = v
		emit_changed()

@export_group("Merge Openings")
@export var is_left_wall_open: bool = false: ## Flattens the left wall to allow track merging
	set(v):
		is_left_wall_open = v
		emit_changed()
		
@export var is_right_wall_open: bool = false: ## Flattens the right wall to allow track merging
	set(v):
		is_right_wall_open = v
		emit_changed()

@export_group("Custom Roof Shape")
@export var roof_height: float = 12.0:
	set(v):
		roof_height = v
		emit_changed()
		
@export var roof_peak_offset: float = 0.0:
	set(v):
		roof_peak_offset = v
		emit_changed()

## Returns a 2D cross-section of the track profile. 
## Points are defined in a continuous loop to allow seamless triangulation.
func get_profile_points(custom_width: float = -1.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	
	# Force cast all values to float to prevent "Nonexistent Vector2 constructor" 
	# errors if properties were loaded as null or integers from older resources.
	var w: float = (float(road_width) if custom_width < 0.0 else custom_width) / 2.0
	var wh: float = float(wall_height)
	var wt: float = float(wall_thickness)
	var td: float = float(track_depth)
	var wa_x: float = wh * tan(deg_to_rad(float(wall_angle)))
	var wa_x_out: float = (wh + wt) * tan(deg_to_rad(float(wall_angle)))
	var rc: float = float(road_crown)
	
	# Use PackedVector2Array directly to prevent Array -> PackedVector2Array conversion errors
	var road_points := PackedVector2Array()
	road_points.append(Vector2(-w, 0.0))
	if rc != 0.0:
		road_points.append(Vector2(0.0, rc))
	road_points.append(Vector2(w, 0.0))
	
	if shape_type == ProfileType.FLAT:
		pts.append_array(road_points)
		if td > 0:
			pts.append(Vector2(w, -td))
			pts.append(Vector2(-w, -td))
			
	elif shape_type == ProfileType.WALLED:
		if not is_left_wall_open:
			pts.append(Vector2(-w - wt - wa_x_out, wh))
			pts.append(Vector2(-w - wa_x, wh))
		else:
			pts.append(Vector2(-w - wt, 0.0))
			
		pts.append_array(road_points)
		
		if not is_right_wall_open:
			pts.append(Vector2(w + wa_x, wh))
			pts.append(Vector2(w + wt + wa_x_out, wh))
		else:
			pts.append(Vector2(w + wt, 0.0))
			
		if td > 0:
			pts.append(Vector2(w + wt, -td))
			pts.append(Vector2(-w - wt, -td))
			
	elif shape_type == ProfileType.TUNNEL:
		if is_left_wall_open and is_right_wall_open:
			pts.append_array(road_points)
			if td > 0:
				pts.append(Vector2(w, -td))
				pts.append(Vector2(-w, -td))
		elif is_left_wall_open and not is_right_wall_open:
			pts.append_array(road_points)
			pts.append(Vector2(w + wa_x, wh)) 
			pts.append(Vector2(-w - wt - wa_x, wh)) 
			pts.append(Vector2(-w - wt - wa_x_out, wh + wt)) 
			pts.append(Vector2(w + wt + wa_x_out, wh + wt)) 
			pts.append(Vector2(w + wt, -td)) 
			pts.append(Vector2(-w - wt, -td)) 
			pts.append(Vector2(-w - wt, 0.0)) 
		elif is_right_wall_open and not is_left_wall_open:
			pts.append_array(road_points)
			pts.append(Vector2(w + wt, 0.0)) 
			pts.append(Vector2(w + wt, -td)) 
			pts.append(Vector2(-w - wt, -td)) 
			pts.append(Vector2(-w - wt - wa_x_out, wh + wt)) 
			pts.append(Vector2(w + wt + wa_x_out, wh + wt)) 
			pts.append(Vector2(w + wt + wa_x, wh)) 
			pts.append(Vector2(-w - wa_x, wh)) 
			pts.append(Vector2(-w, 0.0)) 
		else:
			pts.append_array(road_points)
			pts.append(Vector2(w + wa_x, wh))
			pts.append(Vector2(-w - wa_x, wh))
			pts.append(Vector2(-w, 0.0)) 
			pts.append(Vector2(-w - wt, 0.0)) 
			pts.append(Vector2(-w - wt - wa_x_out, wh + wt)) 
			pts.append(Vector2(w + wt + wa_x_out, wh + wt)) 
			pts.append(Vector2(w + wt, -td)) 
			pts.append(Vector2(-w - wt, -td)) 
			pts.append(Vector2(-w - wt, 0.0)) 

	elif shape_type == ProfileType.CUSTOM_ROOF:
		pts.append_array(road_points)
		if not is_right_wall_open:
			pts.append(Vector2(w + wa_x, wh))
			
		pts.append(Vector2(float(roof_peak_offset), wh + float(roof_height)))
		
		if not is_left_wall_open:
			pts.append(Vector2(-w - wa_x, wh))
			
		if not is_left_wall_open:
			pts.append(Vector2(-w - wt - wa_x_out, wh))
		else:
			pts.append(Vector2(-w - wt, 0.0))
			
		pts.append(Vector2(float(roof_peak_offset), wh + float(roof_height) + wt))
		
		if not is_right_wall_open:
			pts.append(Vector2(w + wt + wa_x_out, wh))
			
		if td > 0:
			pts.append(Vector2(w + wt, -td))
			pts.append(Vector2(-w - wt, -td))

	elif shape_type == ProfileType.TUBE:
		var radius: float = w
		var circle_pts: int = 16
		for i in range(circle_pts + 1):
			var angle: float = -PI/2.0 + (float(i) * PI * 2.0 / float(circle_pts))
			pts.append(Vector2(cos(angle) * radius, sin(angle) * radius + radius))
		pts.append(Vector2(cos(PI*1.5) * (radius + wt), sin(PI*1.5) * (radius + wt) + radius))
		for i in range(circle_pts + 1):
			var angle: float = PI*1.5 - (float(i) * PI * 2.0 / float(circle_pts))
			pts.append(Vector2(cos(angle) * (radius + wt), sin(angle) * (radius + wt) + radius))
			
	elif shape_type == ProfileType.HALF_PIPE:
		var radius: float = w
		var circle_pts: int = 16
		for i in range((circle_pts/2) + 1):
			var angle: float = PI + (float(i) * PI / float(circle_pts/2))
			pts.append(Vector2(cos(angle) * radius, sin(angle) * radius + radius))
		for i in range((circle_pts/2) + 1):
			var angle: float = (2.0*PI) - (float(i) * PI / float(circle_pts/2))
			pts.append(Vector2(cos(angle) * (radius + wt), sin(angle) * (radius + wt) + radius))

	return pts
