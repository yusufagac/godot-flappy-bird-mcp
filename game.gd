extends Node2D

enum GameState { START, PLAYING, GAME_OVER }

var current_state: GameState = GameState.START
var score: int = 0
var highscore: int = 0

var pipe_spawn_timer: float = 0.0
const PIPE_SPAWN_INTERVAL: float = 2.0
var pipes: Array[PipePair] = []

# Viewport bounds
const VIEWPORT_WIDTH: float = 480.0
const VIEWPORT_HEIGHT: float = 720.0
const GROUND_Y: float = 640.0

# Node references
var bird: Bird = null
var mcp_client: MCPClient = null

# UI elements
var score_label: Label = null
var instruction_label: Label = null
var title_label: Label = null
var mcp_status_indicator: ColorRect = null
var mcp_status_label: Label = null

# Screen shake variables
var shake_intensity: float = 0.0
var shake_decay: float = 12.0
var original_camera_pos: Vector2 = Vector2.ZERO
var camera: Camera2D = null

func _ready() -> void:
	# Add Camera
	camera = Camera2D.new()
	camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(camera)
	original_camera_pos = camera.position

	# Setup MCP Client Autoload or Child
	mcp_client = MCPClient.new()
	add_child(mcp_client)
	
	# Connect MCP commands
	mcp_client.command_flap.connect(_on_mcp_flap)
	mcp_client.command_restart.connect(_on_mcp_restart)
	mcp_client.command_pause.connect(_on_mcp_pause)
	mcp_client.command_resume.connect(_on_mcp_resume)

	# Build Game UI programmatically for robust setup without scene edits
	_setup_ui()
	_reset_game()

func _setup_ui() -> void:
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)

	# Title Label
	title_label = Label.new()
	title_label.text = "FLAPPY BIRD\nMCP"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector2(0, 140)
	title_label.size = Vector2(VIEWPORT_WIDTH, 100)
	title_label.add_theme_font_size_override("font_size", 42)
	canvas_layer.add_child(title_label)

	# Instructions Label
	instruction_label = Label.new()
	instruction_label.text = "PRESS SPACE OR CLICK TO START"
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.position = Vector2(0, 420)
	instruction_label.size = Vector2(VIEWPORT_WIDTH, 40)
	instruction_label.add_theme_font_size_override("font_size", 18)
	canvas_layer.add_child(instruction_label)

	# Score Label
	score_label = Label.new()
	score_label.text = "0"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.position = Vector2(0, 40)
	score_label.size = Vector2(VIEWPORT_WIDTH, 80)
	score_label.add_theme_font_size_override("font_size", 64)
	score_label.hide()
	canvas_layer.add_child(score_label)

	# MCP Status Area
	var mcp_container = Panel.new()
	mcp_container.position = Vector2(16, VIEWPORT_HEIGHT - 48)
	mcp_container.size = Vector2(180, 32)
	canvas_layer.add_child(mcp_container)

	mcp_status_indicator = ColorRect.new()
	mcp_status_indicator.color = Color.RED
	mcp_status_indicator.position = Vector2(10, 10)
	mcp_status_indicator.size = Vector2(12, 12)
	mcp_container.add_child(mcp_status_indicator)

	mcp_status_label = Label.new()
	mcp_status_label.text = "MCP DISCONNECTED"
	mcp_status_label.position = Vector2(30, 4)
	mcp_status_label.add_theme_font_size_override("font_size", 11)
	mcp_container.add_child(mcp_status_label)

func _reset_game() -> void:
	# Clear old pipes
	for pipe in pipes:
		if is_instance_valid(pipe):
			pipe.queue_free()
	pipes.clear()
	
	score = 0
	score_label.text = "0"
	score_label.hide()
	
	# Instantiate bird
	if bird and is_instance_valid(bird):
		bird.queue_free()
	
	bird = Bird.new()
	bird.position = Vector2(120, 320)
	bird.hit_obstacle.connect(_on_bird_hit)
	
	# Collision Shape for Bird
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 14.0
	collision.shape = circle
	bird.add_child(collision)
	
	add_child(bird)
	
	current_state = GameState.START
	title_label.text = "FLAPPY BIRD\nMCP"
	title_label.show()
	instruction_label.text = "PRESS SPACE OR CLICK TO START"
	instruction_label.show()

func _start_game() -> void:
	current_state = GameState.PLAYING
	score_label.show()
	title_label.hide()
	instruction_label.hide()

func _physics_process(delta: float) -> void:
	# Process screen shake
	if shake_intensity > 0:
		shake_intensity = lerp(shake_intensity, 0.0, shake_decay * delta)
		camera.position = original_camera_pos + Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	else:
		camera.position = original_camera_pos

	# State Management
	match current_state:
		GameState.START:
			if Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				_start_game()
				bird.flap()
				
		GameState.PLAYING:
			if Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				bird.flap()
				
			# Spawn Pipes
			pipe_spawn_timer += delta
			if pipe_spawn_timer >= PIPE_SPAWN_INTERVAL:
				pipe_spawn_timer = 0.0
				_spawn_pipe_pair()
				
			# Check ground collision
			if bird.global_position.y >= GROUND_Y:
				bird.die()
				
		GameState.GAME_OVER:
			if Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				_reset_game()

	# Update MCP Status UI
	if mcp_client.is_connected_to_server:
		mcp_status_indicator.color = Color.GREEN
		mcp_status_label.text = "MCP CONNECTED"
	else:
		mcp_status_indicator.color = Color.RED
		mcp_status_label.text = "MCP DISCONNECTED"

	# Send State over MCP WebSocket
	_send_mcp_state()

