extends Node3D
class_name WeaponData

@export_group("Daño")
@export var damage: float = 10.0
@export var critical_multiplier: float = 2.0

@export_group("Cadencia")
@export var fire_rate: float = 0.15

@export_group("Proyectil")
@export var projectile_speed:    float = 80.0
@export var projectile_lifetime: float = 3.0

@export_group("Energía")
@export var max_energy:     float = 100.0
@export var energy:         float = 100.0
@export var energy_cost:    float = 10.0
@export var recharge_speed: float = 50.0
@export var recharge_shooting_multiplier: float = 0.5

@export_group("Recoil")
@export var recoil_pitch: float = 10.0
@export var recoil_yaw:   float = 5.0

@export_group("Efectos")
@export var projectile_scene: PackedScene
@export var camera_shake:     float = 0.25
@export_enum(
	"Crosshair",
	"Scope",
	"Holographic",
	"Sniper"
)
var sight_type := 0

@export_group("Audio")
@export var fire_sounds: Array[AudioStream]

@onready var ui_energy: Label = $"../../CanvasLayer/UI/Label"

var cooldown := 0.0
var shoot_pressed := false

func _process(delta):
	cooldown = max(cooldown - delta, 0.0)
	
	var delta_recharge = recharge_speed
	ui_energy.text = str(int(energy))
	
	if shoot_pressed:
		delta_recharge *= recharge_shooting_multiplier
	
	energy = min(energy + delta_recharge * delta, max_energy)

func try_fire() -> bool:
	if cooldown > 0.0:
		return false
	
	if energy < energy_cost:
		return false
	
	cooldown = fire_rate
	energy -= energy_cost
	return true

func apply_modifier(modifier: LootModifier) -> void:
	if modifier == null:
		return

	# Vida
	var player_state := $"../../PlayerState" as PlayerState
	if player_state:
		player_state.health = min(
			player_state.health + modifier.health,
			player_state.max_health
		)
		player_state.set_health.rpc(player_state.health)

	# Daño
	damage += modifier.damage
	critical_multiplier += modifier.critical_multiplier

	# Cadencia
	fire_rate += modifier.fire_rate
	fire_rate = max(fire_rate, 0.02)

	# Proyectil
	projectile_speed += modifier.projectile_speed
	projectile_lifetime += modifier.projectile_lifetime

	# Energía
	max_energy += modifier.max_energy
	energy = min(energy, max_energy)

	energy_cost += modifier.energy_cost
	energy_cost = max(energy_cost, 0.0)

	recharge_speed += modifier.recharge_speed
	recharge_speed = max(recharge_speed, 0.0)

	# Recoil
	recoil_pitch += modifier.recoil_pitch
	recoil_yaw += modifier.recoil_yaw

	# Efectos
	camera_shake += modifier.camera_shake
