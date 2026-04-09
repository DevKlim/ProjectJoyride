@tool
class_name BaseImporter
extends RefCounted

const RESOURCE_BASE_PATH = "res://resources/"
const SCENE_TRACKS_PATH = "res://scenes/tracks/"

const CHARACTER_SCRIPT = "res://scripts/resources/character_resource.gd"
const TRACK_SCRIPT = "res://scripts/resources/track_resource.gd"
const UPGRADE_SCRIPT = "res://scripts/resources/upgrade_resource.gd"

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
