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

@onready var aim_pivot:    Node3D = $Head/Camera3D/AimPivot
@onready var weapon_pivot: Node3D = $Head/WeaponPivot
@onready var weapon_model: Node3D = $Head/WeaponPivot/Weapon
@onready var shoot_pivot:  Node3D = $Head/WeaponPivot/Weapon/ShootPivot
@onready var raycast:   RayCast3D = $Head/RayCast3D

@onready var weapon_data: WeaponData = $Head/WeaponPivot

@export var aim_speed: float = 12.0

var peer_id: int
var direction := Vector2.ZERO
var view_rotation := Vector2.ZERO
var origin_weapon_position := Vector3.ZERO
var current_speed_multiplier: float = 1.0

var pitch := 0.0
var yaw   := 0.0

var spawn_position: Vector3

@onready var ui_health: ProgressBar = $CanvasLayer/Health

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
		
		camera.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		$CanvasLayer.hide()
	spawn_position = global_position

func _process(delta):
	if multiplayer.get_unique_id() != int(name):
		return
	
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
	
	ui_health.value = player_state.health
	
	rotation.y = yaw + recoil.rotation_offset.y + camera_bob.position_offset.x
	head.rotation.x = pitch + recoil.rotation_offset.x  + camera_bob.position_offset.y

func _unhandled_input(event):
	if !is_multiplayer_authority():
		return
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_look_sensitivity)
		
		yaw -= event.relative.x * mouse_look_sensitivity
		
		pitch -= event.relative.y * mouse_look_sensitivity
		pitch  = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))
	
	if Input.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta):
	if !is_multiplayer_authority():
		return
	move_player(delta)

func move_player(delta):
	if !is_multiplayer_authority():
		return
	
	if Input.is_action_pressed("ui_cancel"):
		get_tree().quit()
	
	if Input.is_action_just_pressed("restart"):
		global_position = spawn_position
		velocity = Vector3.ZERO
	
	var input := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)
	
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_FORCE
	
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
	
	velocity.x = lerpf(velocity.x, target_velocity.x, 12.0 * delta)
	velocity.z = lerpf(velocity.z, target_velocity.z, 12.0 * delta)
	
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	
	var target_position: Vector3
	
	if Input.is_action_pressed("aim"):
		target_position = aim_pivot.global_position
	else:
		target_position = weapon_pivot.global_position
	
	target_position += camera_bob.position_offset * 1.35
	
	weapon_model.global_position = weapon_model.global_position.lerp(
		target_position,
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
	if !Input.is_action_pressed("shoot"):
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

func die() -> void:
	if !multiplayer.is_server():
		return
	
	player_state.health = 0.0
	player_state.deaths += 1
	
	print("Murió: ", peer_id)

func take_damage(amount: float) -> void:
	if !multiplayer.is_server():
		return
	
	player_state.health = max(player_state.health - amount, 0.0)
	player_state.set_health.rpc(player_state.health)
	
	if player_state.health <= 0.0:
		die()

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
