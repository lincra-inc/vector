extends Node3D
class_name LootModifier

@export_group("Boost")
@export var jump_boost: float = 0.0
@export var health_boost: float = 0.0

@export_group("Atributos")
@export var speed: float = 0.0
@export var run_speed: float = 0.0
@export var jump: float = 0.0

@export_group("Vida")
@export var health: float = 0.0

@export_group("Daño")
@export var damage: float = 0.0
@export var critical_multiplier: float = 0.0

@export_group("Cadencia")
@export var fire_rate: float = 0.0

@export_group("Proyectil")
@export var projectile_speed: float = 0.0
@export var projectile_lifetime: float = 0.0
@export var projectile_size: float = 0.0
@export var projectile_per_shoot: int = 0

@export_group("Energía")
@export var max_energy: float = 0.0
@export var energy_cost: float = 0.0
@export var recharge_speed: float = 0.0

@export_group("Recoil")
@export var recoil_pitch: float = 0.0
@export var recoil_yaw: float = 0.0

@export_group("Efectos")
@export var camera_shake: float = 0.0

var color : Color
var text : String

var is_static : bool = true
var despawn_timer: float = 5.0

func _ready() -> void:
	var angle := randf() * TAU
	var distance := randf_range(0.1, 1.25)

	target_position = global_position + Vector3(
		cos(angle) * distance,
		0,
		sin(angle) * distance
	)
	
	start_position = target_position
	global_position = start_position

func setup(is_static: bool, modifier_type: int) -> void:
	self.is_static = is_static
	$PowerUp.visible = false
	$vida.visible = false
	$salto.visible = false
	
	if modifier_type < 15:
		$PowerUp.visible = true
	elif modifier_type == 15:
		$vida.visible = true
	else:
		$salto.visible = true
	
	color = Color(1.0, 0.825, 1.0)
	if modifier_type == 0:
		health = randf_range(10, 20)
		color = Color(0.0, 1.825, 0.0)
		text = "+" + str(int(health))

	elif modifier_type == 1:
		damage = randf_range(2, 6)
		color = Color(2.8, 0.672, 0.0)
		text = "+" + str(int(damage))

	elif modifier_type == 2:
		max_energy = randf_range(5, 10)
		color = Color(1.825, 1.825, 0.0)
		text = "+" + str(int(max_energy))

	elif modifier_type == 3:
		recharge_speed = randf_range(5, 10)
		color = Color(1.825, 1.825, 0.0)
		text = "+" + str(int(recharge_speed))

	elif modifier_type == 4:
		fire_rate = randf_range(0.0025, 0.0075)
		color = Color(2.8, 0.672, 0.0)
		text = "-" + str("%.2f" % fire_rate)

	elif modifier_type == 5:
		speed = randf_range(0.1, 0.5)
		color = Color(0.0, 1.825, 0.0)
		text = "+" + str("%.1f" % speed)

	elif modifier_type == 6:
		jump = randf_range(0.5, 2.0)
		color = Color(0.0, 1.825, 0.0)
		text = "+" + str("%.1f" % jump)

	elif modifier_type == 7:
		run_speed = randf_range(0.1, 0.5)
		color = Color(0.0, 1.825, 0.0)
		text = "+" + str("%.1f" % run_speed)

	elif modifier_type == 8:
		critical_multiplier = randf_range(0.05, 0.20)
		color = Color(2.8, 0.672, 0.0)
		text = "+" + str("%.2f" % critical_multiplier)

	elif modifier_type == 9:
		projectile_speed = randf_range(5, 15)
		color = Color(0.0, 1.193, 1.943)
		text = "+" + str(int(projectile_speed))

	elif modifier_type == 10:
		energy_cost = -randf_range(0.5, 1.5)
		color = Color(1.825, 1.825, 0.0)
		text = str(int(energy_cost))

	elif modifier_type == 11:
		recoil_pitch = randf_range(0.5, 2.0)
		color = Color(2.8, 0.672, 0.0)
		text = str("%.1f" % recoil_pitch)

	elif modifier_type == 12:
		recoil_yaw = randf_range(0.5, 2.0)
		color = Color(2.8, 0.672, 0.0)
		text = str("%.1f" % recoil_yaw)

	elif modifier_type == 14:
		camera_shake = randf_range(0.02, 0.10)
		color = Color(2.8, 0.672, 0.0)
		text = str("%.2f" % camera_shake)

	elif modifier_type == 15:
		color = Color(1.596, 0.473, 1.743, 1.0)
		health_boost = randf_range(30.0, 60.0)
		text = str("%.2f" % health_boost)
	elif modifier_type == 16:
		projectile_size = randf_range(0.1, 0.5)
		color = Color(0.0, 1.193, 1.943)
		text = "+" + str(int(projectile_size))
	elif modifier_type == 17:
		projectile_per_shoot = 1
		color = Color(0.0, 1.193, 1.943)
		text = "+" + str(int(projectile_size))

	else:
		color = Color(1.593, 1.592, 1.743, 1.0)
		text = str("<>")
		jump_boost = 10.0

	if not is_static:
		despawn_timer = 5.0
	
	if DisplayServer.get_name() == "headless":
		return
	
	var material := $PowerUp/MeshInstance3D.get_active_material(0) as ShaderMaterial
	var material2 := $PowerUp/MeshInstance3D/MeshInstance3D2.get_active_material(0) as ShaderMaterial
	
	if material:
		$PowerUp/Label3D.text = "+"
		$PowerUp/Label3D.modulate = color
		
		var unique_material := material.duplicate() as ShaderMaterial
		$PowerUp/MeshInstance3D.set_surface_override_material(0, unique_material)
		if unique_material:
			unique_material.set_shader_parameter("ColorParameter", color)
	
	if material2:
		
		var unique_material := material2.duplicate() as ShaderMaterial
		$PowerUp/MeshInstance3D/MeshInstance3D2.set_surface_override_material(0, unique_material)
		if unique_material:
			unique_material.set_shader_parameter("ColorParameter", color)

var landed : bool = false
var hover_time := randf() * TAU
var target_position : Vector3 = Vector3.ZERO
var hover_height : float = 1.0
var start_position: Vector3
var float_height := 0.15
var float_speed := 2.0

func _physics_process(delta):
	if is_static:
		return

	despawn_timer -= delta
	if despawn_timer <= 0.0:
		queue_free()
		return

	# Flotar en el lugar
	hover_time += delta * float_speed

	global_position.y = start_position.y + sin(hover_time) * float_height

	# Rotación suave
	rotate_y(delta)
