extends Control


const Level: PackedScene = preload("res://scenes/level.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%Play.grab_focus()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _on_play_pressed() -> void:
	get_tree().change_scene_to_packed(Level)
