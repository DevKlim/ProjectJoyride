class_name UpgradeSystem
extends Node

@export var target_stats: StatsComponent

func apply_upgrade(upgrade_data: Resource) -> void:
	if not target_stats: return
	if "modifiers" in upgrade_data:
		for stat in upgrade_data.modifiers.keys():
			var current = target_stats.get(stat)
			if current != null:
				target_stats.set(stat, current + upgrade_data.modifiers[stat])
				