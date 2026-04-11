class_name KartVFXComponent
extends Node3D

var drift_sparks: GPUParticles3D
var boost_flame: GPUParticles3D

var driving_dust: GPUParticles3D
var landing_dust: GPUParticles3D

@onready var physics: KartPhysicsComponent = $"../KartPhysicsComponent"
@onready var input: KartInputComponent = $"../KartInputComponent"

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

	# --- Dust Systems ---
	var dust_mat = StandardMaterial3D.new()
	dust_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dust_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	dust_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_mat.vertex_color_use_as_albedo = true
	
	var dust_mesh = QuadMesh.new()
	dust_mesh.size = Vector2(1.0, 1.0)
	dust_mesh.material = dust_mat
	
	var dust_grad = Gradient.new()
	dust_grad.add_point(0.0, Color(0.8, 0.8, 0.8, 0.6))
	dust_grad.add_point(1.0, Color(0.8, 0.8, 0.8, 0.0))
	var dust_grad_tex = GradientTexture1D.new()
	dust_grad_tex.gradient = dust_grad
	
	# Driving Dust
	driving_dust = GPUParticles3D.new()
	driving_dust.draw_pass_1 = dust_mesh
	driving_dust.emitting = false
	driving_dust.amount = 32
	driving_dust.lifetime = 0.5
	var d_proc = ParticleProcessMaterial.new()
	d_proc.gravity = Vector3(0, 1, 0)
	d_proc.direction = Vector3(0, 0, 1)
	d_proc.initial_velocity_min = 2.0
	d_proc.initial_velocity_max = 4.0
	d_proc.scale_min = 0.5
	d_proc.scale_max = 1.2
	d_proc.color_ramp = dust_grad_tex
	driving_dust.process_material = d_proc
	add_child(driving_dust)
	driving_dust.position = Vector3(0, -0.4, 0.5)
	
	# Landing Dust
	landing_dust = GPUParticles3D.new()
	landing_dust.draw_pass_1 = dust_mesh
	landing_dust.emitting = false
	landing_dust.amount = 24
	landing_dust.lifetime = 0.4
	landing_dust.one_shot = true
	landing_dust.explosiveness = 0.9
	var l_proc = ParticleProcessMaterial.new()
	l_proc.gravity = Vector3(0, 1, 0)
	l_proc.direction = Vector3(0, 0.2, 0)
	l_proc.spread = 180.0
	l_proc.initial_velocity_min = 5.0
	l_proc.initial_velocity_max = 8.0
	l_proc.scale_min = 1.0
	l_proc.scale_max = 2.0
	l_proc.color_ramp = dust_grad_tex
	landing_dust.process_material = l_proc
	add_child(landing_dust)
	landing_dust.position = Vector3(0, -0.4, 0)

func play_landing_vfx() -> void:
	if landing_dust:
		landing_dust.restart()
		landing_dust.emitting = true

func _process(_delta: float) -> void:
	if not physics: return
	
	# Evaluate drifting sparks based on the updated physics progression tiers
	if physics.is_drifting and physics.drift_time >= 1.0:
		drift_sparks.emitting = true
		var spark_color = Color(0, 0.5, 1) # Blue (Lv1)
		
		if physics.drift_time >= 4.5:
			spark_color = Color(0.8, 0, 1) # Purple (Lv3)
		elif physics.drift_time >= 2.5:
			spark_color = Color(1, 0.5, 0) # Orange (Lv2)
			
		(drift_sparks.process_material as ParticleProcessMaterial).color = spark_color
	else:
		drift_sparks.emitting = false
		
	# Evaluate Boosts
	boost_flame.emitting = physics.boost_time > 0
	
	# Evaluate Driving Dust
	if input and driving_dust:
		if physics.is_grounded and abs(physics.current_speed) > 15.0 and input.accelerate > 0:
			driving_dust.emitting = true
		else:
			driving_dust.emitting = false

