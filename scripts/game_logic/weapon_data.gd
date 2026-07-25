extends Node3D
class_name WeaponData

@export_group("Daño")
@export var damage: float = 20.0
@export var critical_multiplier: float = 2.0

@export_group("Cadencia")
@export var fire_rate: float = 0.15

@export_group("Proyectil")
@export var projectile_speed: float = 80.0
@export var projectile_lifetime: float = 3.0

@export_group("Energía")
@export var max_energy: float = 100.0
@export var energy: float = 100.0
@export var energy_cost: float = 10.0
@export var recharge_speed: float = 50.0

@export_group("Recoil")
@export var recoil_pitch: float = 10.0
@export var recoil_yaw: float = 5.0

@export_group("Efectos")
@export var projectile_scene: PackedScene
@export var camera_shake: float = 0.25
@export_enum(
	"Crosshair",
	"Scope",
	"Holographic",
	"Sniper"
)
var sight_type := 0

@export_group("Audio")
@export var fire_sounds: Array[AudioStream]

@onready var ui_energy: ProgressBar = $"../../CanvasLayer/Energy"

var cooldown := 0.0
var shoot_pressed := false

func _process(delta):
	cooldown = max(cooldown - delta, 0.0)
	
	var delta_recharge = recharge_speed
	ui_energy.value = energy
	
	if shoot_pressed:
		delta_recharge *= 0.5
	
	energy = min(energy + delta_recharge * delta, max_energy)

func try_fire() -> bool:
	if cooldown > 0.0:
		return false
	
	if energy < energy_cost:
		return false
	
	cooldown = fire_rate
	energy -= energy_cost
	return true
