extends Node
class_name NetworkState


## Identidad
@export var peer_id: int = 1
@export var player_name: String = ""
@export var player_color: Color

## Estado
@export var dead := false
@export var max_health : float = 100.0
@export var health : float = 100.0
@export var armor: int = 0
@export var regeneration : float = 0.0

## Equipo
@export var team: int = 0

## Estadísticas
@export var kills: int = 0
@export var deaths: int = 0
@export var assists: int = 0
@export var score: int = 0

## Animación
@export var running: bool = false
@export var jumping: bool = false

## Eventos (incrementar para notificar cambios)
@export var damage_sequence: int = 0
@export var respawn_sequence: int = 0
@export var weapon_sequence: int = 0
@export var death_sequence: int = 0

@export var respawn_player: bool = false

func reset():
	dead = false

	health = max_health

	running   = false
	jumping   = false

	damage_sequence  = 0
	respawn_sequence = 0
	death_sequence   = 0
