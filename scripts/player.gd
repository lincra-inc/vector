extends CharacterBody3D
class_name Player

@export var gamepad_look_sensitivity := 3.0
@export var gamepad_deadzone         := 0.15
@export var mouse_look_sensitivity   := 0.003

@export var run_lerp_speed: float = 8.0

@export var step_distance := 0.85
@export var step_height: float = 0.45
@export var step_forward_distance: float = 0.15
@export var step_check_distance: float = 0.5
@export var step_speed: float = 12.0

const MAX_SPEED    := 10.0
const ACCEL        := 70.0
const AIR_ACCEL    := 35.0
const FRICTION     := 10.0
const GRAVITY      := 18.0
const FALL_GRAVITY := 45.0

@export var JUMP_FORCE   := 9.0
@export var move_speed:    float = 6.0
@export var run_multiplier: float = 1.8

@onready var step_ray_low: RayCast3D = $StepRayLow
@onready var step_ray_high: RayCast3D = $StepRayHigh

@onready var camera:       Camera3D = $Head/Camera3D
@onready var input_state:  PlayerInputState = $InputState
@onready var player_state: PlayerState = $PlayerState

@onready var camera_shake: CameraShake  = $Head/CameraShake
@onready var camera_bob:   CameraBob    = $Head/CameraBob
@onready var recoil:       CameraRecoil = $Head/CameraRecoil

@onready var head: Node3D = $Head
#@onready var head_mesh: Node3D = $Head/MeshInstance3D

@onready var run_pivot:    Node3D = $Head/Camera3D/RunPivot
@onready var aim_pivot:    Node3D = $Head/Camera3D/AimPivot
@onready var weapon_pivot: Node3D = $Head/WeaponPivot
@onready var weapon_model: Node3D = $Head/WeaponPivot/Weapon
@onready var shoot_pivot:  Node3D = $Head/WeaponPivot/Weapon/ShootPivot
@onready var raycast:   RayCast3D = $Head/RayCast3D

@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var weapon_data: WeaponData   = $Head/WeaponPivot
@onready var anim_tree: AnimationTree   = $Body/Character2/AnimationTree

@export var aim_speed: float = 12.0

var coyote_timer := 0.0
@export var coyote_time_amount := 0.2

var footstep_timer := 0.0
@export var footstep_interval := 0.35

var peer_id: int
var direction := Vector2.ZERO
var view_rotation := Vector2.ZERO
var origin_weapon_position := Vector3.ZERO
var current_speed_multiplier: float = 1.0

var pitch := 0.0
var yaw   := 0.0
var dead  := false

var spawn_position: Vector3

@onready var ui_player: Control = $CanvasLayer/UI
@onready var ui_info: Control = $CanvasLayer/INFO

# UI Stuff!!
var stats_template  := ""
var energy_template := ""
var bullet_template := ""
var weapon_template := ""

var health_width : float = 0
var energy_width : float = 0
var delayed_health := 0.0
var damage_delay := 1.0
var damage_timer := 0.0
var delayed_energy := 0.0
var energy_timer := 0.0
var energy_delay := 1.0
@onready var health_bar : ColorRect = $CanvasLayer/UI/HealthBar
@onready var shadow_bar : ColorRect = $CanvasLayer/UI/ShadowHealthBar
@onready var energy_bar : ColorRect = $CanvasLayer/UI/EnergyBar
@onready var energy_shadow_bar : ColorRect = $CanvasLayer/UI/ShadowEnergyBar
@onready var stats_label: Label = $CanvasLayer/UI/character_text
@onready var power_label: Label = $CanvasLayer/UI/powerenergy_text
@onready var bullet_label: Label = $CanvasLayer/UI/bullet_text
@onready var weapon_label: Label = $CanvasLayer/UI/weapon_text

func _enter_tree():
	set_multiplayer_authority(int(name))

func setup(id: int) -> void:
	peer_id = id;

