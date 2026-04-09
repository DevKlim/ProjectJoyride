@tool
extends BaseImporter

func import_items(data: Array) -> void:
	for i_data in data:
		var id = i_data["id"]
		var res_path = RESOURCE_BASE_PATH + "items/" + id + ".tres"
		
		if not _should_process(id, res_path): continue
		
		var res = _get_or_create_resource(res_path, "res://scripts/resources/item_resource.gd")
		res.id = id
		res.item_name = i_data.get("name", id)
		res.type = i_data.get("type", "boost")
		res.attributes = i_data.get("attributes", {})
		
		var tex_path = i_data.get("icon_path", "")
		if ResourceLoader.exists(tex_path):
			res.icon = load(tex_path)
		else:
			# Fallback generated texture if asset is missing
			var grad_tex = GradientTexture2D.new()
			grad_tex.width = 64
			grad_tex.height = 64
			var grad = Gradient.new()
			# Randomish color based on id hash
			var hue = float(id.hash() % 1000) / 1000.0
			grad.add_point(0.0, Color.from_hsv(hue, 0.8, 0.9))
			grad.add_point(1.0, Color.from_hsv(hue, 0.9, 0.5))
			grad_tex.gradient = grad
			grad_tex.fill_to = Vector2(1, 1)
			res.icon = grad_tex
		
		ResourceSaver.save(res, res_path)
		print("Imported Item: ", id)

