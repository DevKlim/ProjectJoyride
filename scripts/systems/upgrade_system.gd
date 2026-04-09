class_name UpgradeSystem
extends Node

@export var target_kart: Node3D

func apply_upgrade(upgrade_data: UpgradeResource) -> void:
	if not target_kart: return
	
	var stats = target_kart.get_node_or_null("StatsComponent")
	var wheels = target_kart.get_node_or_null("WheelsComponent")
	
	# Apply standard modifiers
	if stats and "modifiers" in upgrade_data:
		for stat in upgrade_data.modifiers.keys():
			var current = stats.get(stat)
			if current != null:
				stats.set(stat, current + upgrade_data.modifiers[stat])
				
	# Apply specific component upgrades
	if upgrade_data.type == UpgradeResource.UpgradeType.WHEELS and wheels:
		wheels.apply_wheel_upgrade(upgrade_data.wheel_mesh, upgrade_data.wheel_radius)