func _ready():
	# UI Inits!
	stats_template  = stats_label.text
	energy_template = power_label.text
	bullet_template = bullet_label.text
	weapon_template = weapon_label.text
	
	delayed_health = player_state.health
	delayed_energy = weapon_data.energy
	
	health_width = health_bar.size.x
	energy_width = energy_bar.size.x
	
	anim_tree.tree_root.resource_local_to_scene = true
	floor_snap_length = 0.5
	floor_max_angle = deg_to_rad(50)
	wall_min_slide_angle = deg_to_rad(88)
	
	floor_block_on_wall = false
	floor_snap_length = 0.1
	wall_min_slide_angle = deg_to_rad(15)
	
	if multiplayer.is_server():
		$PlayerState.set_multiplayer_authority(1)
		player_state.health = player_state.max_health
	
	if is_multiplayer_authority():
		origin_weapon_position = weapon_pivot.global_position
		
		$Name.text = Globals.player_name
		input_state.player_name = Globals.player_name
		
		ui_player.show()
		ui_info.hide()
		$Name.visible = false
		$Body/Character2/Armature_003/Skeleton3D/QuakeGuy_001.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		$Body/Character2/Armature_003/Skeleton3D/BoneAttachment3D/Weapon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		camera.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		camera.current = false
		$Head/WeaponPivot/Weapon/ArmaPlaceholder.hide()
		
		canvas_layer.hide()
	spawn_position = global_position

func _process(delta):
	
	if multiplayer.get_unique_id() != int(name):
		return
	
	if dead:
		return
	
	var main = get_tree().current_scene
	if Input.is_action_pressed("scoreboard"):
		main.scoreboard.show_scoreboard()
	else:
		main.scoreboard.hide_scoreboard()
	
	var look := Input.get_vector(
		"look_left",
		"look_right",
		"look_up",
		"look_down",
		gamepad_deadzone
	)
	
	if look != Vector2.ZERO:
		yaw   -= look.x * gamepad_look_sensitivity * delta
		pitch -= look.y * gamepad_look_sensitivity * delta
		pitch = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))
	
	#input_state.movement = Input.get_vector(
		#"ui_left",
		#"ui_right",
		#"ui_up",
		#"ui_down"
	#)
	
	update_shoot_input()
	
	# UI! Temporary
	$CanvasLayer/UI/name_text.text = Globals.player_name;
	$CanvasLayer/UI/Score.text = str("SCORE: ", input_state.kills, "/", input_state.deaths)
	
	var current_health = player_state.health
	health_bar.size.x = health_width * (current_health / player_state.max_health)
	if current_health < delayed_health:
		damage_timer += delta
		
		if damage_timer >= damage_delay:
			delayed_health = lerp(delayed_health, current_health, delta * 8.0)
			
			if abs(delayed_health - current_health) < 0.1:
				delayed_health = current_health
				
	else:
		delayed_health = current_health
		damage_timer = 0.0
	shadow_bar.size.x = health_width * (delayed_health / player_state.max_health)
	
	var current_energy = weapon_data.energy
	energy_bar.size.x = energy_width * (current_energy / weapon_data.max_energy)
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
	
	var ui_health_text : Label = $CanvasLayer/UI/health_text
	ui_health_text.text = str(int(player_state.health)) +"/"+ str(int(player_state.max_health))
	
	var ui_energy_text : Label = $CanvasLayer/UI/energy_text
	ui_energy_text.text = str(int(weapon_data.energy)) +"/"+ str(int(weapon_data.max_energy))
	
	# Stats!
	var text = stats_template \
		.replace("{HEALTH}", str("+", (int)(player_state.max_health-100.0))) \
		.replace("{RUN}", str("%.1f" % run_multiplier)) \
		.replace("{JUMP}", str("%.1f" % JUMP_FORCE))
	stats_label.text = text
	
	var power_text = energy_template \
		.replace("{EXTRA}", str("+", (int)(weapon_data.max_energy-100.0))) \
		.replace("{COST}", str("%.1f" % weapon_data.energy_cost)) \
		.replace("{REFILL}", str("%.1f" % weapon_data.recharge_speed))
	power_label.text = power_text
	
	var bullet_text = bullet_template \
		.replace("{AMOUNT}", str(weapon_data.projectile_per_shoot)) \
		.replace("{VEL}", str("%.1f" % weapon_data.projectile_speed)) \
		.replace("{SIZE}", str("%.1f" % weapon_data.projectile_size))
	bullet_label.text = bullet_text
	
	var weapon_text = weapon_template \
		.replace("{DAMAGE}", str("%.1f" % weapon_data.damage)) \
		.replace("{HEADSHOT}", str("%.1f" % weapon_data.critical_multiplier)) \
		.replace("{VEL_ATTK}", str("%.1f" % weapon_data.fire_rate)) \
		.replace("{RECOIL}", str("%.1f" % weapon_data.camera_shake))
	weapon_label.text = weapon_text
	
	#ui_health.add_theme_color_override("font_color", Color.GOLD)
	
	rotation.y = yaw + recoil.rotation_offset.y + camera_bob.position_offset.x
	head.rotation.x = pitch + recoil.rotation_offset.x  + camera_bob.position_offset.y

