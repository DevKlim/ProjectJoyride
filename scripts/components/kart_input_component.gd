class_name KartInputComponent
extends Node

var steer: float = 0.0
var accelerate: float = 0.0
var brake: bool = false

var drift: bool = false
var drift_just_pressed: bool = false

var item_just_pressed: bool = false

func _process(_delta: float) -> void:
	steer = Input.get_axis("steer_right", "steer_left") 
	# Brake goes first as the negative axis, accelerate is positive
	accelerate = Input.get_axis("brake", "accelerate")
	brake = Input.is_action_pressed("brake")
	
	drift = Input.is_action_pressed("drift")
	drift_just_pressed = Input.is_action_just_pressed("drift")
	
	item_just_pressed = Input.is_action_just_pressed("item")

