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

func _ready() -> void:
	# Add Area2D components dynamically for collisions
	_setup_collision_areas()

func _physics_process(delta: float) -> void:
	if not is_active:
		return

	position.x -= SPEED * delta
	
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

# Procedural drawing of beautiful premium retro/modern green pipes
func _draw() -> void:
	# Colors
	var dark_green = Color(0.2, 0.6, 0.25)
	var light_green = Color(0.35, 0.75, 0.4)
	var shadow_green = Color(0.12, 0.45, 0.18)
	var cap_color = Color(0.4, 0.8, 0.45)
	
	# Top Pipe boundary
	var top_bottom_y = -GAP_SIZE / 2.0
	
	# Bottom Pipe boundary
	var bottom_top_y = GAP_SIZE / 2.0
	
	# Draw Top Pipe (Sleek Pillar)
	draw_rect(Rect2(-PIPE_WIDTH/2.0, -1000, PIPE_WIDTH, 1000 + top_bottom_y - 24), dark_green)
	# Accent highlight line
	draw_rect(Rect2(-PIPE_WIDTH/2.0 + 4, -1000, 8, 1000 + top_bottom_y - 24), light_green)
	# Shadow edge
	draw_rect(Rect2(PIPE_WIDTH/2.0 - 12, -1000, 12, 1000 + top_bottom_y - 24), shadow_green)
	
	# Draw Top Pipe Cap
	draw_rect(Rect2(-PIPE_WIDTH/2.0 - 6, top_bottom_y - 24, PIPE_WIDTH + 12, 24), cap_color)
	draw_rect(Rect2(-PIPE_WIDTH/2.0 - 4, top_bottom_y - 22, 6, 20), Color.WHITE)
	draw_rect(Rect2(PIPE_WIDTH/2.0 + 2, top_bottom_y - 22, 4, 20), shadow_green)
	
	# Draw Bottom Pipe (Sleek Pillar)
	draw_rect(Rect2(-PIPE_WIDTH/2.0, bottom_top_y + 24, PIPE_WIDTH, 1000), dark_green)
	# Accent highlight line
	draw_rect(Rect2(-PIPE_WIDTH/2.0 + 4, bottom_top_y + 24, 8, 1000), light_green)
	# Shadow edge
	draw_rect(Rect2(PIPE_WIDTH/2.0 - 12, bottom_top_y + 24, 12, 1000), shadow_green)
	
	# Draw Bottom Pipe Cap
	draw_rect(Rect2(-PIPE_WIDTH/2.0 - 6, bottom_top_y, PIPE_WIDTH + 12, 24), cap_color)
	draw_rect(Rect2(-PIPE_WIDTH/2.0 - 4, bottom_top_y + 2, 6, 20), Color.WHITE)
	draw_rect(Rect2(PIPE_WIDTH/2.0 + 2, bottom_top_y + 2, 4, 20), shadow_green)
