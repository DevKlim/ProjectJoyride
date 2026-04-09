class_name WheelsComponent
extends Node3D

@export var wheel_base_width: float = 1.0
@export var wheel_base_length: float = 1.4

var wheel_containers: Array[Node3D] = []
var wheel_spinners: Array[Node3D] = []

@onready var input: KartInputComponent = $"../KartInputComponent"
@onready var physics: KartPhysicsComponent = $"../KartPhysicsComponent"
@onready var visual_model: Node3D = $"../VisualModel"

func _ready() -> void:
	var template = get_child(0) as MeshInstance3D
	if template:
		template.hide()
		_generate_wheels(template.mesh)

func _generate_wheels(mesh: Mesh) -> void:
	# Clear old structure
	for c in wheel_containers: c.queue_free()
	wheel_containers.clear()
	wheel_spinners.clear()
	
	var positions = [
		Vector3(wheel_base_width, 0, -wheel_base_length),  # Front Left
		Vector3(-wheel_base_width, 0, -wheel_base_length), # Front Right
		Vector3(wheel_base_width, 0, wheel_base_length),   # Back Left
		Vector3(-wheel_base_width, 0, wheel_base_length)   # Back Right
	]
	
	for pos in positions:
		# Container handles Steering (Y Rotation)
		var container = Node3D.new()
		container.position = pos
		
		# Spinner handles Forward Rolling (Local X Rotation)
		var spinner = Node3D.new()
		
		# The visual mesh retains its baseline orientation inside the spinner
		var w_inst = MeshInstance3D.new()
		w_inst.mesh = mesh
		w_inst.rotation_degrees = Vector3(0, 0, 90)
		
		spinner.add_child(w_inst)
		container.add_child(spinner)
		add_child(container)
		
		wheel_containers.append(container)
		wheel_spinners.append(spinner)

func apply_wheel_upgrade(new_mesh: Mesh, new_radius: float) -> void:
	if new_mesh:
		_generate_wheels(new_mesh)
		
	if visual_model:
		visual_model.position.y = (new_radius - 0.4) - 0.5

func _process(delta: float) -> void:
	if not physics or not input or wheel_containers.size() < 4: return
	
	var speed = physics.current_speed
	var spin_amount = speed * delta * -2.0 # Negative to spin forward
	
	var steer_angle = input.steer * 0.5
	var drift_dir = physics.drift_dir * 0.4 if physics.is_drifting else 0.0

	for i in wheel_containers.size():
		var container = wheel_containers[i]
		var spinner = wheel_spinners[i]
		
		# Front wheels turn with steering and drift
		if i < 2:
			container.rotation.y = steer_angle + drift_dir
		else:
			# Rear wheels just slightly angle on drift
			container.rotation.y = drift_dir * 0.5
			
		# Spin purely on the inner X axis
		spinner.rotate_object_local(Vector3.RIGHT, spin_amount)