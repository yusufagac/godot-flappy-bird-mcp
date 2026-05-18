extends Node2D
class_name PipePair

signal scored

const SPEED: float = 180.0
const GAP_SIZE: float = 160.0
const PIPE_WIDTH: float = 64.0

var gap_y: float = 360.0 # Vertical center of the pipe gap
var is_active: bool = true
var score_recorded: bool = false
var bird_ref: Node2D = null

# Dynamic movement variables
var movement_type: int = 0 # 0 = Static, 1 = Vertical, 2 = Horizontal, 3 = Diagonal
var movement_speed: float = 2.2
var movement_range: float = 50.0
var initial_y: float = 0.0
var time_passed: float = 0.0

func _ready() -> void:
	initial_y = position.y
	# Add Area2D components dynamically for collisions
	_setup_collision_areas()

func _physics_process(delta: float) -> void:
	if not is_active:
		return

	time_passed += delta
	
	# Horizontal scroll
	position.x -= SPEED * delta
	
	# Apply dynamic secondary movement
	match movement_type:
		1: # Vertical bobbing
			position.y = initial_y + sin(time_passed * movement_speed) * movement_range
		2: # Horizontal squeeze sliding
			position.x += cos(time_passed * movement_speed * 1.5) * 1.2
		3: # Diagonal orbit movement
			position.y = initial_y + sin(time_passed * movement_speed) * movement_range
			position.x += cos(time_passed * movement_speed * 1.5) * 1.0
	
	# Delete once off screen
	if position.x < -100:
		queue_free()

	# Score tracking
	if not score_recorded and bird_ref and is_instance_valid(bird_ref):
		if bird_ref.global_position.x > global_position.x:
			score_recorded = true
			scored.emit()

func _setup_collision_areas() -> void:
	# Top Pipe Area
	var top_area = Area2D.new()
	top_area.name = "TopPipe"
	var top_shape = CollisionShape2D.new()
	var top_box = RectangleShape2D.new()
	top_box.size = Vector2(PIPE_WIDTH, 800)
	top_shape.shape = top_box
	top_shape.position = Vector2(0, -400 - (GAP_SIZE / 2.0))
	top_area.add_child(top_shape)
	add_child(top_area)
	top_area.body_entered.connect(_on_bird_entered)

	# Bottom Pipe Area
	var bottom_area = Area2D.new()
	bottom_area.name = "BottomPipe"
	var bottom_shape = CollisionShape2D.new()
	var bottom_box = RectangleShape2D.new()
	bottom_box.size = Vector2(PIPE_WIDTH, 800)
	bottom_shape.shape = bottom_box
	bottom_shape.position = Vector2(0, 400 + (GAP_SIZE / 2.0))
	bottom_area.add_child(bottom_shape)
	add_child(bottom_area)
	bottom_area.body_entered.connect(_on_bird_entered)

func _on_bird_entered(body: Node2D) -> void:
	if body is Bird:
		body.die()

# Procedural drawing of beautiful premium dark gothic stone columns
func _draw() -> void:
	# Gothic/Souls Dark Stone Colors
	var stone_dark = Color(0.14, 0.14, 0.17)
	var stone_light = Color(0.26, 0.26, 0.3)
	var stone_shadow = Color(0.06, 0.06, 0.08)
	var lava_glow = Color(0.9, 0.35, 0.02) # Fiery orange glow in cracks
	
	# Top Pipe boundary
	var top_bottom_y = -GAP_SIZE / 2.0
	
	# Draw Top Column (Dark weathered stone)
	draw_rect(Rect2(-PIPE_WIDTH/2.0, -1000, PIPE_WIDTH, 1000 + top_bottom_y - 24), stone_dark)
	# Highlights & Shadows
	draw_rect(Rect2(-PIPE_WIDTH/2.0, -1000, 4, 1000 + top_bottom_y - 24), stone_light)
	draw_rect(Rect2(PIPE_WIDTH/2.0 - 6, -1000, 6, 1000 + top_bottom_y - 24), stone_shadow)
	
	# Weathered Brick Lines (Horizontal cracks)
	var h_cracks = [top_bottom_y - 80, top_bottom_y - 180, top_bottom_y - 300, top_bottom_y - 450]
	for h in h_cracks:
		if h < top_bottom_y - 24:
			draw_line(Vector2(-PIPE_WIDTH/2.0, h), Vector2(PIPE_WIDTH/2.0, h), stone_light, 1.5)
			# Random fiery cracks
			draw_line(Vector2(-PIPE_WIDTH/4.0, h), Vector2(0, h + 8), lava_glow, 2.0)
			draw_line(Vector2(0, h + 8), Vector2(PIPE_WIDTH/3.0, h + 2), lava_glow, 1.5)

	# Draw Gothic Top Capital
	draw_rect(Rect2(-PIPE_WIDTH/2.0 - 8, top_bottom_y - 24, PIPE_WIDTH + 16, 24), stone_light)
	draw_rect(Rect2(-PIPE_WIDTH/2.0 - 4, top_bottom_y - 20, PIPE_WIDTH + 8, 16), stone_dark)
	# Draw Glowing Rune/Crest in the center of the capital
	draw_circle(Vector2(0, top_bottom_y - 12), 6.0, lava_glow)
	draw_circle(Vector2(0, top_bottom_y - 12), 3.0, Color.YELLOW)
	
	# Bottom Pipe boundary
	var bottom_top_y = GAP_SIZE / 2.0
	
	# Draw Bottom Column
	draw_rect(Rect2(-PIPE_WIDTH/2.0, bottom_top_y + 24, PIPE_WIDTH, 1000), stone_dark)
	draw_rect(Rect2(-PIPE_WIDTH/2.0, bottom_top_y + 24, 4, 1000), stone_light)
	draw_rect(Rect2(PIPE_WIDTH/2.0 - 6, bottom_top_y + 24, 6, 1000), stone_shadow)
	
	# Weathered Brick Lines for Bottom
	var b_cracks = [bottom_top_y + 80, bottom_top_y + 180, bottom_top_y + 300, bottom_top_y + 450]
	for h in b_cracks:
		draw_line(Vector2(-PIPE_WIDTH/2.0, h), Vector2(PIPE_WIDTH/2.0, h), stone_light, 1.5)
		draw_line(Vector2(-PIPE_WIDTH/3.0, h), Vector2(-10, h - 10), lava_glow, 2.0)
		draw_line(Vector2(-10, h - 10), Vector2(PIPE_WIDTH/4.0, h - 4), lava_glow, 1.5)
		
	# Draw Gothic Bottom Capital
	draw_rect(Rect2(-PIPE_WIDTH/2.0 - 8, bottom_top_y, PIPE_WIDTH + 16, 24), stone_light)
	draw_rect(Rect2(-PIPE_WIDTH/2.0 - 4, bottom_top_y + 4, PIPE_WIDTH + 8, 16), stone_dark)
	# Glowing Rune
	draw_circle(Vector2(0, bottom_top_y + 12), 6.0, lava_glow)
	draw_circle(Vector2(0, bottom_top_y + 12), 3.0, Color.YELLOW)
