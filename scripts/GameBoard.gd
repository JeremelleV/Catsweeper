extends Node2D

@export var cols: int = 9
@export var rows: int = 9
@export var cell_size: int = 32

var cells: Array = []

func _ready() -> void:
	_create_board()

func _create_board() -> void:
	# Clear old children if recreate the board
	for child in get_children():
		child.queue_free()
	cells.clear()

	for y in range(rows):
		var row: Array = []
		for x in range(cols):
			var tile := ColorRect.new()
			tile.size = Vector2(cell_size, cell_size)
			tile.position = Vector2(x * cell_size, y * cell_size)
			tile.color = Color(0.2, 0.2, 0.2) # placeholder dark gray

			add_child(tile)
			row.append(tile)
		cells.append(row)
