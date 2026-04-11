class_name WheelsComponent
extends Node3D

@export var wheel_base_width: float = 1.0
@export var wheel_base_length: float = 1.0
@export var front_wheel_scale: float = 0.5 ## Adjusts the size of the front two wheels

var wheel_containers: Array[Node3D] = []
var wheel_spinners: Array[Node3D] = []

var initial_mesh_basis: Basis = Basis.IDENTITY

@onready var input: KartInputComponent = $"../KartInputComponent"
@onready var physics: KartPhysicsComponent = $"../KartPhysicsComponent"
@onready var visual_model: Node3D = $"../VisualModel"

func _ready() -> void:
	if get_child_count() > 0:
		var template = get_child(0) as Node3D
		if template:
			# Capture the Godot-editor configured rotation (e.g. 90 deg fixes)
			initial_mesh_basis = template.transform.basis
			template.hide()
			_generate_wheels(template)

func _generate_wheels(source: Variant) -> void:
	# Clear old structure
	for c in wheel_containers: c.queue_free()
	wheel_containers.clear()
	wheel_spinners.clear()
	
	var positions = [
		Vector3(wheel_base_width, 0, -wheel_base_length - 1.25),  # Front Left
		Vector3(-wheel_base_width, 0, -wheel_base_length - 1.25), # Front Right
		Vector3(wheel_base_width, 0, wheel_base_length),   # Back Left
		Vector3(-wheel_base_width, 0, wheel_base_length)   # Back Right
	]
	
	for i in range(positions.size()):
		var pos = positions[i]
		
		# Container handles Steering (Y Rotation)
		var container = Node3D.new()
		container.position = pos
		
		# Spinner handles Forward Rolling (Local X Rotation)
		var spinner = Node3D.new()
		var w_inst: Node3D
		
		# Handle spawning from an instanced GLB/TSCN scene (Default)
		if source is Node3D:
			w_inst = source.duplicate()
			w_inst.show()
			w_inst.position = Vector3.ZERO
			w_inst.transform.basis = initial_mesh_basis
			
			# Flip right-side wheels so the rims face outward
			if i % 2 != 0:
				w_inst.transform.basis = w_inst.transform.basis.rotated(Vector3.UP, PI)
				
		# Handle spawning from an upgrade resource (Shop)
		elif source is Mesh:
			var mesh_inst = MeshInstance3D.new()
			mesh_inst.mesh = source
			mesh_inst.transform.basis = initial_mesh_basis
			
			if i % 2 != 0:
				mesh_inst.transform.basis = mesh_inst.transform.basis.rotated(Vector3.UP, PI)
				
			w_inst = mesh_inst
			
		if w_inst:
			# Apply scale reduction to front wheels
			if i < 2:
				w_inst.scale = Vector3.ONE * front_wheel_scale
			else:
				w_inst.scale = Vector3.ONE
				
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
		if physics and "base_visual_y" in physics:
			physics.base_visual_y = visual_model.position.y

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
