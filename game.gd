extends Node2D

enum GameState { START, PLAYING, BOSS_INTRO, BOSS_FIGHT, VICTORY, GAME_OVER }

var current_state: GameState = GameState.START
var score: int = 0
var highscore: int = 0

var pipe_spawn_timer: float = 0.0
const PIPE_SPAWN_INTERVAL: float = 2.2
var pipes: Array[PipePair] = []

# Dark Souls / Flappy Souls variables
var boss: Area2D = null
var boss_hp_bar_container: Panel = null
var boss_hp_bar: ProgressBar = null
var boss_name_label: Label = null
var you_died_overlay: ColorRect = null
var you_died_label: Label = null
var victory_label: Label = null

# Progress HUD elements
var progress_container: Panel = null
var progress_indicator: ColorRect = null
var progress_text_label: Label = null

var estus_spawn_timer: float = 0.0
var enemy_spawn_timer: float = 0.0
const ESTUS_SPAWN_INTERVAL: float = 4.2
const ENEMY_SPAWN_INTERVAL: float = 3.6

var gargoyles: Array[Area2D] = []
var powerups: Array[Area2D] = []

var projectile_script = load("res://projectile.gd")

var boss_intro_timer: float = 0.0

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

	# Boss HP Bar Container (bottom of screen above ground)
	boss_hp_bar_container = Panel.new()
	boss_hp_bar_container.position = Vector2(40, 570)
	boss_hp_bar_container.size = Vector2(VIEWPORT_WIDTH - 80, 44)
	boss_hp_bar_container.hide()
	canvas_layer.add_child(boss_hp_bar_container)
	
	boss_name_label = Label.new()
	boss_name_label.text = "GWYN, LORD OF CINDER"
	boss_name_label.position = Vector2(0, 2)
	boss_name_label.size = Vector2(VIEWPORT_WIDTH - 80, 18)
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.add_theme_font_size_override("font_size", 11)
	boss_name_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.7))
	boss_hp_bar_container.add_child(boss_name_label)
	
	boss_hp_bar = ProgressBar.new()
	boss_hp_bar.show_percentage = false
	boss_hp_bar.position = Vector2(10, 22)
	boss_hp_bar.size = Vector2(VIEWPORT_WIDTH - 100, 14)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.65, 0.08, 0.08) # Crimson red
	boss_hp_bar.add_theme_stylebox_override("fill", sb)
	var sbbg = StyleBoxFlat.new()
	sbbg.bg_color = Color(0.1, 0.1, 0.1)
	boss_hp_bar.add_theme_stylebox_override("background", sbbg)
	boss_hp_bar_container.add_child(boss_hp_bar)
	
	# YOU DIED Overlay (Full screen semi-transparent black, fades in)
	you_died_overlay = ColorRect.new()
	you_died_overlay.color = Color(0.08, 0.0, 0.0, 0.0) # Translucent red/black
	you_died_overlay.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	you_died_overlay.hide()
	canvas_layer.add_child(you_died_overlay)
	
	you_died_label = Label.new()
	you_died_label.text = "YOU DIED"
	you_died_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	you_died_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	you_died_label.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	you_died_label.add_theme_font_size_override("font_size", 54)
	you_died_label.add_theme_color_override("font_color", Color(0.7, 0.08, 0.08)) # Crimson blood
	you_died_overlay.add_child(you_died_label)
	
	# VICTORY ACHIEVED Overlay
	victory_label = Label.new()
	victory_label.text = "VICTORY ACHIEVED"
	victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	victory_label.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	victory_label.add_theme_font_size_override("font_size", 40)
	victory_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.15)) # Gold
	victory_label.hide()
	canvas_layer.add_child(victory_label)

	# Progression HUD container (slim elegant desaturated gothic bar)
	progress_container = Panel.new()
	progress_container.size = Vector2(400, 32)
	progress_container.position = Vector2(40, 16)
	var sb_prog = StyleBoxFlat.new()
	sb_prog.bg_color = Color(0.06, 0.06, 0.08, 0.6)
	sb_prog.border_width_bottom = 1
	sb_prog.border_width_top = 1
	sb_prog.border_width_left = 1
	sb_prog.border_width_right = 1
	sb_prog.border_color = Color(0.24, 0.24, 0.28)
	sb_prog.corner_radius_top_left = 4
	sb_prog.corner_radius_bottom_right = 4
	progress_container.add_theme_stylebox_override("panel", sb_prog)
	canvas_layer.add_child(progress_container)

	var prog_line = ColorRect.new()
	prog_line.size = Vector2(340, 2)
	prog_line.position = Vector2(30, 22)
	prog_line.color = Color(0.18, 0.18, 0.22)
	progress_container.add_child(prog_line)

	progress_indicator = ColorRect.new()
	progress_indicator.size = Vector2(8, 8)
	progress_indicator.position = Vector2(30, 19)
	progress_indicator.color = Color(1.0, 0.5, 0.0) # Golden-orange ember slider
	progress_container.add_child(progress_indicator)

	progress_text_label = Label.new()
	progress_text_label.size = Vector2(400, 20)
	progress_text_label.position = Vector2(0, 2)
	progress_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_text_label.add_theme_font_size_override("font_size", 9)
	progress_text_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.82))
	progress_text_label.text = "PROGRESS: 0/100 | Target: Asylum Demon"
	progress_container.add_child(progress_text_label)

