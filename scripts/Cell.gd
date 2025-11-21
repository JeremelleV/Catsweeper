extends Node2D

enum CellState { HIDDEN, REVEALED, FLAGGED }

var coord: Vector2i
var has_mine: bool = false
var neighbour_count: int = 0
var state: CellState = CellState.HIDDEN

@onready var tile_rect: ColorRect = $TileRect
@onready var number_label: Label = $TileRect/NumberLabel
@onready var background: Sprite2D = $Background
@onready var foreground: AnimatedSprite2D = $Foreground

@export var tex_hidden_cat: Texture2D
@export var tex_water: Texture2D
@export var tex_mine_cat: Texture2D
@export var tex_flag_icon: Texture2D

func setup(x: int, y: int, size: int) -> void:
	coord = Vector2i(x, y)
	position = Vector2(x * size, y * size)

	tile_rect.size = Vector2(size, size)

	# Background & foreground both align to top-left of the cell
	background.position = Vector2(0, 0)
	foreground.position = Vector2(0, 0)

	_refresh_visual()

func reveal() -> void:
	if state == CellState.REVEALED:
		return
		
	state = CellState.REVEALED
	_refresh_visual()

	if has_mine:
		if foreground:
			scale = Vector2(1.2,1.2)
			var tween: Tween = create_tween()
			tween.tween_property(self,"scale",Vector2(1.0,1.0),0.1)
	else:
		_play_sink_animation()

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
	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
		
	# Start from normal
	background.modulate = Color(1,1,1,1)
	
	# Tween to a yellowish tint 
	tween.tween_property(
		background,
		"modulate",
		Color(1.2,1.2,0.4,1.0),
		0.15
	)

func _refresh_visual() -> void:
	if tex_water:
		background.texture = tex_water
	else:
		background.texture = null
	background.modulate = Color(1, 1, 1, 1)

	match state:
		CellState.HIDDEN:
			tile_rect.color = Color(0, 0, 0, 0) 
			number_label.text = ""

			if foreground.sprite_frames and foreground.sprite_frames.has_animation("idle"):
				foreground.play("idle")
				foreground.visible = true

		CellState.FLAGGED:
			tile_rect.color = Color(0, 0, 0, 0)
			number_label.text = ""

			if tex_flag_icon:
				foreground.stop()
				foreground.visible = true
				foreground.frame = 0

		CellState.REVEALED:
			tile_rect.color = Color(0, 0, 0, 0) 

			if has_mine:
				number_label.text = ""
				if tex_mine_cat:
					foreground.stop()
					foreground.visible = true
					foreground.frame = 0
					foreground.play("mine")
					foreground.visible = true

			else:
				if neighbour_count > 0:
					number_label.text = str(neighbour_count)
				else:
					number_label.text = ""

func _play_sink_animation() -> void:
	if foreground == null or foreground.sprite_frames == null:
		return
		
	if not foreground.sprite_frames.has_animation("sink"):
		return
		
	foreground.visible = true
	foreground.play("sink")
	
	foreground.animation_finished.connect(
		Callable(self,"_on_sink_animation_finished"),
		CONNECT_ONE_SHOT
	)

func _on_sink_animation_finished() -> void:
	if foreground.animation == "sink":
		foreground.visible = false
		foreground.stop()
		foreground.animation = "idle"
		foreground.frame = 0

func _clear_foreground() -> void:
	foreground.texture = null
	foreground.position = Vector2(0,0)
	foreground.modulate = Color(1,1,1,1)
