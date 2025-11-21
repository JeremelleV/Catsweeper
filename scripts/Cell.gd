extends Node2D

enum CellState { HIDDEN, REVEALED, FLAGGED }

var coord: Vector2i
var has_mine: bool = false
var neighbour_count: int = 0
var state: CellState = CellState.HIDDEN

@onready var tile_rect: ColorRect = $TileRect
@onready var number_label: Label = $TileRect/NumberLabel


func setup(x: int, y: int, size: int) -> void:
	coord = Vector2i(x, y)
	position = Vector2(x * size, y * size)
	print("TileRect is: ", tile_rect)  # should not be 'Null'
	tile_rect.size = Vector2(size, size)
	_refresh_visual()


func reveal() -> void:
	if state == CellState.REVEALED:
		return
	state = CellState.REVEALED
	_refresh_visual()


func reveal_with_delay(delay: float) -> void:
	# 👇 For now, ignore delay. Later we’ll use a Tween/AnimationPlayer.
	reveal()


func toggle_flag() -> void:
	if state == CellState.REVEALED:
		return

	if state == CellState.HIDDEN:
		state = CellState.FLAGGED
	elif state == CellState.FLAGGED:
		state = CellState.HIDDEN

	_refresh_visual()


func show_mine_triggered() -> void:
	# Called when this is the clicked mine (special styling later)
	state = CellState.REVEALED
	_refresh_visual()
	tile_rect.color = Color(1, 0, 0)  # bright red for now


func show_mine_revealed() -> void:
	# Called when revealing all mines on game over
	state = CellState.REVEALED
	_refresh_visual()


func play_pee_poo_wave(delay: float) -> void:
	# Placeholder for future pee/poo ripple animation
	# Later we’ll animate a colored overlay with this delay.
	pass


func _refresh_visual() -> void:
	match state:
		CellState.HIDDEN:
			tile_rect.color = Color(0.2, 0.2, 0.2)
			number_label.text = ""

		CellState.FLAGGED:
			tile_rect.color = Color(0.8, 0.8, 0.2)
			number_label.text = "F"

		CellState.REVEALED:
			if has_mine:
				tile_rect.color = Color(0.6, 0, 0)
				number_label.text = "X"
			else:
				tile_rect.color = Color(0.1, 0.3, 0.5)
				if neighbour_count > 0:
					number_label.text = str(neighbour_count)
				else:
					number_label.text = ""
