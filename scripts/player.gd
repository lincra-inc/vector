extends CharacterBody3D
class_name Player



#
#   PLAYER SETTINGS - CONFIG
#
#@export var gamepad_look_sensitivity := 3.0
#@export var mouse_look_sensitivity   := 0.003
@export var gamepad_deadzone         := 0.15

@export var hurt_fade_speed := 0.5
@export var hurt_hit_strength := 1.5
var hurt_alpha := 0.0

@export var jump_buffer_time := 0.15
var jump_buffer_timer := 0.0

@export_group("Fall Damage")
@export var fall_damage_min_speed := 16.0      # velocidad mínima para recibir daño
@export var fall_damage_multiplier := 3.0      # daño por unidad de velocidad
@export var fall_damage_max := 100.0

var was_on_floor := true
var max_fall_speed := 0.0

#
#   GAMEPLAY-MOVEMENT-SETTINGS 
#
@export var step_distance         : float= 0.85
@export var step_height           : float = 0.45
@export var step_forward_distance : float = 0.15
@export var step_check_distance   : float = 0.5
@export var step_speed            : float = 12.0

@onready var step_ray_low  : RayCast3D = $StepRayLow
@onready var step_ray_high : RayCast3D = $StepRayHigh



#
# PLAYER-MOVEMENT 
#
@export var jump_force : float = 9.0

@export var max_speed        : float = 10.0
@export var acceleration     : float = 12.0
@export var air_acceleration : float = 3.5
@export var gravity          : float = 18.0

@export var aim_speed  : float = 12.0
@export var move_speed : float = 6.0

@export var run_multiplier   : float = 1.6
@export var run_lerp_speed   : float = 8.0
var current_speed_multiplier : float = 1.0



#
# PLAYER-RELATED MOVEMENT
#
@export var coyote_time_amount := 0.2
var coyote_timer := 0.0

@export var footstep_interval := 0.35
var footstep_timer := 0.0



#
# INPUT-DATA
#
var spawn_position: Vector3
var pitch := 0.0
var yaw   := 0.0



#
# PLAYER-UNIQUE-DATA REFERENCES
#
@onready var input_state   : InputState  = $InputState
@onready var network_state : NetworkState  = $NetworkState
@onready var weapon_data   : WeaponData  = $Head/WeaponPivot
# @onready var player_state  : PlayerState = $PlayerState

@onready var input_sync = $InputState/MultiplayerSynchronizer
@onready var network_sync = $NetworkState/MultiplayerSynchronizer


#
# NODE REFERENCES
#
@onready var head          : Node3D = $Head
@onready var camera        : Camera3D = $Head/Camera3D
@onready var camera_shake  : CameraShake = $Head/CameraShake
@onready var camera_bob    : CameraBob = $Head/CameraBob
@onready var camera_recoil : CameraRecoil = $Head/CameraRecoil
@onready var anim_tree     : AnimationTree = $Body/Character2/AnimationTree

@onready var visual_model        : MeshInstance3D =  $Head/WeaponPivot/Weapon/ArmaPlaceholder/QuakeGuy_002
@onready var player_model        : MeshInstance3D =  $Body/Character2/Armature_003/Skeleton3D/QuakeGuy_001
@onready var player_model_weapon : MeshInstance3D =  $Body/Character2/Armature_003/Skeleton3D/BoneAttachment3D/Weapon
@onready var player_pov_model    : Node3D =  $Head/WeaponPivot/Weapon/ArmaPlaceholder


#
# NODE-PIVOT REFERENCES
#
@onready var run_pivot:    Node3D = $Head/Camera3D/RunPivot
@onready var aim_pivot:    Node3D = $Head/Camera3D/AimPivot
@onready var weapon_pivot: Node3D = $Head/WeaponPivot
@onready var weapon_model: Node3D = $Head/WeaponPivot/Weapon
@onready var shoot_pivot:  Node3D = $Head/WeaponPivot/Weapon/ShootPivot



#
# NODE-UTILITIES REFERENCES
#
@onready var raycast:   RayCast3D = $Head/RayCast3D
@onready var canvas_layer: CanvasLayer = $CanvasLayer
var main_core : MainCore


