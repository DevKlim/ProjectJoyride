@tool
extends Node

@export var import_data: bool = false:
	set(value):
		if value: _run_import()
		import_data = false

@export var clean_up_data: bool = false:
	set(value):
		if value: _run_cleanup()
		clean_up_data = false

@export_enum("All", "Characters", "Tracks", "Upgrades", "Items") var target_category: String = "All":
	set(value):
		if target_category != value:
			target_category = value
			target_item_id = "All"
			notify_property_list_changed()

var target_item_id: String = "All"
@export var overwrite_existing: bool = false
@export var only_update_resources: bool = false

const IMPORTER_BASE = "res://utils/importers/"
const CONTENT_DIR = "res://data/content/"
const RESOURCE_BASE_PATH = "res://resources/"

func _get_property_list() -> Array:
	var properties = []
	var options = ["All"]
	
	if target_category != "All":
		var key = target_category.to_lower()
		_collect_ids(_load_json_safe(key), options)

	properties.append({
		"name": "target_item_id",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ",".join(options)
	})
	return properties

func _collect_ids(data, out_array: Array) -> void:
	if typeof(data) == TYPE_ARRAY:
		for entry in data:
			if entry is Dictionary and entry.has("id"):
				out_array.append(str(entry["id"]))

func _load_json_safe(section: String):
	var path = CONTENT_DIR + section + ".json"
	if not FileAccess.file_exists(path): return null
	var file = FileAccess.open(path, FileAccess.READ)
	if not file: return null
	var json = JSON.new()
	if json.parse(file.get_as_text()) == OK: return json.data
	return null

func _get_importer(script_name: String):
	var script_path = IMPORTER_BASE + script_name
	if not ResourceLoader.exists(script_path):
		printerr("Importer missing: " + script_path)
		return null
		
	var script = load(script_path)
	if script is Script and script.can_instantiate():
		return script.new(target_item_id, overwrite_existing, only_update_resources)
	return null

func _run_import() -> void:
	print("--- Starting Racing Data Import [%s] ---" % target_category)
	_make_dirs()

	var run_imp = func(cat: String, script: String, method: String):
		if target_category == "All" or target_category == cat:
			var data = _load_json_safe(cat.to_lower())
			if data:
				var imp = _get_importer(script)
				if imp: imp.call(method, data)

	run_imp.call("Characters", "character_importer.gd", "import_characters")
	run_imp.call("Tracks", "track_importer.gd", "import_tracks")
	run_imp.call("Upgrades", "upgrade_importer.gd", "import_upgrades")
	run_imp.call("Items", "item_importer.gd", "import_items")
	
	print("--- Data Import Complete ---")
	if Engine.is_editor_hint():
		EditorInterface.get_resource_filesystem().scan()

func _make_dirs() -> void:
	var dirs = [
		CONTENT_DIR,
		RESOURCE_BASE_PATH + "characters/", RESOURCE_BASE_PATH + "tracks/", RESOURCE_BASE_PATH + "upgrades/", RESOURCE_BASE_PATH + "items/",
		"res://scenes/tracks/"
	]
	for d in dirs: DirAccess.make_dir_recursive_absolute(d)

func _run_cleanup() -> void:
	print("--- Starting Orphan Cleanup ---")
	if Engine.is_editor_hint(): EditorInterface.get_resource_filesystem().scan()

