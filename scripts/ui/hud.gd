extends Control

@onready var time_label = $TimeLabel
@onready var lap_label = $LapLabel
@onready var coin_label = $CoinLabel

func on_race_started() -> void:
	time_label.text = "Time: 0.00"
	lap_label.text = "Lap: 1/3"

func update_time(time: float) -> void:
	time_label.text = "Time: %.2f" % time

func update_lap(lap: int, _lap_time: float) -> void:
	lap_label.text = "Lap: %d/3" % lap

func update_coins(coins: int) -> void:
	coin_label.text = "Coins: %d" % coins
	