#
# NETWORK-DATA-INFO
#
@onready var display_name: Label3D = $Name
var peer_id : int = 0
var player_color : Color = Color.WHITE

# @NOTE(Liman1): This is use for the online-animations, when stopper_timer is <= 0 the animation is set to idle.
#                Cause we do not share animations states, we build it on the fly based on the motion and position on world.
var stopped_time_amount : float = 0.2
var stopped_timer := 0.0 
var last_position: Vector3



#
# USER-INTERFACE REFERENCES
#
@onready var ui_player: Control = $CanvasLayer/UI
@onready var ui_info :  Control = $CanvasLayer/INFO
@onready var ui_death :  Label = $CanvasLayer/INFO/Killer

@onready var hurt_effect: ColorRect = $CanvasLayer/UI/HurtEffect
@onready var fade_rect: ColorRect = $CanvasLayer/INFO/FadeEffect
var fading := false
var fade_target := 0.0
var fade_speed := 0.0

var death_sequence := false
var death_timer := 0.0
var death_phase := 0
var death_target: Player = null

var health_width : float = 0
var energy_width : float = 0
var delayed_health := 0.0
var damage_delay := 1.0
var damage_timer := 0.0
var delayed_energy := 0.0
var energy_timer := 0.0
var energy_delay := 1.0

@onready var player_name  : Label = $CanvasLayer/UI/name_text
@onready var player_score : Label = $CanvasLayer/UI/Score
@onready var ui_health_text : Label = $CanvasLayer/UI/health_text
@onready var ui_energy_text : Label = $CanvasLayer/UI/energy_text

@onready var health_bar : ColorRect = $CanvasLayer/UI/HealthBar
@onready var shadow_bar : ColorRect = $CanvasLayer/UI/ShadowHealthBar
@onready var energy_bar : ColorRect = $CanvasLayer/UI/EnergyBar
@onready var energy_shadow_bar : ColorRect = $CanvasLayer/UI/ShadowEnergyBar

@onready var extra_label  : Label = $CanvasLayer/UI/HBoxContainer/energy_container/EXTRA
@onready var cost_label   : Label = $CanvasLayer/UI/HBoxContainer/energy_container/COST
@onready var refill_label : Label = $CanvasLayer/UI/HBoxContainer/energy_container/REFILL
var extra_template  := ""
var cost_template   := ""
var refill_template := ""

@onready var damage_label   : Label = $CanvasLayer/UI/HBoxContainer/weapon_container/DAMAGE
@onready var headshot_label : Label = $CanvasLayer/UI/HBoxContainer/weapon_container/HEADSHOT
@onready var firerate_label : Label = $"CanvasLayer/UI/HBoxContainer/weapon_container/VEL ATTK"
@onready var recoil_label   : Label = $CanvasLayer/UI/HBoxContainer/weapon_container/RECOIL
var damage_template   := ""
var headshot_template := ""
var firerate_template := ""
var recoil_template   := ""

@onready var amount_label : Label = $CanvasLayer/UI/HBoxContainer/bullet_container/AMOUNT
@onready var vel_label    : Label = $CanvasLayer/UI/HBoxContainer/bullet_container/VEL
@onready var size_label   : Label = $CanvasLayer/UI/HBoxContainer/bullet_container/SIZE
var amount_template := ""
var vel_template    := ""
var size_template   := ""

@onready var health_label : Label = $CanvasLayer/UI/HBoxContainer/hero_container/HEALTH
@onready var jump_label   : Label = $CanvasLayer/UI/HBoxContainer/hero_container/JUMP
@onready var run_label    : Label = $CanvasLayer/UI/HBoxContainer/hero_container/RUN
var health_template := ""
var jump_template   := ""
var run_template    := ""

#
# CODE STARTS HERE :)
#

func _enter_tree():
	pass

func setup(color: Color, id: int) -> void:
	peer_id = id;
	player_color = color;
	set_multiplayer_authority(peer_id)
	$InputState.set_multiplayer_authority(peer_id)
	$InputState/MultiplayerSynchronizer.set_multiplayer_authority(peer_id)
	$NetworkState.set_multiplayer_authority(1)
	$NetworkState/MultiplayerSynchronizer.set_multiplayer_authority(1)

