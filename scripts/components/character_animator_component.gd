class_name CharacterAnimatorComponent
extends Node

@export var anim_player: AnimationPlayer
@export var kart_physics: KartPhysicsComponent
@export var kart_input: KartInputComponent

@export var cartoony_fps: float = 12.0

var current_state: String = ""
var _time_accum: float = 0.0

func _ready() -> void:
	if anim_player:
		# Enforce manual process mode so we can step the animation at a low framerate
		if "playback_process_mode" in anim_player:
			anim_player.set("playback_process_mode", 2) # MANUAL (Godot 4.0 - 4.1)
		elif "callback_mode_process" in anim_player:
			anim_player.set("callback_mode_process", 2) # MANUAL (Godot 4.2+)

func _process(delta: float) -> void:
	if not anim_player or not kart_physics: return
	
	var frame_time = 1.0 / cartoony_fps
	_time_accum += delta
	
	# Only evaluate logic and advance the animation in strict steps
	while _time_accum >= frame_time:
		_update_animation_state()
		
		# The manual advance will process blends and positions in choppy intervals
		anim_player.advance(frame_time)
		_time_accum -= frame_time

func _update_animation_state() -> void:
	# Priority animations override standard driving logic
	if current_state in ["trick", "stun"] and anim_player.is_playing():
		return
		
	var next_anim = "idle"
	
	# Determine base state based on speed
	if kart_physics.current_speed < -1.0:
		next_anim = "Look_Back"
	elif abs(kart_physics.current_speed) > 1.0:
		
		# Base visual steering strictly on raw input for maximum snappiness
		var pressing_left = Input.is_action_pressed("steer_left")
		var pressing_right = Input.is_action_pressed("steer_right")
		
		if pressing_left and not pressing_right:
			next_anim = "Drive_Left"
		elif pressing_right and not pressing_left:
			next_anim = "Drive_Right"
		else:
			# Snaps cleanly back to center when no keys are pressed
			next_anim = "Drive_Idle"
	
	# Transition gracefully when state changes
	if current_state != next_anim:
		current_state = next_anim
		_play_anim_with_fallback(current_state)

func play_trick() -> void:
	if anim_player and anim_player.has_animation("Trick1"):
		anim_player.stop()
		anim_player.play("Trick1")
		current_state = "trick"

func play_stun() -> void:
	if anim_player and anim_player.has_animation("stun"):
		anim_player.stop()
		anim_player.play("stun")
		current_state = "stun"

func _play_anim_with_fallback(target_anim: String) -> void:
	var blend_time = 0.15 # Smoothly crossfade back to idle or into turns
	
	# 1. Exact Match
	if anim_player.has_animation(target_anim):
		anim_player.play(target_anim, blend_time)
		return
		
	# 2. Capitalization Fallbacks (avoids exact string mis-matches)
	if target_anim == "drive_idle" and anim_player.has_animation("Drive_Idle"):
		anim_player.play("Drive_Idle", blend_time)
		return
		
	# 3. Fallback to driving idle if specific directional animations are missing from the model
	if target_anim in ["Drive_Left", "Drive_Right", "Look_Back"]:
		if anim_player.has_animation("drive_idle"):
			anim_player.play("drive_idle", blend_time)
		elif anim_player.has_animation("Drive_Idle"):
			anim_player.play("Drive_Idle", blend_time)
