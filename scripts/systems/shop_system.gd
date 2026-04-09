class_name ShopSystem
extends Node

signal coins_changed(new_amount: int)
signal item_purchased(item_id: String)

@export var starting_coins: int = 0
var current_coins: int = 0
var unlocked_items: Array[String] = []
var available_upgrades: Array[UpgradeResource] = []

func _ready() -> void:
	current_coins = starting_coins
	_load_all_upgrades()

func _load_all_upgrades() -> void:
	var path = "res://resources/upgrades/"
	if DirAccess.dir_exists_absolute(path):
		var dir = DirAccess.open(path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".tres") or file_name.ends_with(".res"):
					var res = load(path + file_name) as UpgradeResource
					if res: available_upgrades.append(res)
				file_name = dir.get_next()

func add_coins(amount: int) -> void:
	current_coins += amount
	coins_changed.emit(current_coins)

func can_afford(cost: int) -> bool:
	return current_coins >= cost

func buy_item(item_id: String, cost: int) -> bool:
	if can_afford(cost) and not item_id in unlocked_items:
		current_coins -= cost
		unlocked_items.append(item_id)
		coins_changed.emit(current_coins)
		item_purchased.emit(item_id)
		return true
	return false

func get_random_upgrades(count: int) -> Array[UpgradeResource]:
	var temp = available_upgrades.duplicate()
	temp.shuffle()
	return temp.slice(0, min(count, temp.size()))