func _unhandled_input(event):
	if !is_multiplayer_authority():
		return
	
	if event.is_action_pressed("ui_cancel"): # Typically the Escape key
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		#get_tree().quit()
	
	if dead:
		return
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_look_sensitivity)
		
		yaw -= event.relative.x * mouse_look_sensitivity
		
		pitch -= event.relative.y * mouse_look_sensitivity
		pitch  = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))
	

func update_footsteps(delta: float):
	if !is_multiplayer_authority():
		return
	
	var input := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	var moving := input.length() > 0.1 and is_on_floor()

	footstep_timer -= delta

	if moving and footstep_timer <= 0:
		footstep_timer = (
			0.22 if Input.is_action_pressed("run")
			else 0.35
		)

		input_state.footstep_sequence += 1

var last_position: Vector3
var stopped_time := 0.0

func _physics_process(delta):
	
	if multiplayer.is_server():
		return
	
	var is_dead = player_state.health <= 0
	anim_tree.set("parameters/StateMachine/conditions/dead", is_dead)
	
	# @TODO: EXTREME TEMPORARY!
	if is_dead:
		$Name.visible = false
	
	anim_tree.set("parameters/StateMachine/conditions/not_dead", !is_dead)
	if not is_dead:
		var jumping := !is_on_floor()
		
		var movement := global_position - last_position
		var speed = movement.length() / delta
		last_position = global_position
		
		var moving_backwards := false
		if movement.length() > 0.001:
			movement = movement.normalized()
			var forward := -global_transform.basis.z.normalized()
			moving_backwards = movement.dot(forward) < 0.0
			if moving_backwards:
				anim_tree.set("parameters/TimeScale/scale", -1.75 )
			else:
				anim_tree.set("parameters/TimeScale/scale", 2.0 )
		
		if jumping:
			anim_tree.set("parameters/StateMachine/conditions/run", false)
			anim_tree.set("parameters/StateMachine/conditions/idle", true)
		else:
			var is_moving: bool
			if speed > 0.1:
				stopped_time = 0.0
				is_moving = true
			else:
				stopped_time += delta
				is_moving = stopped_time < 0.02
			
			anim_tree.set("parameters/StateMachine/playback", is_moving)
			anim_tree.set("parameters/StateMachine/conditions/run", is_moving)
			anim_tree.set("parameters/StateMachine/conditions/idle", !is_moving)
		anim_tree.set("parameters/StateMachine/conditions/jump", jumping)
		anim_tree.set("parameters/StateMachine/conditions/walk", !jumping)
	
	if !is_multiplayer_authority():
		move_and_slide()
		return
	
	if dead:
		if Input.is_action_just_pressed("restart"):
			var main = get_tree().current_scene
			for it in main.players.get_children():
				if it is Player:
					if it.peer_id != peer_id:
						var body : Node3D = it.get_node("Body/Character2")
						body.show()
						var hand : Node3D= it.get_node("Head/WeaponPivot")
						hand.hide()
			
			var spawn := Network._find_spawn_position(
				main.spawns_pool,
				main.players,
				10.0
			)
			
			if spawn == Vector3.INF:
				spawn = spawn_position
			
			global_position = spawn
			velocity = Vector3.ZERO
			
			ui_player.show()
			ui_info.hide()
			
			dead = false
			camera.current = true
			yaw = randf_range(0.0, TAU)
			pitch = 0
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
			$Body/Character2/Armature_003/Skeleton3D/QuakeGuy_001.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			$Body/Character2/Armature_003/Skeleton3D/BoneAttachment3D/Weapon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			
			var my_hand := get_node("Head/WeaponPivot")
			my_hand.show()
			
			player_state.health = player_state.max_health
			player_state.set_health.rpc(player_state.health)
		return
	
	if !is_on_floor():
		coyote_timer -= delta
	else:
		coyote_timer = coyote_time_amount
	
	update_footsteps(delta)
	move_player(delta)

