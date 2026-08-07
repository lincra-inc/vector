extends Area3D

@export var damage: float = 9999.0
@export var damage_interval := 1.0

var damage_timer := 0.0

func _process(delta: float) -> void:
	if !Network.is_server():
		return

	damage_timer += delta

	if damage_timer < damage_interval:
		return

	damage_timer = 0.0

	var damaged: Dictionary = {}

	for overlap in get_overlapping_areas():
		var player := overlap.get_parent() as Player

		if player == null:
			continue

		# Evita hacer daño varias veces si el jugador tiene varias áreas
		if damaged.has(player.peer_id) or player.network_state.dead or player.network_state.health <= 0:
			continue

		damaged[player.peer_id] = true
		var final_damage := damage * randf_range(0.75, 1.25)
		player.take_damage(-1, final_damage, Vector3(randf(), randf(), randf()))
