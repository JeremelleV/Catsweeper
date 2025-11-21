extends Node2D

@export var cols: int = 9
@export var rows: int = 9
@export var cell_size: int = 32
@export var mine_count: int = 10

enum CellState { HIDDEN, REVEALED, FLAGGED }

var cells: Array = []
var cell_labels: Array = []
var board_data: Array = []

var first_click_done: bool = false
var game_over: bool = false

var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	_create_board()


func _create_board() -> void:
	for child in get_children():
		child.queue_free()

	cells.clear()
	cell_labels.clear()
	board_data.clear()
	first_click_done = false
	game_over = false

	for y in range(rows):
		var row_nodes: Array = []
		var row_labels: Array = []
		var row_data: Array = []

		for x in range(cols):
			var tile := ColorRect.new()
			tile.size = Vector2(cell_size, cell_size)
			tile.position = Vector2(x * cell_size, y * cell_size)
			tile.color = Color(0.2, 0.2, 0.2)
			add_child(tile)

			var label := Label.new()
			label.set_anchors_preset(Control.PRESET_FULL_RECT)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.text = ""
			tile.add_child(label)

			row_nodes.append(tile)
			row_labels.append(label)

			var cell_data := {
				"has_mine": false,
				"neighbour_count": 0,
				"state": CellState.HIDDEN
			}
			row_data.append(cell_data)

		cells.append(row_nodes)
		cell_labels.append(row_labels)
		board_data.append(row_data)


func _input(event: InputEvent) -> void:
	if game_over:
		return

	if event is InputEventMouseButton and event.pressed:
		var mouse_event := event as InputEventMouseButton

		# Position in GameBoard local coordinates
		var local_pos := to_local(mouse_event.position)
		var x := int(floor(local_pos.x / cell_size))
		var y := int(floor(local_pos.y / cell_size))

		# Debug so you can see clicks in console
		print("Click at local:", local_pos, " -> cell (", x, ",", y, ")")

		if x < 0 or x >= cols or y < 0 or y >= rows:
			return

		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click(x, y)
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_right_click(x, y)


func _handle_left_click(x: int, y: int) -> void:
	if game_over:
		return

	var cell = board_data[y][x]
	if cell["state"] == CellState.REVEALED:
		return

	if not first_click_done:
		_place_mines(x, y)
		_calculate_neighbours()
		first_click_done = true
		cell = board_data[y][x]  # refresh, just in case

	if cell["has_mine"]:
		_trigger_mine(x, y)
		return

	# 👇 NEW: decide between single reveal or flood-fill
	if cell["neighbour_count"] == 0:
		_flood_fill_from(x, y)
	else:
		_reveal_cell(x, y)

	_check_win_condition()


func _handle_right_click(x: int, y: int) -> void:
	if game_over or not first_click_done:
		return

	var cell = board_data[y][x]
	if cell["state"] == CellState.REVEALED:
		return

	if cell["state"] == CellState.HIDDEN:
		cell["state"] = CellState.FLAGGED
	elif cell["state"] == CellState.FLAGGED:
		cell["state"] = CellState.HIDDEN

	_update_tile_visual(x, y)


func _place_mines(safe_x: int, safe_y: int) -> void:
	var available_positions: Array = []

	for y in range(rows):
		for x in range(cols):
			if x == safe_x and y == safe_y:
				continue
			available_positions.append(Vector2i(x, y))

	available_positions.shuffle()

	var mines_to_place: int = min(mine_count, available_positions.size())
	for i in range(mines_to_place):
		var pos: Vector2i = available_positions[i]
		board_data[pos.y][pos.x]["has_mine"] = true


func _calculate_neighbours() -> void:
	for y in range(rows):
		for x in range(cols):
			if board_data[y][x]["has_mine"]:
				board_data[y][x]["neighbour_count"] = 0
				continue

			var count := 0
			for ny in range(max(0, y - 1), min(rows, y + 2)):
				for nx in range(max(0, x - 1), min(cols, x + 2)):
					if nx == x and ny == y:
						continue
					if board_data[ny][nx]["has_mine"]:
						count += 1

			board_data[y][x]["neighbour_count"] = count


func _reveal_cell(x: int, y: int) -> void:
	var cell = board_data[y][x]
	if cell["state"] == CellState.REVEALED:
		return

	cell["state"] = CellState.REVEALED
	_update_tile_visual(x, y)


func _flood_fill_from(x_start: int, y_start: int) -> void:
	var stack: Array = []
	stack.append(Vector2i(x_start, y_start))

	while stack.size() > 0:
		var pos: Vector2i = stack.pop_back()
		var x := pos.x
		var y := pos.y

		var cell = board_data[y][x]
		if cell["state"] == CellState.REVEALED:
			continue

		cell["state"] = CellState.REVEALED
		_update_tile_visual(x, y)

		if cell["neighbour_count"] != 0:
			continue

		for ny in range(max(0, y - 1), min(rows, y + 2)):
			for nx in range(max(0, x - 1), min(cols, x + 2)):
				if nx == x and ny == y:
					continue
				var neighbour = board_data[ny][nx]
				if neighbour["state"] == CellState.HIDDEN and not neighbour["has_mine"]:
					stack.append(Vector2i(nx, ny))


func _trigger_mine(x: int, y: int) -> void:
	game_over = true

	for yy in range(rows):
		for xx in range(cols):
			var cell = board_data[yy][xx]
			if cell["has_mine"]:
				cell["state"] = CellState.REVEALED
				_update_tile_visual(xx, yy)

	cells[y][x].color = Color(1, 0, 0)
	print("Game over – you clicked a mine.")


func _check_win_condition() -> void:
	for y in range(rows):
		for x in range(cols):
			var cell = board_data[y][x]
			if not cell["has_mine"] and cell["state"] != CellState.REVEALED:
				return

	game_over = true
	print("You win! 🎉")


func _update_tile_visual(x: int, y: int) -> void:
	var tile: ColorRect = cells[y][x]
	var label: Label = cell_labels[y][x]
	var cell = board_data[y][x]

	match cell["state"]:
		CellState.HIDDEN:
			tile.color = Color(0.2, 0.2, 0.2)
			label.text = ""

		CellState.FLAGGED:
			tile.color = Color(0.8, 0.8, 0.2)
			label.text = "F"

		CellState.REVEALED:
			if cell["has_mine"]:
				tile.color = Color(0.6, 0, 0)
				label.text = "X"
			else:
				tile.color = Color(0.1, 0.3, 0.5)
				var n: int = cell["neighbour_count"]
				label.text = str(n) if n > 0 else ""
