extends CharacterBody3D
class_name Player

const SPEED: float = 6.0
const MOUSE_SENS: float = 0.003
const GRAVITY: float = 20.0



@onready var camera: Camera3D = $Head/Camera3D
@onready var input_state: PlayerInputState = $InputState

@onready var head: Node3D = $Head
@onready var head_mesh: Node3D = $Head/MeshInstance3D
@onready var weapon_pivot: Node3D = $Head/WeaponPivot
@onready var raycast: RayCast3D = $Head/RayCast3D

@export var fire_rate: float = 0.3

var shoot_timer := fire_rate

var direction := Vector2.ZERO
var view_rotation := Vector2.ZERO

var pitch := 0.0

func _enter_tree():
	set_multiplayer_authority(int(name))

func _ready():
	if is_multiplayer_authority():
		camera.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		#$head_mesh.visible = false

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

func _unhandled_input(event):
	if !is_multiplayer_authority():
		return
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENS)
		pitch -= event.relative.y * MOUSE_SENS
		
		pitch = clamp(
			pitch,
			deg_to_rad(-89),
			deg_to_rad(89)
		)
		
		head.rotation.x = pitch
	
	if Input.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta):
	if !is_multiplayer_authority():
		return
	move_player(delta)

func move_player(delta):
	if !is_multiplayer_authority():
		return
	
	var input := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)
	
	var dir := (
		transform.basis.x * input.x
		-
		-transform.basis.z * input.y
	).normalized()
	
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
	
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

	input_state.shoot_sequence += 1
	input_state.shoot_position = weapon_pivot.global_position
	input_state.shoot_direction = -camera.global_transform.basis.z

#func move_player(delta):
	#var direction := Vector3(
		#input_state.movement.x,
		#0,
		#input_state.movement.y
	#)
	#
	#direction = transform.basis * direction
	#direction = direction.normalized()
	#
	#velocity.x = direction.x * SPEED
	#velocity.z = direction.z * SPEED
	#
	#if not is_on_floor():
		#velocity.y -= GRAVITY * delta
	#move_and_slide()

#func _unhandled_input(event):
	#if !is_multiplayer_authority():
		#return
	#if event is InputEventMouseMotion:
		#rotate_y(-event.relative.x * MOUSE_SENS)
		#pitch -= event.relative.y * MOUSE_SENS
		#pitch = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))
		##camera.rotation.x = pitch
		#head.rotation.x = pitch
	#
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_LEFT:
			#if event.pressed:
				#shoot()
#
#func _physics_process(delta) -> void:
	#if !is_multiplayer_authority():
		#return
	#
	#if Input.is_action_pressed("ui_cancel"):
		#get_tree().quit()
	#
	#var input := Input.get_vector(
	#"ui_left",
	#"ui_right",
	#"ui_up",
	#"ui_down")
	#
	#var dir := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	#velocity.x = dir.x * SPEED
	#velocity.z = dir.z * SPEED
	#move_and_slide()
