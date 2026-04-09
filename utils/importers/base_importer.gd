@tool
class_name BaseImporter
extends RefCounted

const RESOURCE_BASE_PATH = "res://resources/"
const SCENE_TRACKS_PATH = "res://scenes/tracks/"

var target_item_id: String = "All"
var overwrite_existing: bool = false
var only_update_resources: bool = false

func _init(p_target_id: String = "All", p_overwrite: bool = false, p_only_update_resources: bool = false) -> void:
	target_item_id = p_target_id
	overwrite_existing = p_overwrite
	only_update_resources = p_only_update_resources

func _get_or_create_resource(path: String, script_path: String) -> Resource:
	if ResourceLoader.exists(path): return load(path)
	var script = load(script_path)
	return script.new() if script else null

func _should_process(id: String, file_path: String) -> bool:
	if target_item_id != "All" and id != target_item_id: return false
	if not ResourceLoader.exists(file_path): return true
	return overwrite_existing

func _save_scene(root_node: Node, path: String) -> void:
	_set_owner_recursive(root_node, root_node)
	var packed = PackedScene.new()
	packed.pack(root_node)
	ResourceSaver.save(packed, path)
	root_node.queue_free()

func _set_owner_recursive(node: Node, root: Node) -> void:
	if node != root: node.owner = root
	for c in node.get_children(): _set_owner_recursive(c, root)

func parse_components(node: Node3D, component_data: Array) -> void:
	for c_data in component_data:
		var type = c_data.get("type", "")
		var pos_arr = c_data.get("pos", [0,0,0])
		var pos = Vector3(pos_arr[0], pos_arr[1], pos_arr[2])
		
		if type == "Start":
			var start = Node3D.new()
			start.set_script(load("res://scripts/components/track/start_position_component.gd"))
			start.position = pos
			start.name = "TrackStartPosition"
			node.add_child(start)
			
		elif type == "ItemBox":
			var ib = Area3D.new()
			ib.set_script(load("res://scripts/entities/item_box.gd"))
			ib.position = pos
			ib.name = "ItemBox"
			node.add_child(ib)
