extends CharacterBody3D

const SPEED := 6.0
const MOUSE_SENS := 0.003

@onready var camera := $Camera3D

var pitch := 0.0

func _enter_tree():
	set_multiplayer_authority(int(name))

func _ready():
	if is_multiplayer_authority():
		camera.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	#$MeshInstance3D.visible = false

func _unhandled_input(event):
	if !is_multiplayer_authority():
		return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENS)
		pitch -= event.relative.y * MOUSE_SENS
		pitch = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))
		camera.rotation.x = pitch

func _physics_process(delta) -> void:
	if !is_multiplayer_authority():
		return
	
	if Input.is_action_pressed("ui_cancel"):
		get_tree().quit()
	
	var input := Input.get_vector(
	"ui_left",
	"ui_right",
	"ui_up",
	"ui_down")
	
	var dir := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
	move_and_slide()