func move_player(delta):
	if !is_multiplayer_authority():
		return
	
	if dead:
		return
	
	var input := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)
	
	if is_on_floor() or coyote_timer > 0:
		if Input.is_action_just_pressed("jump"):
			coyote_timer = 0
			velocity.y = JUMP_FORCE
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
	
	var accel := 12.0 if is_on_floor() else 3.5
	
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
		velocity.y -= GRAVITY * delta
	
	var target_position: Vector3
	
	if Input.is_action_pressed("run"):
		target_position = run_pivot.global_position
	else:
		if Input.is_action_pressed("aim"):
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
	elif Input.is_action_pressed("aim"):
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
	
	weapon_data.shoot_pressed = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if !Input.is_action_pressed("shoot") or Input.is_action_pressed("run"):
		return
	
	raycast.force_raycast_update()
	
	var target: Vector3
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
		recoil.add_recoil(deg_to_rad(randf_range(weapon_data.recoil_pitch, weapon_data.recoil_pitch+1)), deg_to_rad(weapon_data.recoil_yaw))

func die(killer_id: int) -> void:
	if !multiplayer.is_server():
		return
	
	if dead:
		return
	dead = true
	
	player_state.health = 0.0
	print("Murió: " + str(peer_id) + " por " + str(killer_id))
	
	Network.spawn_play_at(
		global_position,
		"res://sounds/death.ogg"
	)
	
	if killer_id != -1:
		var killer := get_player_by_peer_id(killer_id)
		if killer:
			killer.add_kill.rpc()
	die_client.rpc_id(peer_id, killer_id)

@rpc("any_peer", "call_local", "reliable")
func add_kill():
	input_state.kills += 1

@rpc("any_peer", "call_local", "reliable")
func die_client(killer_id: int):
	if dead:
		return
	
	dead = true
	camera.current = false
	
	input_state.deaths += 1
	ui_player.hide()
	ui_info.show()
	
	$Body/Character2/Armature_003/Skeleton3D/QuakeGuy_001.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	$Body/Character2/Armature_003/Skeleton3D/BoneAttachment3D/Weapon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	
	var my_hand := get_node("Head/WeaponPivot")
	my_hand.hide()
	
	$Body/Character2/AnimationPlayer.current_animation = "mixamo_com"
	# global_position = spawn_position
	# global_position.y -= 10
	
	if killer_id != -1:
		var killer_data := get_player_by_peer_id(killer_id) as Player
		
		if killer_data != null:
			$CanvasLayer/INFO/Killer.text = killer_data.input_state.player_name;
		
		velocity = Vector3.ZERO
		
		var players := get_tree().current_scene.get_node("World/Players")
		var killer := players.get_node_or_null(str(killer_id))
		
		var target := get_spectator_target(killer_id)
		
		if target:
			var target_camera: Camera3D = target.get_node("Head/Camera3D")
			target_camera.current = true
			
			if target:
				var body := target.get_node("Body/Character2")
				body.hide()
				var hand := target.get_node("Head/WeaponPivot")
				hand.show()
			
			print("Ahora espectando a: ", target.peer_id)
		else:
			print("No hay jugadores vivos para espectar")

func get_player_by_peer_id(peer_id: int) -> Player:
	var players := get_tree().current_scene.get_node("World/Players")
	return players.get_node_or_null(str(peer_id))
	
func get_spectator_target(killer_id: int) -> Player:
	var players := get_tree().current_scene.get_node("World/Players")
	
	# Primero intentar seguir al killer
	var killer := players.get_node_or_null(str(killer_id))
	
	if killer and killer.player_state.health > 0 && !killer.dead:
		return killer
	
	# Buscar otro jugador vivo aleatorio
	var alive_players: Array[Node] = []
	
	for player in players.get_children():
		
		if player == null:
			continue
		
		if player == self:
			continue
		
		if player.player_state == null:
			continue
		
		if !player.dead && player.player_state.health > 0:
			alive_players.append(player)
	
	if alive_players.is_empty():
		return null
	
	return alive_players.pick_random()

func take_damage(killer: int, amount: float) -> void:
	if !multiplayer.is_server():
		return
	
	if dead:
		return
	
	player_state.health = max(player_state.health - amount, 0.0)
	player_state.set_health.rpc(player_state.health)
	
	hit_client.rpc_id(peer_id, amount)
	
	if player_state.health <= 0.0:
		die(killer)

@rpc("any_peer", "call_local", "reliable")
func hit_client(amount: int):
	camera_shake.add_shake(amount * 0.25)

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


func is_inside_concave(other: CollisionShape3D, concave_body: CollisionShape3D) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = other.shape
	query.transform = other.global_transform
	query.collide_with_bodies = true
	query.collide_with_areas = false
	
	var results = get_world_3d().direct_space_state.intersect_shape(query)
	
	for r in results:
		if r.collider == concave_body:
			return true
	
	return false
