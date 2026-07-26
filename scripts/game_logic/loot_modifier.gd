extends Node
class_name LootModifier

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

@export_group("Energía")
@export var max_energy: float = 0.0
@export var energy_cost: float = 0.0
@export var recharge_speed: float = 0.0

@export_group("Recoil")
@export var recoil_pitch: float = 0.0
@export var recoil_yaw: float = 0.0

@export_group("Efectos")
@export var camera_shake: float = 0.0

func setup(modifier_type: int) -> void:
	var material := $PowerUp/MeshInstance3D.get_active_material(0) as ShaderMaterial
	
	var color : Color
	var text : String
	
	if modifier_type == 0:
		health = randf_range(10, 20)
		color = Color.GREEN
		text  = "+" + str(int(health))
	elif modifier_type == 1:
		damage = randf_range(2, 6)
		color = Color.ORANGE
		text  = "+" + str(int(damage))
	elif modifier_type == 2:
		max_energy = randf_range(5, 10)
		color = Color.SKY_BLUE
		text  = "+" + str(int(max_energy))
	elif modifier_type == 3:
		recharge_speed = randf_range(5, 10)
		color = Color.BLUE_VIOLET
		text  = "+" + str(int(recharge_speed))
	elif modifier_type == 4:
		recharge_speed = randf_range(0.01, 0.02)
		color = Color.YELLOW
		text  = "+" + str("%.2f" % recharge_speed)
	else:
		critical_multiplier = randf_range(0.04, 0.10)
		color = Color.GOLD
		text  = "+" + str("%.2f" % critical_multiplier)
	
	if material:
		$PowerUp/Label3D.text = text
		$PowerUp/Label3D.modulate = color
		material.set_shader_parameter("ColorParameter", color)
