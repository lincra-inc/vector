extends CharacterBody3D
class_name Player

@export var gamepad_look_sensitivity := 3.0
@export var gamepad_deadzone         := 0.15
@export var mouse_look_sensitivity   := 0.003

@export var move_speed:    float = 6.0
@export var run_multiplier: float = 1.8
@export var run_lerp_speed: float = 8.0

@export var step_distance := 0.85
@export var step_height: float = 0.4
@export var step_forward_distance: float = 0.35
@export var step_check_distance: float = 0.5
@export var step_speed: float = 12.0

const MAX_SPEED    := 10.0
const ACCEL        := 70.0
const AIR_ACCEL    := 35.0
const FRICTION     := 10.0
const JUMP_FORCE   := 9.0
const GRAVITY      := 18.0
const FALL_GRAVITY := 45.0

@onready var step_ray_low: RayCast3D = $StepRayLow
@onready var step_ray_high: RayCast3D = $StepRayHigh

@onready var camera:       Camera3D = $Head/Camera3D
@onready var input_state:  PlayerInputState = $InputState
@onready var player_state: PlayerState = $PlayerState

@onready var camera_shake: CameraShake  = $Head/CameraShake
@onready var camera_bob:   CameraBob    = $Head/CameraBob
@onready var recoil:       CameraRecoil = $Head/CameraRecoil

@onready var head: Node3D = $Head
@onready var head_mesh: Node3D = $Head/MeshInstance3D

@onready var run_pivot:    Node3D = $Head/Camera3D/RunPivot
@onready var aim_pivot:    Node3D = $Head/Camera3D/AimPivot
@onready var weapon_pivot: Node3D = $Head/WeaponPivot
@onready var weapon_model: Node3D = $Head/WeaponPivot/Weapon
@onready var shoot_pivot:  Node3D = $Head/WeaponPivot/Weapon/ShootPivot
@onready var raycast:   RayCast3D = $Head/RayCast3D

@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var weapon_data: WeaponData = $Head/WeaponPivot

@export var aim_speed: float = 12.0

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

func _enter_tree():
	set_multiplayer_authority(int(name))

func setup(id: int) -> void:
	peer_id = id;

func _ready():
	floor_snap_length = 0.5
	floor_max_angle = deg_to_rad(50)
	wall_min_slide_angle = deg_to_rad(88)
	
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
		
		camera.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		camera.current = false
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
	
	var ui_health : Label = $CanvasLayer/UI/Health
	ui_health.text = str(int(player_state.health))
	if player_state.health < 25:
		ui_health.add_theme_color_override("font_color", Color.RED)
	elif player_state.health < 50:
		ui_health.add_theme_color_override("font_color", Color.ORANGE)
	elif player_state.health <= 100:
		ui_health.add_theme_color_override("font_color", Color.GREEN)
	else:
		ui_health.add_theme_color_override("font_color", Color.GOLD)
	
	rotation.y = yaw + recoil.rotation_offset.y + camera_bob.position_offset.x
	head.rotation.x = pitch + recoil.rotation_offset.x  + camera_bob.position_offset.y

func _unhandled_input(event):
	if !is_multiplayer_authority():
		return
	
	if dead:
		return
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_look_sensitivity)
		
		yaw -= event.relative.x * mouse_look_sensitivity
		
		pitch -= event.relative.y * mouse_look_sensitivity
		pitch  = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))
	
	if Input.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

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

func _physics_process(delta):
	if !is_multiplayer_authority():
		return
	
	if dead:
		if Input.is_action_just_pressed("restart"):
			var root = get_tree().current_scene
			
			var main = get_tree().current_scene
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
			
			player_state.health = player_state.max_health
			player_state.set_health.rpc(player_state.health)
		
		return
	
	update_footsteps(delta)
	move_player(delta)

func move_player(delta):
	if !is_multiplayer_authority():
		return
	
	if Input.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		#get_tree().quit()
	
	var input := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)
	
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_FORCE
			input_state.jump_sequence += 1
	
	var dir := (transform.basis.x * input.x - -transform.basis.z * input.y).normalized()
	
	var target_multiplier := 1.0
	if Input.is_action_pressed("run"):
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
	
	player_state.health = 0.0
	print("Murió: " + str(peer_id) + " por " + str(killer_id))
	
	Network.spawn_play_at(
		global_position,
		"res://sounds/death.ogg"
	)
	
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
		
		print("Ahora espectando a: ", target.peer_id)
	else:
		print("No hay jugadores vivos para espectar")
	
	global_position = spawn_position
	global_position.y -= 10

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