@rpc("any_peer", "reliable")
func set_player_name_and_color(name: String, color: Color):
	network_state.player_name = name.to_upper()
	network_state.player_color = color

func _ready():
	anim_tree.tree_root.resource_local_to_scene = true
	anim_tree.set("parameters/StateMachine/conditions/dead", false)
	anim_tree.set("parameters/StateMachine/conditions/not_dead", true)
	
	if is_multiplayer_authority():
		hurt_effect.material = hurt_effect.material.duplicate()
		fade_rect.modulate.a = 0
		#@NOTE(Liman1): World dependant initialization
		var main_node = get_tree().current_scene
		main_core = main_node as MainCore
		
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		set_player_name_and_color.rpc_id(1, Globals.player_name, player_color)
		display_name.text = Globals.player_name.to_upper()
		
		display_name.hide()
		ui_player.show()
		ui_info.hide()
		
		ui_player.set_anchors_preset(Control.PRESET_FULL_RECT)
		Input.use_accumulated_input = false
		
		player_model.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		player_model_weapon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		
		#@NOTE(Liman1): Weird movement initialization
		floor_snap_length    = 0.5
		floor_max_angle      = deg_to_rad(50)
		wall_min_slide_angle = deg_to_rad(88)
		
		floor_block_on_wall  = false
		floor_snap_length    = 0.1
		wall_min_slide_angle = deg_to_rad(15)
		
		spawn_position = global_position
		camera.current = true
		camera.make_current()
		
		damage_template   = damage_label.text
		headshot_template = headshot_label.text
		firerate_template = firerate_label.text
		recoil_template   = recoil_label.text
		
		extra_template  = extra_label.text
		cost_template   = cost_label.text
		refill_template = refill_label.text
		
		amount_template = amount_label.text
		vel_template    = vel_label.text
		size_template   = size_label.text
		
		health_template = health_label.text
		jump_template   = jump_label.text
		run_template    = run_label.text
		
		delayed_health = network_state.health
		delayed_energy = weapon_data.energy
		
		health_width = health_bar.size.x
		energy_width = energy_bar.size.x
	else:
		spawn_position = global_position
		
		canvas_layer.hide()
		player_pov_model.hide()
		
		camera.current = false


