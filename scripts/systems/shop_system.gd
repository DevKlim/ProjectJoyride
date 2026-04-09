class_name ShopSystem
extends Node

signal coins_changed(new_amount: int)
signal item_purchased(item_id: String)

@export var starting_coins: int = 0
var current_coins: int = 0
var unlocked_items: Array[String] = []

func _ready() -> void:
	current_coins = starting_coins

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
	