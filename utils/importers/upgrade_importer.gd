@tool
extends BaseImporter

func import_upgrades(data: Array) -> void:
	for u_data in data:
		var id = u_data["id"]
		var res_path = RESOURCE_BASE_PATH + "upgrades/" + id + ".tres"
		
		if not _should_process(id, res_path): continue
		
		var res = _get_or_create_resource(res_path, UPGRADE_SCRIPT)
		res.id = id
		res.upgrade_name = u_data.get("name", id)
		res.type = u_data.get("type", 1) # Default to STATS
		res.cost = u_data.get("cost", 100)
		res.modifiers = u_data.get("modifiers", {})
		
		if res.type == 2: # WHEELS
			res.wheel_radius = u_data.get("wheel_radius", 0.4)
			# You can optionally set res.wheel_mesh to a pre-built res:// mesh here
			
		ResourceSaver.save(res, res_path)
		print("Imported Upgrade: ", id)