func _process(delta):
	#if visual_model:
		#var material := visual_model.get_active_material(0) as ShaderMaterial
		#
		#var unique_material := material.duplicate() as ShaderMaterial
		#visual_model.set_surface_override_material(0, unique_material)
		#if unique_material:
			#unique_material.set_shader_parameter("ColorParameter", player_color)
	
	if multiplayer.get_unique_id() != int(name):
		return
	
	#
	#@NOTE(Liman1): UI Updates.
	#
	if fading:
		var current := fade_rect.modulate.a
		current = move_toward(
			current,
			fade_target,
			fade_speed * delta
		)
		
		fade_rect.modulate.a = current
		if is_equal_approx(current, fade_target):
			fading = false
	
	if hurt_alpha > 0.0:
		hurt_alpha = hurt_alpha - (delta * hurt_fade_speed)
	if hurt_effect and hurt_effect.material:
		hurt_effect.material.set_shader_parameter("hurt_amount", hurt_alpha)
	
	if death_sequence:
		death_timer += delta
		# Esperar que termine el fade a negro
		if death_phase == 0:
			if fade_rect.modulate.a >= 0.99:
				death_phase = 1
				camera.current = false
				
				if death_target:
					ui_death.text = death_target.network_state.player_name
					
					var target_camera: Camera3D = death_target.get_node("Head/Camera3D")
					target_camera.current = true
					
					var body := death_target.get_node("Body/Character2")
					body.hide()
					
					var hand := death_target.get_node("Head/WeaponPivot")
					hand.show()
					
					var pov_hand := death_target.get_node("Head/WeaponPivot/Weapon/ArmaPlaceholder")
					pov_hand.show()
				else:
					print("No hay jugador para espectar")
				
				# si hay cámara nueva quitar negro
				if death_target:
					fade_screen(0.0, 0.4)
	
	# terminado
	elif death_phase == 1:
		if fade_rect.modulate.a <= 0.01:
			death_sequence = false
			fade_rect.modulate.a = 0
	#
	#
	#
	
	player_name.text  = network_state.player_name;
	player_score.text = str(network_state.kills, "/", network_state.deaths)
	# display_name.text  = network_state.player_name
	
	var current_health = network_state.health
	var health_percent : float = (current_health / network_state.max_health)
	
	health_bar.size.x  = health_width * health_percent
	if current_health < delayed_health:
		damage_timer += delta
		
		if damage_timer >= damage_delay:
			delayed_health = lerp(delayed_health, current_health, delta * 8.0)
			
			if abs(delayed_health - current_health) < 0.1:
				delayed_health = current_health
	else:
		delayed_health = current_health
		damage_timer = 0.0
	shadow_bar.size.x = health_width * (delayed_health / network_state.max_health)
	
	var current_energy = weapon_data.energy
	var energy_percent : float = (current_energy / weapon_data.max_energy)
	
	energy_bar.size.x = energy_width * energy_percent
	if current_energy < delayed_energy:
		energy_timer += delta
		
		if energy_timer >= energy_delay:
			delayed_energy = lerp(delayed_energy, current_energy, delta * 8.0)
			
			if abs(delayed_energy - current_energy) < 0.1:
				delayed_energy = current_energy
				
	else:
		# Si recupera energía, actualiza instantáneo
		delayed_energy = current_energy
		energy_timer = 0.0
	energy_shadow_bar.size.x = energy_width * (delayed_energy / weapon_data.max_energy)
	
	ui_health_text.text = str(int(network_state.health)) +"/"+ str(int(network_state.max_health))
	if network_state.health > network_state.max_health:
		health_bar.color = Color("00fbffff")
	else:
		health_bar.color = Color("5fbf00")
	
	ui_energy_text.text = str(int(weapon_data.energy)) +"/"+ str(int(weapon_data.max_energy))
	
	health_label.text = health_template.replace("{HEALTH}", str("+", (int)(network_state.max_health-100.0)))
	jump_label.text   = jump_template.replace("{JUMP}", str("%.1f" % jump_force))
	run_label.text    = run_template.replace("{RUN}", str("%.1f" % run_multiplier))
	
	extra_label.text  = extra_template.replace("{EXTRA}", str("+", (int)(weapon_data.max_energy-100.0)))
	cost_label.text   = cost_template.replace("{COST}", str("%.1f" % weapon_data.energy_cost))
	refill_label.text = refill_template.replace("{REFILL}", str("%.1f" % weapon_data.recharge_speed))
	
	amount_label.text = amount_template.replace("{AMOUNT}", str(weapon_data.projectile_per_shoot))
	vel_label.text    = vel_template.replace("{VEL}", str("%.1f" % weapon_data.projectile_speed))
	size_label.text   = size_template.replace("{SIZE}", str("%.1f" % weapon_data.projectile_size))
	
	damage_label.text   = damage_template.replace("{DAMAGE}", str("%.1f" % weapon_data.damage))
	headshot_label.text = headshot_template.replace("{HEADSHOT}", str("%.1f" % weapon_data.critical_multiplier))
	firerate_label.text = firerate_template.replace("{VEL_ATTK}", str("%.1f" % weapon_data.fire_rate))
	recoil_label.text   = recoil_template.replace("{RECOIL}", str("%.1f" % (weapon_data.camera_shake + weapon_data.recoil_pitch + weapon_data.recoil_yaw)))
	
	#ui_health.add_theme_color_override("font_color", Color.GOLD)
	
	if network_state.dead:
		return
	
	#@NOTE(Liman1): This is for joystick and mouse rotation.
	rotation.y      = yaw + camera_recoil.rotation_offset.y + camera_bob.position_offset.x
	head.rotation.x = pitch + camera_recoil.rotation_offset.x  + camera_bob.position_offset.y



