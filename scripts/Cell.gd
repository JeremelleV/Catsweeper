extends Node2D

enum CellState { HIDDEN, REVEALED, FLAGGED }

var coord: Vector2i
var has_mine: bool = false
var neighbour_count: int = 0
var state: CellState = CellState.HIDDEN

@onready var tile_rect: ColorRect = $TileRect
@onready var number_label: Label = $TileRect/NumberLabel
@onready var sprite: Sprite2D = $Sprite

@export var tex_hidden_cat: Texture2D
@export var tex_water: Texture2D
@export var tex_mine_cat: Texture2D
@export var tex_flag_icon: Texture2D

func setup(x: int, y: int, size: int) -> void:
	coord = Vector2i(x, y)
	position = Vector2(x * size, y * size)
	tile_rect.size = Vector2(size, size)
	_refresh_visual()


func reveal() -> void:
	if state == CellState.REVEALED:
		return
		
	state = CellState.REVEALED
	_refresh_visual()

	# Simple pop/sink animation for now
	scale = Vector2(1.2,1.2)
	var tween: Tween = create_tween()
	tween.tween_property(self,"scale",Vector2(1.0,1.0),0.1)

func reveal_with_delay(delay: float) -> void:
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
	state = CellState.REVEALED
	_refresh_visual()
	scale = Vector2(1.3,1.3)
	var tween: Tween = create_tween()
	tween.tween_property(self,"scale",Vector2(1.0,1.0), 0.15)

func show_mine_revealed() -> void:
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
			
			if tex_hidden_cat:
				sprite.texture = tex_hidden_cat
			else:
				sprite.texture = null

		CellState.FLAGGED:
			tile_rect.color = Color(0.8, 0.8, 0.2)
			if tex_flag_icon:
				sprite.texture = tex_flag_icon
				number_label.text = ""
			else:
				sprite.texture = null
				number_label.text = "F"

		CellState.REVEALED:
			if has_mine:
				tile_rect.color = Color(0.6, 0, 0)
				if tex_mine_cat:
					sprite.texture = tex_mine_cat
					number_label.text = ""
				else:
					sprite.texture = null
					number_label.text = "X"
			else:
				tile_rect.color = Color(0.1, 0.3, 0.5)
				if tex_water:
					sprite.texture = tex_water
				else:
					sprite.texture = null
					
				if neighbour_count > 0:
					number_label.text = str(neighbour_count)
				else:
					number_label.text = ""
