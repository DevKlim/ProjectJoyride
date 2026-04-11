@tool
extends BaseImporter

func import_tracks(data: Array) -> void:
	for t_data in data:
		var id = t_data["id"]
		var res_path = RESOURCE_BASE_PATH + "tracks/" + id + ".tres"
		var scene_path = SCENE_TRACKS_PATH + id + ".tscn"
		
		if not _should_process(id, res_path): continue
		
		var res = _get_or_create_resource(res_path, "res://scripts/resources/track_resource.gd")
		res.id = id
		res.track_name = t_data.get("name", id)
		res.total_laps = t_data.get("laps", 3)
		ResourceSaver.save(res, res_path)
		
		if only_update_resources: continue
		if ResourceLoader.exists(scene_path) and not overwrite_existing: continue
		
		var root = Node3D.new()
		root.name = "Track_" + id.capitalize()
		_save_scene(root, scene_path)
		print("Imported Track: ", id)
