extends CharacterBody3D
class_name Player

const MOUSE_SENS: float = 0.003

const MAX_SPEED := 10.0
const ACCEL := 70.0
const AIR_ACCEL := 35.0
const FRICTION := 10.0

const JUMP_FORCE := 9.0

const GRAVITY := 18.0
const FALL_GRAVITY := 45.

@onready var camera: Camera3D = $Head/Camera3D
@onready var input_state: PlayerInputState = $InputState

@onready var camera_shake: CameraShake = $Head/CameraShake
@onready var recoil: CameraRecoil = $Head/CameraRecoil

@onready var head: Node3D = $Head
@onready var head_mesh: Node3D = $Head/MeshInstance3D
@onready var weapon_pivot: Node3D = $Head/WeaponPivot
@onready var raycast: RayCast3D = $Head/RayCast3D

@export var fire_rate: float = 0.15

var peer_id: int
var shoot_timer := fire_rate
var direction := Vector2.ZERO
var view_rotation := Vector2.ZERO

var pitch := 0.0
var yaw := 0.0
var spawn_position: Vector3

func _enter_tree():
	set_multiplayer_authority(int(name))

func setup(id: int) -> void:
	peer_id = id;
	
func _ready():
	if is_multiplayer_authority():
		camera.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	spawn_position = global_position

func _process(delta):
	if multiplayer.get_unique_id() != int(name):
		return
	
	shoot_timer -= delta
	
	input_state.movement = Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)
	
	update_shoot_input()
	
	rotation.y = yaw + recoil.rotation_offset.y
	head.rotation.x = pitch + recoil.rotation_offset.x

func _unhandled_input(event):
	if !is_multiplayer_authority():
		return
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENS)
		
		yaw -= event.relative.x * MOUSE_SENS
		
		pitch -= event.relative.y * MOUSE_SENS
		pitch = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))
	
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

	if Input.is_action_just_pressed("Reiniciar"):
		global_position = spawn_position
		velocity = Vector3.ZERO

	var input := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	var wish_dir := (transform.basis * Vector3(input.x, 0, input.y)).normalized()

	if is_on_floor():

		apply_friction(delta)

		accelerate(wish_dir, MAX_SPEED, ACCEL, delta)

		if Input.is_action_just_pressed("Jump"):
			velocity.y = JUMP_FORCE

	else:

		accelerate(wish_dir, MAX_SPEED, AIR_ACCEL, delta)

		if velocity.y > 0:
			velocity.y -= GRAVITY * delta
		else:
			velocity.y -= FALL_GRAVITY * delta

	move_and_slide()
	
func accelerate(wish_dir: Vector3, wish_speed: float, accel: float, delta: float):

	var current_speed = velocity.dot(wish_dir)
	var add_speed = wish_speed - current_speed

	if add_speed <= 0:
		return

	var accel_speed = accel * delta * wish_speed

	if accel_speed > add_speed:
		accel_speed = add_speed

	velocity += wish_dir * accel_speed


func apply_friction(delta):

	var horizontal = Vector3(velocity.x,0,velocity.z)

	var speed = horizontal.length()

	if speed < 0.01:
		return

	var drop = speed * FRICTION * delta
	var new_speed = max(speed - drop,0.0)

	horizontal *= new_speed / speed

	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	
	move_and_slide()

func update_shoot_input():
	if !is_multiplayer_authority():
		return
	
	if shoot_timer > 0.0:
		return
	if !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return
	
	shoot_timer = fire_rate
	raycast.force_raycast_update()
	
	var target: Vector3
	if raycast.is_colliding():
		target = raycast.get_collision_point()
	else:
		target = raycast.global_position + (-camera.global_transform.basis.z) * 1000.0
	
	camera_shake.add_shake(.35)
	recoil.add_recoil(deg_to_rad(randf_range(11.6, 12.3)), deg_to_rad(10.7))
	
	input_state.shoot_sequence += 1
	input_state.shoot_position = weapon_pivot.global_position
	input_state.shoot_direction = (target - weapon_pivot.global_position).normalized()
