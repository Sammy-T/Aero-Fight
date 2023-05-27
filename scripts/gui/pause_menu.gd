extends VBoxContainer


const MAIN_MENU: String = "res://scenes/gui/main_menu.tscn"

@onready var main_bus_idx: int = AudioServer.get_bus_index("Master")
@onready var music_bus_idx: int = AudioServer.get_bus_index("Music")
@onready var sfx_bus_idx: int = AudioServer.get_bus_index("Sfx")

@onready var main_volume: HSlider = %MainVolume
@onready var music_volume: HSlider = %MusicVolume
@onready var sfx_volume: HSlider = %SfxVolume


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().paused = true
	
	_init_audio_controls()
	
	%Resume.grab_focus()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_pause"):
		_resume_scene()
		get_viewport().set_input_as_handled()


func _init_audio_controls() -> void:
	main_volume.value = db_to_linear(AudioServer.get_bus_volume_db(main_bus_idx))
	music_volume.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus_idx))
	sfx_volume.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_idx))


func _resume_scene() -> void:
	get_tree().paused = false
	queue_free()


func _on_resume_pressed() -> void:
	_resume_scene()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU)


func _on_main_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(main_bus_idx, linear_to_db(value))


func _on_music_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(music_bus_idx, linear_to_db(value))


func _on_sfx_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(sfx_bus_idx, linear_to_db(value))