func _spawn_pipe_pair() -> void:
	var pipe_script = load("res://pipe.gd")
	var pipe_instance = Node2D.new()
	pipe_instance.set_script(pipe_script)
	
	# Spawn off screen
	pipe_instance.position = Vector2(VIEWPORT_WIDTH + 80, 0)
	
	# Randomize Gap center
	var random_gap = randf_range(200, 480)
	pipe_instance.gap_y = random_gap
	pipe_instance.bird_ref = bird
	pipe_instance.scored.connect(_on_pipe_scored)
	
	# Position shapes relative to the gap center
	pipe_instance.position.y = random_gap
	
	add_child(pipe_instance)
	pipes.append(pipe_instance)

func _on_pipe_scored() -> void:
	score += 1
	score_label.text = str(score)
	
	# Subtle bounce animation on score UI
	var tween = create_tween()
	tween.tween_property(score_label, "scale", Vector2(1.2, 1.2), 0.08)
	tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.08)

func _on_bird_hit() -> void:
	if current_state != GameState.GAME_OVER:
		current_state = GameState.GAME_OVER
		shake_intensity = 15.0 # Screen shake trigger!
		
		# Stop all pipes scrolling
		for p in pipes:
			if is_instance_valid(p):
				p.is_active = false
				
		if score > highscore:
			highscore = score
			
		title_label.text = "GAME OVER"
		title_label.show()
		instruction_label.text = "SCORE: %d | HIGH: %d\nCLICK TO RESTART" % [score, highscore]
		instruction_label.show()

# MCP Command Handlers
func _on_mcp_flap() -> void:
	if current_state == GameState.PLAYING:
		bird.flap()
	elif current_state == GameState.START:
		_start_game()
		bird.flap()

func _on_mcp_restart() -> void:
	if current_state == GameState.GAME_OVER:
		_reset_game()

func _on_mcp_pause() -> void:
	get_tree().paused = true

func _on_mcp_resume() -> void:
	get_tree().paused = false

func _send_mcp_state() -> void:
	if not mcp_client or not mcp_client.is_connected_to_server:
		return
		
	# Find next incoming pipe
	var next_pipe_x: float = -999.0
	var next_pipe_top_y: float = -999.0
	var next_pipe_bottom_y: float = -999.0
	
	for pipe in pipes:
		if is_instance_valid(pipe) and pipe.position.x + 32 > bird.position.x:
			next_pipe_x = pipe.position.x
			next_pipe_top_y = pipe.gap_y - (pipe.GAP_SIZE / 2.0)
			next_pipe_bottom_y = pipe.gap_y + (pipe.GAP_SIZE / 2.0)
			break
			
	var state_payload = {
		"type": "state",
		"game_state": GameState.keys()[current_state],
		"score": score,
		"highscore": highscore,
		"bird_y": bird.position.y if bird else 0.0,
		"bird_vy": bird.velocity.y if bird else 0.0,
		"bird_alive": bird.is_alive if bird else false,
		"next_pipe_x": next_pipe_x,
		"next_pipe_top_y": next_pipe_top_y,
		"next_pipe_bottom_y": next_pipe_bottom_y,
		"ground_y": GROUND_Y
	}
	
	mcp_client.send_payload(state_payload)

# Draw gorgeous gradient background & parallax sky procedurally
func _draw() -> void:
	# Beautiful Sky Gradient (Sunset style)
	for y in range(0, int(GROUND_Y)):
		var t = float(y) / GROUND_Y
		var sky_color = lerp(Color(0.24, 0.45, 0.72), Color(0.65, 0.42, 0.65), t)
		draw_line(Vector2(0, y), Vector2(VIEWPORT_WIDTH, y), sky_color)
		
	# Draw rolling landscape (procedural hills)
	var hill_color = Color(0.22, 0.53, 0.3)
	var points = PackedVector2Array()
	points.append(Vector2(0, GROUND_Y))
	for x in range(0, int(VIEWPORT_WIDTH) + 10, 10):
		var hill_y = GROUND_Y - 20.0 + sin(x * 0.02) * 10.0 + cos(x * 0.007) * 4.0
		points.append(Vector2(x, hill_y))
	points.append(Vector2(VIEWPORT_WIDTH, GROUND_Y))
	draw_colored_polygon(points, hill_color)

	# Draw Ground (Brown dirt block + green grass boundary)
	draw_rect(Rect2(0, GROUND_Y, VIEWPORT_WIDTH, VIEWPORT_HEIGHT - GROUND_Y), Color(0.5, 0.35, 0.2)) # Dirt
	draw_rect(Rect2(0, GROUND_Y, VIEWPORT_WIDTH, 12), Color(0.28, 0.64, 0.34)) # Grass outline
	draw_rect(Rect2(0, GROUND_Y + 12, VIEWPORT_WIDTH, 4), Color(0.18, 0.48, 0.24)) # Accent dark grass shadow