func _reset_game() -> void:
	# Clear old pipes
	for pipe in pipes:
		if is_instance_valid(pipe):
			pipe.queue_free()
	pipes.clear()
	
	# Clear old powerups
	for p in powerups:
		if is_instance_valid(p):
			p.queue_free()
	powerups.clear()
	
	# Clear old gargoyles
	for g in gargoyles:
		if is_instance_valid(g):
			g.queue_free()
	gargoyles.clear()
	
	# Clear projectiles & boss
	for child in get_children():
		if child.get_script() == projectile_script or child.name == "FlappyBoss":
			child.queue_free()
	if boss and is_instance_valid(boss):
		boss.queue_free()
	boss = null
	
	score = 0
	score_label.text = "0"
	score_label.hide()
	
	if progress_indicator:
		progress_indicator.position.x = 30
	if progress_text_label:
		progress_text_label.text = "PROGRESS: 0/100 | Target: Asylum Demon"
	
	# Reset timers
	estus_spawn_timer = 0.0
	enemy_spawn_timer = 0.0
	boss_intro_timer = 0.0
	
	# Instantiate bird
	if bird and is_instance_valid(bird):
		bird.queue_free()
	
	bird = Bird.new()
	bird.position = Vector2(120, 320)
	bird.hit_obstacle.connect(_on_bird_hit)
	
	# Collision Shape for Bird
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var circle = CircleShape2D.new()
	circle.radius = 14.0
	collision.shape = circle
	bird.add_child(collision)
	
	add_child(bird)
	
	# Reset UI Overlays
	if boss_hp_bar_container:
		boss_hp_bar_container.hide()
	if you_died_overlay:
		you_died_overlay.hide()
		you_died_overlay.color = Color(0.08, 0.0, 0.0, 0.0)
	if victory_label:
		victory_label.hide()
		victory_label.modulate = Color.WHITE
		
	current_state = GameState.START
	title_label.text = "FLAPPY SOULS"
	title_label.add_theme_color_override("font_color", Color(0.75, 0.2, 0.15)) # Souls dark red title!
	title_label.show()
	instruction_label.text = "TAP SPACE TO KINDLE THE FLAME\n(GET SCORE 6 TO FIGHT GWYN)"
	instruction_label.show()

func _start_game() -> void:
	current_state = GameState.PLAYING
	score_label.show()
	title_label.hide()
	instruction_label.hide()

