class_name KartVFXComponent
extends Node3D

var drift_sparks: GPUParticles3D
var boost_flame: GPUParticles3D

@onready var physics: KartPhysicsComponent = $"../KartPhysicsComponent"

func _ready() -> void:
	_create_particles()

func _create_particles() -> void:
	# Setup basic Quad mesh for particles (Y2K style N64 look)
	var mesh = QuadMesh.new()
	mesh.size = Vector2(0.5, 0.5)
	
	# Blocky, unshadded material for retro vibe
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.use_particle_trails = false
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = mat
	
	# Drift Sparks System
	drift_sparks = GPUParticles3D.new()
	drift_sparks.draw_pass_1 = mesh
	drift_sparks.emitting = false
	drift_sparks.amount = 16
	drift_sparks.lifetime = 0.3
	
	var proc_mat = ParticleProcessMaterial.new()
	proc_mat.gravity = Vector3(0, 2, 0)
	proc_mat.direction = Vector3(0, 1, -1)
	proc_mat.initial_velocity_min = 2.0
	proc_mat.initial_velocity_max = 5.0
	proc_mat.scale_min = 0.4
	proc_mat.scale_max = 0.8
	drift_sparks.process_material = proc_mat
	
	add_child(drift_sparks)
	drift_sparks.position = Vector3(0, -0.2, -1) # Positioned at rear base
	
	# Boost Flame System
	boost_flame = GPUParticles3D.new()
	boost_flame.draw_pass_1 = mesh
	boost_flame.emitting = false
	boost_flame.amount = 30
	boost_flame.lifetime = 0.2
	
	var boost_mat = ParticleProcessMaterial.new()
	boost_mat.gravity = Vector3(0, 0, 0)
	boost_mat.direction = Vector3(0, 0, 1)
	boost_mat.spread = 10.0
	boost_mat.initial_velocity_min = 5.0
	boost_mat.initial_velocity_max = 10.0
	
	var grad = Gradient.new()
	grad.add_point(0.0, Color(1, 1, 1, 1))
	grad.add_point(0.2, Color(1, 0.5, 0, 1))
	grad.add_point(1.0, Color(1, 0, 0, 0))
	var grad_tex = GradientTexture1D.new()
	grad_tex.gradient = grad
	boost_mat.color_ramp = grad_tex
	
	boost_flame.process_material = boost_mat
	add_child(boost_flame)
	boost_flame.position = Vector3(0, 0, 1.2) # Positioned behind tailpipe

func _process(_delta: float) -> void:
	if not physics: return
	
	# Evaluate MK8-style drifting sparks
	if physics.is_drifting and physics.drift_time > 1.5:
		drift_sparks.emitting = true
		var spark_color = Color(0, 0.5, 1) # Blue (Lv1)
		if physics.drift_time > 5.0:
			spark_color = Color(0.8, 0, 1) # Purple (Lv3)
		elif physics.drift_time > 3.0:
			spark_color = Color(1, 0.5, 0) # Orange (Lv2)
			
		(drift_sparks.process_material as ParticleProcessMaterial).color = spark_color
	else:
		drift_sparks.emitting = false
		
	# Evaluate Boosts
	boost_flame.emitting = physics.boost_time > 0

