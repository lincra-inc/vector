extends CharacterBody3D

# -----------------------------
# MOVEMENT
# -----------------------------
const MAX_SPEED := 10.0
const ACCEL := 70.0
const AIR_ACCEL := 35.0
const FRICTION := 10.0

const JUMP_FORCE := 9.0

const GRAVITY := 18.0
const FALL_GRAVITY := 45.0

# -----------------------------
# CAMERA
# -----------------------------
const MOUSE_SENS := 0.003

var spawn_position: Vector3

@onready var camera := $Camera3D

var pitch := 0.0

func _enter_tree():
	set_multiplayer_authority(int(name))



func _ready():
	if is_multiplayer_authority():
		camera.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	spawn_position = global_position

func _unhandled_input(event):
	if !is_multiplayer_authority():
		return

	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENS)

		pitch -= event.relative.y * MOUSE_SENS
		pitch = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))

		camera.rotation.x = pitch

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

	var horizontal = Vector3(velocity.x, 0, velocity.z)

	var speed = horizontal.length()

	if speed < 0.01:
		return

	var drop = speed * FRICTION * delta
	var new_speed = max(speed - drop, 0.0)

	horizontal *= new_speed / speed

	velocity.x = horizontal.x
	velocity.z = horizontal.z

func _physics_process(delta):

	if !is_multiplayer_authority():
		return

	# ESC para cerrar el juego
	if Input.is_action_pressed("ui_cancel"):
		get_tree().quit()
		
		#R para reiniciar la spawn position
	if Input.is_action_just_pressed("Reiniciar"):	
		global_position = spawn_position
		velocity = Vector3.ZERO 	
	

		
		


	var input = Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	var wish_dir = (transform.basis * Vector3(input.x, 0, input.y)).normalized()

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
