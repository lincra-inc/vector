extends Node3D

var lifetime : float = 3.0
var timer    : float = 0.0
var stream   : AudioStream

@onready var audio_pick: AudioStreamPlayer3D = $AudioStreamPlayer3D

func setup(path: String) -> void:
	stream = ResourceLoader.load(path) as AudioStream
	if stream == null:
		push_error("No se pudo cargar el audio: " + path)
		return

func _ready() -> void:
	audio_pick = $AudioStreamPlayer3D
	audio_pick.stream = stream
	audio_pick.play()

func _process(delta: float) -> void:
	timer += delta
	
	#if timer >= lifetime:
		#queue_free()
