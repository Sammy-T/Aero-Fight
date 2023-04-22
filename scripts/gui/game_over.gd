extends VBoxContainer


const MAIN_MENU: String = "res://scenes/gui/main_menu.tscn"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%Restart.grab_focus()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func set_score_display(score: int) -> void:
	%Score.text = "Score %03d" % score


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()


func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU)