func _input(event):
	if !is_multiplayer_authority():
		return
	
	if main_core.pause_menu.paused:
		return
	
	if event.is_action_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	
	if Input.is_action_pressed("scoreboard"):
		main_core.scoreboard.show_scoreboard()
	else:
		main_core.scoreboard.hide_scoreboard()
	
	if network_state.dead:
		if Input.is_action_just_pressed("restart"):
			request_respawn()
	else:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * Globals.mouse_look_sensitivity)
			
			yaw   -= event.relative.x * Globals.mouse_look_sensitivity
			pitch -= event.relative.y * Globals.mouse_look_sensitivity
			pitch  = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))

func request_respawn():
	input_state.respawn_request = true


@rpc("any_peer", "call_local", "reliable")
func respawn_player():
	input_state.respawn_request = false
	
	for it in main_core.players.get_children():
		if it is Player:
			if it.peer_id != peer_id:
				var body : Node3D = it.get_node("Body/Character2")
				body.show()
				var hand : Node3D= it.get_node("Head/WeaponPivot")
				hand.hide()
				it.player_pov_model.hide()
				camera.current = false
				it.display_name.show()
	
	var spawn := Network._find_spawn_position(
		main_core.spawns_pool,
		main_core.players,
		5.0
	)
	
	if spawn == Vector3.INF:
		spawn = spawn_position
	
	global_position = spawn
	velocity = Vector3.ZERO
	max_fall_speed = 0
	
	ui_player.show()
	ui_info.hide()
	
	camera.current = true
	yaw = randf_range(0.0, TAU)
	pitch = 0
	hurt_alpha = 0
	
	fading = false
	fade_rect.modulate.a = 0
	
	player_model.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	player_model_weapon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	weapon_pivot.show()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	if multiplayer.is_server():
		if input_state.respawn_request:
			network_state.dead = false
			network_state.health = network_state.max_health
			network_state.respawn_player = !network_state.respawn_player
			
			respawn_player.rpc_id(peer_id)
		return
	
	var is_dead = network_state.dead
	
	if is_dead:
		collision_layer &= ~(1 << 1)
	else:
		collision_layer |= (1 << 1)
	
	anim_tree.set("parameters/StateMachine/conditions/dead", is_dead)
	anim_tree.set("parameters/StateMachine/conditions/not_dead", !is_dead)
	
	# @TODO: REFACTOR ALL THIS CODE.
	if is_dead:
		if not is_on_floor():
			velocity.y -= gravity * delta
		
		move_and_slide()
		display_name.hide()
		return
	
	if not is_dead:
		var jumping := !is_on_floor()
		var movement := global_position - last_position
		var speed = movement.length() / delta
		last_position = global_position
		
		var moving_backwards := false
		if movement.length() > 0.01:
			movement = movement.normalized()
			var forward := -global_transform.basis.z.normalized()
			moving_backwards = movement.dot(forward) < 0.0
			if moving_backwards:
				anim_tree.set("parameters/TimeScale/scale", -1.75)
			else:
				anim_tree.set("parameters/TimeScale/scale", 2.0)
		
		if jumping:
			anim_tree.set("parameters/StateMachine/conditions/run", false)
			anim_tree.set("parameters/StateMachine/conditions/idle", true)
		else:
			var is_moving: bool
			if speed > 0.05:
				stopped_timer = 0.0
				is_moving = true
			else:
				stopped_timer += delta
				is_moving = stopped_timer < stopped_time_amount
			
			anim_tree.set("parameters/StateMachine/playback", is_moving)
			anim_tree.set("parameters/StateMachine/conditions/run", is_moving)
			anim_tree.set("parameters/StateMachine/conditions/idle", !is_moving)
		
		anim_tree.set("parameters/StateMachine/conditions/jump", jumping)
		anim_tree.set("parameters/StateMachine/conditions/walk", !jumping)
	
	if !is_multiplayer_authority():
		move_and_slide()
		return
	
	var look := Input.get_vector(
		"look_left",
		"look_right",
		"look_up",
		"look_down",
		gamepad_deadzone
	)
	
	if !is_on_floor():
		coyote_timer -= delta
	else:
		coyote_timer = coyote_time_amount
	
	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta
	
	yaw   -= look.x * Globals.gamepad_look_sensitivity * delta
	pitch -= look.y * Globals.gamepad_look_sensitivity * delta
	pitch  = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))
	
	update_autoaim(delta)
	update_shoot_input()
	
	update_footsteps(delta)
	move_player(delta)
	
	# Mientras cae, guardar la máxima velocidad alcanzada
	if !is_on_floor() and velocity.y < 0.0:
		max_fall_speed = max(max_fall_speed, -velocity.y)
	
	# Acaba de aterrizar
	if !was_on_floor and is_on_floor():
		if max_fall_speed > fall_damage_min_speed:
			var damage := (max_fall_speed - fall_damage_min_speed) * fall_damage_multiplier
			damage = clamp(damage, 0.0, fall_damage_max)
			input_state.apply_damage = damage
			input_state.damage_sequence += 1
		max_fall_speed = 0.0
	
	was_on_floor = is_on_floor()

