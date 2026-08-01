extends Node3D

@export var card_field_label: PackedScene
@export var card_field_value: PackedScene
@onready var card_name_label = $SubViewport/CardInformation/Name
@onready var card_stats = $SubViewport/CardInformation/Stats/GridContainer

var card_values = {}

var stat_labels = {}
var value_labels = {}

var plain_card_name

func initialize_card(card_name,card_value_array):
	card_name_label.text = card_name
	plain_card_name = card_name
	card_values = card_value_array
	for item in card_values:
		var card_stat_label = card_field_label.instantiate()
		card_stat_label.text = str(item)
		card_stats.add_child(card_stat_label)
		stat_labels[item] = card_stat_label
		var card_stat_value = card_field_value.instantiate()
		card_stat_value.text = str(card_values[item])
		value_labels[item] = card_stat_value
		card_stats.add_child(card_stat_value)


func set_image(card_image_path):
	var new_mat = StandardMaterial3D.new()
	var image = Image.load_from_file(card_image_path)
	var card_texture = ImageTexture.create_from_image(image)
	new_mat.albedo_texture = card_texture
	$CardImage.set_surface_override_material(0, new_mat)

# Call this on the server/authority
func request_reparent(new_parent: Node, front: bool = true) -> void:
	if not multiplayer.is_server():
		return
	rpc("_execute_reparent", new_parent.get_path(), front)


@rpc("call_local", "reliable")
func _execute_reparent(new_parent_path: NodePath, front: bool) -> void:
	var target = get_node_or_null(new_parent_path)
	if target:
		if get_parent() != target:
			reparent(target, true)
		
		# Move to end if front is true, or position 0 if false
		var target_index = -1 if front else 0
		target.move_child(self, target_index)

@export var highlight_color: Color

@rpc("any_peer", "call_local", "reliable")
func highlight_stat(stat_name):
	print("Highlighting on card "+str(self)+" "+str(stat_name))
	for item in card_values:
		if stat_labels[item].has_theme_color_override("font_color") and item != stat_name:
			stat_labels[item].remove_theme_color_override("font_color")
			value_labels[item].remove_theme_color_override("font_color")
		else:
			if item == stat_name:
				stat_labels[item].add_theme_color_override("font_color",highlight_color)
				value_labels[item].add_theme_color_override("font_color",highlight_color)

@rpc("any_peer", "call_local", "reliable")
func clear_stat_selection():
	highlight_stat("")