func _physics_process(delta: float) -> void:
	# Update HUD progress bar slider and target text dynamically
	if progress_indicator and progress_text_label and bird and bird.is_alive:
		var progress_ratio = clamp(float(score) / 100.0, 0.0, 1.0)
		progress_indicator.position.x = 30.0 + (progress_ratio * 340.0) - 4.0
		
		var next_boss = "Asylum Demon"
		if score < 10: next_boss = "Asylum Demon"
		elif score < 20: next_boss = "Bell Gargoyle"
		elif score < 30: next_boss = "Capra Demon"
		elif score < 40: next_boss = "Gaping Dragon"
		elif score < 50: next_boss = "Chaos Witch Quelaag"
		elif score < 60: next_boss = "Wolf Sif"
		elif score < 70: next_boss = "Iron Golem"
		elif score < 80: next_boss = "Ornstein"
		elif score < 90: next_boss = "Gravelord Nito"
		else: next_boss = "Lord Gwyn"
		
		progress_text_label.text = "PROGRESS: %d/100 | Target: %s" % [score, next_boss]

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
				
			# Spawn Gargoyle enemies
			enemy_spawn_timer += delta
			if enemy_spawn_timer >= ENEMY_SPAWN_INTERVAL:
				enemy_spawn_timer = 0.0
				_spawn_gargoyle()
				
			# Spawn Estus Flask powerups
			estus_spawn_timer += delta
			if estus_spawn_timer >= ESTUS_SPAWN_INTERVAL:
				estus_spawn_timer = 0.0
				_spawn_estus_flask()
				
			# Check ground collision
			if bird.global_position.y >= GROUND_Y:
				bird.die()
				
			# Trigger progressive boss fights at score endings of 6 (6, 16, 26... up to 96)
			var score_mod = score % 10
			if score_mod == 6 and score < 100:
				current_state = GameState.BOSS_INTRO
				boss_intro_timer = 0.0
				shake_intensity = 6.0 # Earth rumbling intro!
				
		GameState.BOSS_INTRO:
			if Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				bird.flap()
				
			# Rumble screen continuously during entrance
			shake_intensity = max(shake_intensity, 3.0)
			
			boss_intro_timer += delta
			if boss_intro_timer >= 3.0:
				# Spawn Boss!
				var boss_script = load("res://boss.gd")
				boss = Area2D.new()
				boss.set_script(boss_script)
				boss.defeated.connect(_on_boss_defeated)
				boss.health_changed.connect(_on_boss_health_changed)
				
				# Calculate and set progressive boss tier
				var tier = (score / 10) + 1
				boss.set_tier(tier)
				
				add_child(boss)
				boss.start_boss()
				
				# Setup HP Bar values dynamically
				boss_hp_bar.max_value = boss.max_hp
				boss_hp_bar.value = boss.hp
				boss_name_label.text = boss.boss_name
				boss_hp_bar_container.show()
				
				current_state = GameState.BOSS_FIGHT
				shake_intensity = 12.0 # Huge shake on boss roar!
				
			if bird.global_position.y >= GROUND_Y:
				bird.die()
				
		GameState.BOSS_FIGHT:
			if Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				bird.flap()
				
			# Spawning powerups only (no pipes or gargoyles)
			estus_spawn_timer += delta
			if estus_spawn_timer >= ESTUS_SPAWN_INTERVAL:
				estus_spawn_timer = 0.0
				_spawn_estus_flask()
				
			if bird.global_position.y >= GROUND_Y:
				bird.die()
				
		GameState.VICTORY:
			if Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				_reset_game()
				
		GameState.GAME_OVER:
			if Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				_reset_game()

	# Clean up deleted reference lists
	var active_gargoyles: Array[Area2D] = []
	for g in gargoyles:
		if is_instance_valid(g):
			active_gargoyles.append(g)
	gargoyles = active_gargoyles
	
	var active_powerups: Array[Area2D] = []
	for p in powerups:
		if is_instance_valid(p):
			active_powerups.append(p)
	powerups = active_powerups

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
	
	# Scale obstacle movement difficulty based on current score
	if score < 10:
		pipe_instance.movement_type = 0 # Static gotic columns
	elif score < 30:
		# 50% chance of vertical bobbing columns
		pipe_instance.movement_type = randi() % 2
	elif score < 60:
		# Static, vertical bobbing, or horizontal sliding columns
		pipe_instance.movement_type = randi() % 3
	else:
		# Extreme stage: Static, vertical, horizontal, or complex diagonal swings!
		pipe_instance.movement_type = randi() % 4
		
	add_child(pipe_instance)
	pipes.append(pipe_instance)

func _spawn_gargoyle() -> void:
	var enemy_script = load("res://enemy.gd")
	var g = Area2D.new()
	g.set_script(enemy_script)
	g.position = Vector2(VIEWPORT_WIDTH + 80, randf_range(120, 520))
	g.defeated.connect(func():
		score += 1
		score_label.text = str(score)
	)
	add_child(g)
	gargoyles.append(g)

func _spawn_estus_flask() -> void:
	var powerup_script = load("res://powerup.gd")
	var p = Area2D.new()
	p.set_script(powerup_script)
	p.position = Vector2(VIEWPORT_WIDTH + 80, randf_range(160, 480))
	add_child(p)
	powerups.append(p)

func _on_boss_health_changed(new_hp: int, max_hp: int) -> void:
	boss_hp_bar.value = float(new_hp) / max_hp * 100.0