func update_footsteps(delta: float):
	var input := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)
	
	var moving := input.length() > 0.1 and is_on_floor()
	
	footstep_timer -= delta
	if moving and footstep_timer <= 0:
		footstep_timer = (0.22 if Input.is_action_pressed("run") else 0.35)
		input_state.footstep_sequence += 1

func move_player(delta):
	if !is_multiplayer_authority():
		return
	
	if main_core.pause_menu.paused:
		return
	
	if network_state.dead:
		return
	
	var input := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)
	
	if Globals.always_run:
		if input.length() > 0.5 and !Input.is_action_pressed("shoot"):
			Input.action_press("run")
		else:
			Input.action_release("run")
	
	if (is_on_floor() or coyote_timer > 0.0) and jump_buffer_timer > 0.0:
		coyote_timer = 0.0
		jump_buffer_timer = 0.0
		velocity.y = jump_force
		input_state.jump_sequence += 1
	
	var dir := (transform.basis.x * input.x - -transform.basis.z * input.y).normalized()
	
	var target_multiplier := 1.0
	if is_on_floor():
		if Input.is_action_pressed("run") and input != Vector2.ZERO:
			target_multiplier = run_multiplier
	
	current_speed_multiplier = lerpf(
		current_speed_multiplier,
		target_multiplier,
		run_lerp_speed * delta
	)
	
	var target_velocity := dir * move_speed * current_speed_multiplier
	
	var accel := acceleration if is_on_floor() else air_acceleration
	
	velocity.x = lerpf(
		velocity.x,
		target_velocity.x,
		accel * delta
	)

	velocity.z = lerpf(
		velocity.z,
		target_velocity.z,
		accel * delta
	)
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	var target_position: Vector3
	
	if Input.is_action_pressed("run"):
		target_position = run_pivot.global_position
	else:
		if Input.is_action_pressed("aim") or Input.is_action_pressed("aim_and_shoot"):
			target_position = aim_pivot.global_position
		else:
			target_position = weapon_pivot.global_position
	
	target_position += camera_bob.position_offset * 1.35
	
	var target_transform := Transform3D(
		weapon_pivot.global_transform.basis,
		target_position
	)
	if Input.is_action_pressed("run"):
		target_transform = Transform3D(
			run_pivot.global_transform.basis,
			run_pivot.global_position
		)
	elif Input.is_action_pressed("aim") or Input.is_action_pressed("aim_and_shoot"):
		target_transform = Transform3D(
			aim_pivot.global_transform.basis,
			aim_pivot.global_position
		)
	else:
		target_transform = Transform3D(
			weapon_pivot.global_transform.basis,
			weapon_pivot.global_position
		)

	target_transform.origin += camera_bob.position_offset * 1.35

	weapon_model.global_transform = weapon_model.global_transform.interpolate_with(
		target_transform,
		aim_speed * delta
	)
	
	var horizontal_speed := Vector2(
		velocity.x,
		velocity.z
	).length()
	
	var speed_ratio := horizontal_speed / (move_speed * run_multiplier)
	
	camera_bob.update_bob(
		delta,
		speed_ratio,
		Input.is_action_pressed("run"),
		is_on_floor()
	)
	
	try_step_up(dir)
	move_and_slide()

