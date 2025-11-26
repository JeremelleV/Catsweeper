extends Node2D

###
@export var vertical_bg_texture: Texture2D 
@export var horizontal_bg_texture: Texture2D

# The path is: self (Gameboard) -> parent (BoardWrapper) -> parent (CenterContainer) -> parent (MainGame)
@onready var main_game_root: Control = get_tree().get_root().get_child(0)

@onready var bg_texture_rect: TextureRect = main_game_root.get_node("BathhouseBackground")

@onready var replay_button = get_parent().get_parent().get_parent().get_node("Top_HBox").get_node("ReplayButton")
###

@export var cols: int = 9
@export var rows: int = 9
@export var cell_size: int = 32
@export var mine_count: int = 10

enum CellState { HIDDEN, REVEALED, FLAGGED }

var cells: Array = []

var first_click_done: bool = false
var game_over: bool = false

var rng := RandomNumberGenerator.new()
var CellScene := preload("res://scenes/Cell.tscn")

func _ready() -> void:
	rng.randomize()
	_create_board()

	_update_background()
	get_viewport().size_changed.connect(_update_background)

func _update_background():
	var viewport_size = get_viewport_rect().size
	
	if viewport_size.x > viewport_size.y:
		bg_texture_rect.texture = horizontal_bg_texture
	else:
		bg_texture_rect.texture = vertical_bg_texture
	
	bg_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func _create_board() -> void:
	for child in get_children():
		child.queue_free()

	cells.clear()
	first_click_done = false
	game_over = false
	
	###
	var board_width = cols * cell_size
	var board_height = rows * cell_size
	
	var wrapper = get_parent()
	
	if wrapper is Control:
		wrapper.custom_minimum_size = Vector2(board_width,board_height)
	
	position = Vector2.ZERO #(-board_width / 2, -board_height / 2)
	###
	
	for y in range(rows):
		var row: Array = []
		for x in range(cols):
			var cell = CellScene.instantiate()
			
			cell.position = Vector2(x * cell_size, y * cell_size)
			
			add_child(cell)  
			cell.call_deferred("setup", x, y, cell_size)  
			row.append(cell)
		cells.append(row)

	replay_button.hide()

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

	var cell = cells[y][x]
	if cell.state == CellState.REVEALED:
		return

	if not first_click_done:
		_place_mines(x, y)
		_calculate_neighbours()
		first_click_done = true

	if cell.has_mine:
		_trigger_mine(x, y)
		return

	if cell.neighbour_count == 0:
		_flood_fill_from(x, y)
	else:
		cell.reveal()

	_check_win_condition()


func _handle_right_click(x: int, y: int) -> void:
	if game_over or not first_click_done:
		return

	var cell = cells[y][x]
	cell.toggle_flag()

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
		cells[pos.y][pos.x].has_mine = true


func _calculate_neighbours() -> void:
	for y in range(rows):
		for x in range(cols):
			var cell = cells[y][x]
			if cell.has_mine:
				cell.neighbour_count = 0
				continue

			var count := 0
			for ny in range(max(0, y - 1), min(rows, y + 2)):
				for nx in range(max(0, x - 1), min(cols, x + 2)):
					if nx == x and ny == y:
						continue
					if cells[ny][nx].has_mine:
						count += 1

			cell.neighbour_count = count
			# Keep visuals up-to-date for future reveals
			# (actual text only shows when revealed)

func _flood_fill_from(x_start: int, y_start: int) -> void:
	var queue: Array = []
	var dist_map = {}
	
	var start = Vector2i(x_start,y_start)
	queue.append(start)
	dist_map[start] = 0
	
	while queue.size() > 0:
		var pos = queue.pop_front()
		var x = pos.x
		var y = pos.y
		
		var d = int(dist_map[pos])
		var cell = cells[y][x]
		
		if cell.state == CellState.REVEALED:
			continue
		
		var delay = float(d) * 0.12 	# tweak for wave speed
		cell.reveal_with_delay(delay)
		
		if cell.neighbour_count != 0:
			continue
		
		for ny in range(max(0,y - 1), min(rows, y + 2)):
			for nx in range(max(0,x - 1), min(cols, x + 2)):
				if nx == x and ny == y:
					continue
					
				var neighbour = cells[ny][nx]
				
				if neighbour.state == CellState.HIDDEN and not neighbour.has_mine:
					var npos = Vector2i(nx,ny)
					if not dist_map.has(npos):
						dist_map[npos] = d + 1
						queue.append(npos)

func _trigger_mine(x: int, y: int) -> void:
	if game_over:
		return
	
	game_over = true
	replay_button.show()

	for yy in range(rows):
		for xx in range(cols):
			var cell = cells[yy][xx]
			if cell.has_mine:
				cell.show_mine_revealed()

	cells[y][x].show_mine_triggered()
	
	_start_pee_wave_from(x,y)
	
	print("Game over – you clicked a mine.")

func _start_pee_wave_from(mx: int, my: int) -> void:
	for y in range(rows):
		for x in range(cols):
			var dx: int = abs(x - mx)
			var dy: int = abs(y - my)
			
			var distance: int  = max(dx,dy)
			var delay := float(distance) * 0.12 # tweak 0.04 for wave speed
			
			var cell = cells[y][x]
			cell.play_pee_poo_wave(delay)

func _check_win_condition() -> void:
	for y in range(rows):
		for x in range(cols):
			var cell = cells[y][x]
			if not cell.has_mine and cell.state != CellState.REVEALED:
				return
	game_over = true
	replay_button.show()
	print("You win! 🎉")

func _on_replay_button_pressed():
	replay_button.hide()
	
	_create_board()
	_update_background()

func set_difficulty(difficulty_level: String) -> void:
	match difficulty_level:
		"easy":
			cols = 9
			rows = 9
			mine_count = 10
		"medium":
			cols = 16
			rows = 16
			mine_count = 40
		"hard":
			cols = 30
			rows = 16
			mine_count = 99
		_:
			cols = 9
			rows = 9
			mine_count = 10
	_create_board()
	_update_background()


func _on_easy_button_pressed() -> void:
	set_difficulty("easy")


func _on_medium_button_pressed() -> void:
	set_difficulty("medium")


func _on_hard_button_pressed() -> void:
	set_difficulty("hard")