func _on_boss_defeated() -> void:
	# Hide boss bar and shake screen
	boss_hp_bar_container.hide()
	shake_intensity = 18.0
	
	var current_tier = (score / 10) + 1
	if current_tier < 10:
		# Mid-boss slain!
		# 1. Clear all active boss fireballs to make the screen safe
		for child in get_children():
			if child is Projectile and child.type != 0:
				child.queue_free()
				
		# 2. Grant +4 score bonus to reach the next X0 multiple
		score = ((score / 10) + 1) * 10
		score_label.text = str(score)
		
		# 3. Resume PLAYING state and reset timers
		current_state = GameState.PLAYING
		pipe_spawn_timer = 0.0
		enemy_spawn_timer = 0.0
		
		# 4. Briefly flash a Souls-style boss slain notification
		title_label.text = "%s SLAIN" % boss.boss_name
		title_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.15)) # Golden yellow
		title_label.show()
		var hide_title = create_tween()
		hide_title.tween_interval(2.5)
		hide_title.tween_callback(title_label.hide)
	else:
		# Final Boss Gwyn Slain! Full Victory!
		if current_state != GameState.VICTORY:
			current_state = GameState.VICTORY
			score = 100
			score_label.text = str(score)
			
			victory_label.show()
			victory_label.modulate.a = 0.0
			var tween = create_tween()
			tween.tween_property(victory_label, "modulate:a", 1.0, 1.8)
			
			if score > highscore:
				highscore = score
				
			instruction_label.text = "ALL BOSSES SLAIN! VICTORY ACHIEVED!\nTAP SPACE TO PLAY AGAIN"
			instruction_label.show()

func _on_pipe_scored() -> void:
	score += 1
	score_label.text = str(score)
	
	# Subtle bounce animation on score UI
	var tween = create_tween()
	tween.tween_property(score_label, "scale", Vector2(1.2, 1.2), 0.08)
	tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.08)

func _on_bird_hit() -> void:
	if current_state != GameState.GAME_OVER and current_state != GameState.VICTORY:
		current_state = GameState.GAME_OVER
		shake_intensity = 18.0 # High impact screen shake!
		
		# Stop all pipes and obstacles
		for p in pipes:
			if is_instance_valid(p):
				p.is_active = false
		for g in gargoyles:
			if is_instance_valid(g):
				g.speed = 0.0
		for p in powerups:
			if is_instance_valid(p):
				# stop bobbing or moving
				p.set_physics_process(false)
				
		# Dark Souls Cinematic YOU DIED overlay fade-in
		you_died_overlay.show()
		var fade = create_tween()
		fade.tween_property(you_died_overlay, "color", Color(0.08, 0.0, 0.0, 0.75), 1.8)
		
		if score > highscore:
			highscore = score
			
		title_label.hide() # Hide normal GAME OVER
		instruction_label.text = "SCORE: %d | HIGH: %d\nTAP SPACE TO RETRY" % [score, highscore]
		instruction_label.add_theme_color_override("font_color", Color.WHITE)
		instruction_label.show()

# MCP Command Handlers
func _on_mcp_flap() -> void:
	if current_state in [GameState.PLAYING, GameState.BOSS_INTRO, GameState.BOSS_FIGHT]:
		bird.flap()
	elif current_state == GameState.START:
		_start_game()
		bird.flap()

func _on_mcp_restart() -> void:
	if current_state in [GameState.GAME_OVER, GameState.VICTORY]:
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
			
	# Find nearest gargoyle
	var next_gargoyle_x: float = -999.0
	var next_gargoyle_y: float = -999.0
	for g in gargoyles:
		if is_instance_valid(g) and g.position.x + 15 > bird.position.x:
			next_gargoyle_x = g.position.x
			next_gargoyle_y = g.position.y
			break
			
	# Find nearest Estus powerup
	var next_estus_x: float = -999.0
	var next_estus_y: float = -999.0
	for p in powerups:
		if is_instance_valid(p) and p.position.x + 16 > bird.position.x:
			next_estus_x = p.position.x
			next_estus_y = p.position.y
			break

	var state_payload = {
		"type": "state",
		"game_state": GameState.keys()[current_state],
		"score": score,
		"highscore": highscore,
		"bird_y": bird.position.y if bird else 0.0,
		"bird_vy": bird.velocity.y if bird else 0.0,
		"bird_alive": bird.is_alive if bird else false,
		"is_kindled": bird.is_kindled if bird else false,
		"powerup_ammo": bird.powerup_ammo if bird else 0,
		"next_pipe_x": next_pipe_x,
		"next_pipe_top_y": next_pipe_top_y,
		"next_pipe_bottom_y": next_pipe_bottom_y,
		"next_gargoyle_x": next_gargoyle_x,
		"next_gargoyle_y": next_gargoyle_y,
		"next_estus_x": next_estus_x,
		"next_estus_y": next_estus_y,
		"boss_hp": boss.hp if is_instance_valid(boss) else -1,
		"boss_max_hp": boss.max_hp if is_instance_valid(boss) else -1,
		"boss_x": boss.position.x if is_instance_valid(boss) else -1.0,
		"boss_y": boss.position.y if is_instance_valid(boss) else -1.0,
		"ground_y": GROUND_Y
	}
	
	mcp_client.send_payload(state_payload)