func update_shoot_input():
	if !is_multiplayer_authority():
		return
	
	if main_core.pause_menu.paused:
		return
	
	weapon_data.shoot_pressed = Input.is_action_pressed("shoot") or Input.is_action_pressed("aim_and_shoot")
	if (!Input.is_action_pressed("shoot") and !Input.is_action_pressed("aim_and_shoot")) or Input.is_action_pressed("run"):
		return
	
	raycast.force_raycast_update()
	
	var target: Vector3
	
	if raycast.is_colliding():
		target = raycast.get_collision_point()
	else:
		target = raycast.global_position + (-camera.global_transform.basis.z) * 1000.0
	
	if Input.is_action_pressed("aim_and_shoot"):
		var enemy := get_autoaim_target()

		if enemy:
			target = enemy.head.global_position
		else:
			raycast.force_raycast_update()

			if raycast.is_colliding():
				target = raycast.get_collision_point()
			else:
				target = raycast.global_position + (-camera.global_transform.basis.z) * 1000.0
	else:
		raycast.force_raycast_update()

		if raycast.is_colliding():
			target = raycast.get_collision_point()
		else:
			target = raycast.global_position + (-camera.global_transform.basis.z) * 1000.0

	
	if(weapon_data.try_fire()):
		input_state.shoot_sequence += 1
		input_state.shoot_position = shoot_pivot.global_position
		input_state.shoot_direction = (target - shoot_pivot.global_position).normalized()
		
		camera_shake.add_shake(weapon_data.camera_shake)
		#recoil.add_recoil(deg_to_rad(randf_range(11.6, 12.3)), deg_to_rad(10.7))
		camera_recoil.add_recoil(deg_to_rad(randf_range(weapon_data.recoil_pitch, weapon_data.recoil_pitch+1)), deg_to_rad(weapon_data.recoil_yaw))

func die(killer_id: int) -> void:
	if !multiplayer.is_server():
		return
	
	print("Murió: " + str(peer_id) + " por " + str(killer_id))
	
	Network.spawn_play_at(
		global_position,
		"res://sounds/death.ogg"
	)
	
	collision_layer &= ~(1 << 1)
	
	for i in range(network_state.score):
		Network.spawn_loot_box(global_position + Vector3.UP, false, randi() % 20)
	network_state.score = 0
	
	if killer_id != -1:
		var killer := get_player_by_peer_id(killer_id)
		if killer:
			killer.network_state.kills += 1
	
	die_local.rpc_id(peer_id, killer_id)

@rpc("any_peer", "call_local", "reliable")
func add_kill():
	input_state.kills += 1

@rpc("any_peer", "call_local", "reliable")
func die_local(killer_id: int):
	# camera.current = false
	
	ui_player.hide()
	ui_info.show()
	
	weapon_pivot.hide()
	
	velocity = Vector3.ZERO
	
	death_sequence = true
	death_phase = 0
	death_timer = 0.0
	
	if killer_id != -1:
		death_target = get_spectator_target(killer_id)
	else:
		death_target = null
		#global_position = spawn_position
		#global_position.y -= 2
	fade_screen(1.0, 1)

func get_player_by_peer_id(peer_id: int) -> Player:
	var main = get_tree().current_scene
	var players : Node3D = main.players
	return players.get_node_or_null(str(peer_id))
	
func get_spectator_target(killer_id: int) -> Player:
	var players : Node3D = main_core.players
	
	# Primero intentar seguir al killer
	var killer := players.get_node_or_null(str(killer_id))
	
	if killer and killer.network_state.health > 0 && !killer.network_state.dead:
		return killer
	
	# Buscar otro jugador vivo aleatorio
	var alive_players: Array[Node] = []
	
	for player in players.get_children():
		
		if player == null:
			continue
		
		if player == self:
			continue
		
		if player.network_state == null:
			continue
		
		if !player.network_state.dead && player.network_state.health > 0:
			alive_players.append(player)
	
	if alive_players.is_empty():
		return null
	
	return alive_players.pick_random()

func take_damage(killer: int, amount: float, hit_direction: Vector3) -> void:
	if network_state.dead:
		return
	
	if multiplayer.is_server():
		network_state.health -= amount
		
		if network_state.health <= 0:
			network_state.health = 0
			network_state.dead = true
			network_state.deaths += 1
			if killer == -1:
				network_state.kills -= 1
			die(killer)
	
	hit_client.rpc_id(peer_id, hit_direction, amount)

