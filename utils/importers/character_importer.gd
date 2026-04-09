@tool
extends BaseImporter

func import_characters(data: Array) -> void:
	for c_data in data:
		var id = c_data["id"]
		var res_path = RESOURCE_BASE_PATH + "characters/" + id + ".tres"
		
		if not _should_process(id, res_path): continue
		
		var res = _get_or_create_resource(res_path, CHARACTER_SCRIPT)
		res.id = id
		res.character_name = c_data.get("name", id)
		res.stats = c_data.get("stats", {})
		
		ResourceSaver.save(res, res_path)
		print("Imported Character: ", id)
		