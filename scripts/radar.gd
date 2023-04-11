extends MarginContainer


var radar_scale: Vector2
var zoom: float = 1.25
var radar_center_pos: Vector2
var radar_radius: float
var player: Node2D
var markers: Dictionary = {}

@onready var radar_bg: TextureRect = %RadarBg
@onready var marker_holder: Node2D = %MarkerHolder
@onready var marker_types: Dictionary = {
		"marked_interest": %Interest,
		"marked_warning": %Warning
}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var margin_l = get_theme_constant("margin_left")
	var margin_r = get_theme_constant("margin_right")
	var margin_t = get_theme_constant("margin_top")
	var margin_b = get_theme_constant("margin_bottom")
	
	var child_offset: Vector2 = Vector2(margin_l, margin_t) # Start position for children
	var container_margin: Vector2 = Vector2(margin_l + margin_r, margin_t + margin_b)
	var radar_bg_size: Vector2 = size - container_margin
	
	radar_scale = radar_bg_size / get_viewport_rect().size * zoom
	radar_center_pos = radar_bg_size * 0.5 + child_offset
	radar_radius = radar_bg_size.x * 0.5
	
	$Templates.hide()
	
	player = get_tree().get_first_node_in_group("player")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	for node in markers:
		var relative_pos: Vector2 = ((node.position - player.position) * radar_scale)\
				.limit_length(radar_radius)
		
		markers[node].position = relative_pos + radar_center_pos


func add_marker(node: Node2D) -> void:
	var marker: Sprite2D
	
	# Determine which marker to add
	for group in marker_types:
		if node.is_in_group(group):
			marker = marker_types[group].duplicate()
			break
	
	# Add the marker and store a mapping to its related node
	marker_holder.add_child(marker)
	markers[node] = marker
	
	# Remove the marker when the node is deleted. 
	# (The lamda function allows the node to passed as an additional parameter)
	node.tree_exited.connect(func(): remove_marker(node))


func remove_marker(node: Node2D) -> void:
	markers[node].queue_free()
	markers.erase(node)
