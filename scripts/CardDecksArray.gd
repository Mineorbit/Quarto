extends HBoxContainer

@export var visible_items_target: int = 6

func _ready() -> void:
	# Ensure parent ScrollContainer handles horizontal scrolling
	var scroll_container = get_parent() as ScrollContainer
	if scroll_container:
		scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll_container.resized.connect(_update_layout)
	
	# Connect signals to react when items are added, removed, or resized
	resized.connect(_update_layout)
	child_entered_tree.connect(func(_c): call_deferred("_update_layout"))
	child_exiting_tree.connect(func(_c): call_deferred("_update_layout"))
	
	call_deferred("_update_layout")

func _update_layout() -> void:
	var scroll_container = get_parent() as ScrollContainer
	if not scroll_container:
		return
		
	var available_width = scroll_container.size.x
	if available_width <= 0:
		return
		
	var sep = get_theme_constant("separation")
	var count = get_child_count()
	if count == 0:
		return
		
	var total_separation = sep * (visible_items_target - 1)
	var item_width = (available_width - total_separation) / float(visible_items_target)
	
	for child in get_children():
		if child is Control:
			child.custom_minimum_size.x = item_width
			
	var total_width = (item_width * count) + (sep * max(0, count - 1))
	custom_minimum_size.x = total_width
