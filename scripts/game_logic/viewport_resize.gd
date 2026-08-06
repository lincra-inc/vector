extends SubViewportContainer

@export var base_size := Vector2i(1440, 1080)

@onready var viewport := $SubViewport

func _ready():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	await get_tree().process_frame
	resize_game()
	
func resize_game():
	var screen := get_viewport().get_visible_rect().size

	var scale := screen.y / float(base_size.y)
	var new_size := base_size * scale
	
	viewport.size = base_size
	size = new_size
	position = (screen - new_size) * 0.5