# Draw gorgeous gradient background & parallax sky procedurally
func _draw() -> void:
	# Dark Gothic Sky Gradient (Sunset of Lordran style)
	for y in range(0, int(GROUND_Y)):
		var t = float(y) / GROUND_Y
		var sky_color = lerp(Color(0.08, 0.06, 0.12), Color(0.24, 0.08, 0.14), t)
		draw_line(Vector2(0, y), Vector2(VIEWPORT_WIDTH, y), sky_color)
		
	# Draw Ruined Gothic Spire and Castle silhouettes in background
	var ruins_color = Color(0.05, 0.04, 0.07)
	var r_pts = PackedVector2Array([
		Vector2(0, GROUND_Y),
		Vector2(0, GROUND_Y - 40),
		# Left Spire Tower
		Vector2(30, GROUND_Y - 40),
		Vector2(40, GROUND_Y - 160),
		Vector2(55, GROUND_Y - 220), # Spire tip
		Vector2(70, GROUND_Y - 160),
		Vector2(80, GROUND_Y - 40),
		# Battlement wall
		Vector2(110, GROUND_Y - 40),
		Vector2(110, GROUND_Y - 80),
		Vector2(130, GROUND_Y - 80),
		Vector2(130, GROUND_Y - 60),
		Vector2(150, GROUND_Y - 60),
		Vector2(150, GROUND_Y - 80),
		Vector2(170, GROUND_Y - 80),
		Vector2(170, GROUND_Y - 40),
		# Mid Spire
		Vector2(220, GROUND_Y - 40),
		Vector2(235, GROUND_Y - 130),
		Vector2(245, GROUND_Y - 160), # Small spire tip
		Vector2(255, GROUND_Y - 130),
		Vector2(270, GROUND_Y - 40),
		# Right Ruined Spire
		Vector2(330, GROUND_Y - 40),
		Vector2(340, GROUND_Y - 150),
		Vector2(365, GROUND_Y - 200), # Cracked spire
		Vector2(375, GROUND_Y - 120),
		Vector2(390, GROUND_Y - 40),
		Vector2(VIEWPORT_WIDTH, GROUND_Y - 40),
		Vector2(VIEWPORT_WIDTH, GROUND_Y)
	])
	draw_colored_polygon(r_pts, ruins_color)

	# Draw Ground (Ash-grey dirt + dark stone border + glowing ember crack)
	draw_rect(Rect2(0, GROUND_Y, VIEWPORT_WIDTH, VIEWPORT_HEIGHT - GROUND_Y), Color(0.13, 0.13, 0.15)) # Ash dirt
	draw_rect(Rect2(0, GROUND_Y, VIEWPORT_WIDTH, 12), Color(0.08, 0.08, 0.1)) # Dark boundary
	draw_rect(Rect2(0, GROUND_Y + 12, VIEWPORT_WIDTH, 4), Color(0.04, 0.04, 0.05)) # Accent shadow shadow
	
	# Glowing ember cracks in the ashen ground
	draw_line(Vector2(0, GROUND_Y + 30), Vector2(140, GROUND_Y + 34), Color(0.9, 0.35, 0.02), 2.0)
	draw_line(Vector2(140, GROUND_Y + 34), Vector2(280, GROUND_Y + 28), Color(0.9, 0.35, 0.02), 1.5)
	draw_line(Vector2(280, GROUND_Y + 28), Vector2(VIEWPORT_WIDTH, GROUND_Y + 36), Color(0.9, 0.35, 0.02), 2.5)
