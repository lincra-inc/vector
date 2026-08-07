extends Control

@onready var sound_slider : HSlider = $PanelContainer/Options/VBoxContainer/TextureRect2/VBoxContainer2/VBoxContainer/sound
@onready var music_slider : HSlider = $PanelContainer/Options/VBoxContainer/TextureRect2/VBoxContainer2/VBoxContainer/music
@onready var sensitivity_slider : HSlider = $PanelContainer/Options/VBoxContainer/TextureRect2/VBoxContainer2/VBoxContainer/sensitivity

@onready var resume_button : Button = $PanelContainer/Options/VBoxContainer/TextureRect2/VBoxContainer2/VBoxContainer/HBoxContainer/resume

var main_core : MainCore

func _ready():
	if Network.is_dedicated_server():
		return
	
	var main_node = get_tree().current_scene
	main_core = main_node as MainCore

	$PanelContainer.visible = false
	sound_slider.min_value = 0
	sound_slider.max_value = 100
	sound_slider.step = 1

	music_slider.min_value = 0
	music_slider.max_value = 100
	music_slider.step = 1

	sensitivity_slider.min_value = 0.1
	sensitivity_slider.max_value = 10.0
	sensitivity_slider.step = 0.1

	sound_slider.value = 100
	music_slider.value = 100
	sensitivity_slider.value = 3.0

	sound_slider.value_changed.connect(_on_sound_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)

	resume_button.pressed.connect(resume_game)

func pause_game():
	$PanelContainer.visible = true

func resume_game():
	$PanelContainer.visible = false

func _on_sound_changed(value: float):
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		linear_to_db(value / 100.0)
	)

func _on_music_changed(value: float):
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(value / 100.0)
	)

func _on_sensitivity_changed(value: float):
	Globals.mouse_look_sensitivity   = value / 1000
	Globals.gamepad_look_sensitivity = value


func _on_resume_pressed() -> void:
	resume_game()


func _on_options_pressed() -> void:
	pause_game()
