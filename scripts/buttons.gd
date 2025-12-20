extends Control

@onready var box = %ButtonRow
@onready var hard_button = %ButtonRow.get_node("HardButton")

const PORTRAIT_OFFSET = Vector2(0, -350) # Offset from screen center in portrait
const LANDSCAPE_OFFSET = Vector2(-600, 100) # Offset from screen center in landscape
const MARGIN = 0 # Minimum distance from screen edges

func _ready():
	get_viewport().size_changed.connect(_on_size_changed)
	_on_size_changed.call_deferred() 

func _on_size_changed():
	if not is_node_ready() or not box:
		return
		
	var view_size = get_viewport().get_visible_rect().size
	var center = view_size / 2
	
	var target_offset : Vector2
	if view_size.y > view_size.x:
		box.vertical = false
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		target_offset = PORTRAIT_OFFSET
		
		if hard_button:
			hard_button.visible = false
		
	else:
		box.vertical = true
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		target_offset = LANDSCAPE_OFFSET
		
		if hard_button:
			hard_button.visible = true
		
	var ideal_pos = center + target_offset - (box.size / 2)
	
	var min_x = MARGIN
	var max_x = view_size.x - box.size.x - MARGIN
	var min_y = MARGIN
	var max_y = view_size.y - box.size.y - MARGIN
	
	box.global_position.x = clamp(ideal_pos.x, min_x, max_x)
	box.global_position.y = clamp(ideal_pos.y, min_y, max_y)
	
