extends Node

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

func setup(modifier: int) -> void:
	pass