func show_damage_direction(hit_direction: Vector3):
	var cam := $Head/Camera3D
	
	var incoming := hit_direction.normalized()
	var forward : Vector3 = -cam.global_transform.basis.z.normalized()
	
	# 1 = viene de frente
	# 0 = lateral
	# -1 = detrás
	var facing := forward.dot(incoming)
	
	if hurt_effect and hurt_effect.material:
		var shader := hurt_effect.material
		
		# Siempre dejamos la mancha roja
		shader.set_shader_parameter(
			"intensity",
			1.0
		)
		
		# Si viene de frente no mostrar flecha
		var arrow := 1.0
		
		if facing > 0.65:
			arrow = 0.0
		
		shader.set_shader_parameter("arrow_visibility", arrow)
		
		
		if arrow > 0.0:
			var right : Vector3 = cam.global_transform.basis.x
			var up : Vector3 = cam.global_transform.basis.y
			
			var dir2d := Vector2(
				incoming.dot(right),
				-incoming.dot(up)
			)
			
			dir2d = dir2d.normalized()
			
			shader.set_shader_parameter("damage_dir", dir2d)

@rpc("any_peer", "call_local", "reliable")
func hit_client(hit_position: Vector3, amount: int):
	camera_shake.add_shake(amount * 0.25)
	var strength := hurt_hit_strength * (float(amount) / 25.0)
	hurt_alpha = clamp(
		hurt_alpha + strength,
		0.0,
		1.0
	)
	
	show_damage_direction(hit_position)

func try_step_up(dir: Vector3):
	if not is_on_floor():
		return
	
	var forward := dir.normalized()
	
	# Convertir dirección global a local del RayCast
	var local_dir := global_transform.basis.inverse() * forward
	
	step_ray_low.target_position = local_dir * step_distance
	step_ray_high.target_position = local_dir * step_distance
	
	step_ray_low.force_raycast_update()
	step_ray_high.force_raycast_update()
	
	# No hay obstáculo delante
	if !step_ray_low.is_colliding():
		return
	
	# Hay techo/obstáculo arriba
	if step_ray_high.is_colliding():
		return
	
	var normal := step_ray_low.get_collision_normal()
	
	# Evitar subir paredes verticales
	if abs(normal.y) > 0.2:
		return
	
	var motion := Vector3.UP * step_height
	
	# Verificar que podemos movernos arriba
	if !test_move(global_transform, motion):
		global_position += motion


@export var autoaim_angle := 36.0 # grados

func get_autoaim_target() -> Player:
	var main = get_tree().current_scene

	var from := camera.global_position
	var forward := -camera.global_transform.basis.z

	var best: Player = null
	var best_dot := cos(deg_to_rad(autoaim_angle))

	for p in main.players.get_children():
		if p == self:
			continue

		var player := p as Player
		
		if player == null or player.dead:
			continue

		if player.player_state.health <= 0:
			continue

		var target_pos : Vector3 = player.head.global_position

		var dir := (target_pos - from).normalized()
		var dot := forward.dot(dir)

		if dot > best_dot:
			best_dot = dot
			best = p

	return best

@export var autoaim_speed := 10.0

func update_autoaim(delta: float):
	if !Input.is_action_pressed("aim_and_shoot"):
		return

	var enemy := get_autoaim_target()
	if enemy == null:
		return

	var target_pos := enemy.head.global_position
	var dir := (target_pos - camera.global_position).normalized()

	var target_yaw := atan2(-dir.x, -dir.z)
	var target_pitch := asin(dir.y)

	yaw = lerp_angle(yaw, target_yaw, autoaim_speed * delta)
	pitch = lerp_angle(
		pitch,
		clamp(target_pitch, deg_to_rad(-89), deg_to_rad(89)),
		autoaim_speed * delta
	)

func fade_screen(value: float, duration: float = 0.5):
	fade_target = value
	if duration <= 0.0:
		fade_rect.modulate.a = value
		fading = false
		return
	fade_speed = 1.0 / duration
	fading = true
