extends Area2D
class_name FlappyBoss

signal defeated
signal health_changed(new_hp, max_hp)

var max_hp: int = 100
var hp: int = 100
var active: bool = false
var intro_completed: bool = false

var base_y: float = 300.0
var lifetime: float = 0.0
var wing_timer: float = 0.0
var jaw_open_amount: float = 0.0

# Timers
var attack_timer: float = 0.0
var special_attack_timer: float = 0.0
var dash_timer: float = 0.0

var is_dashing: bool = false
var dash_stage: int = 0  # 0 = normal, 1 = windup, 2 = dash, 3 = retreat
var dash_x_target: float = 360.0

var projectile_script = load("res://projectile.gd")

func _ready() -> void:
	name = "FlappyBoss"
	# Add programmatic collision shape (large box for the boss)
	var col = CollisionShape2D.new()
	var box = RectangleShape2D.new()
	box.size = Vector2(80, 110)
	col.shape = box
	add_child(col)
	
	# Initial position off-screen right
	position = Vector2(620, 320)
	
	body_entered.connect(_on_body_entered)

func start_boss() -> void:
	active = true
	# Tween to enter screen
	var tween = create_tween()
	tween.tween_property(self, "position:x", 360.0, 3.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): intro_completed = true)

func take_damage(amount: int) -> void:
	if not active or not intro_completed:
		return
	
	hp = max(0, hp - amount)
	health_changed.emit(hp, max_hp)
	
	# Flash red on damage
	modulate = Color(1.5, 0.4, 0.4, 1.0)
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color.WHITE, 0.15)
	
	if hp <= 0:
		die()

func die() -> void:
	active = false
	defeated.emit()
	
	# Death explosion scaling effect
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

func _physics_process(delta: float) -> void:
	if not active:
		return
		
	lifetime += delta
	wing_timer += delta * 8.0
	
	# 1. Hovering (only when not dashing)
	if not is_dashing:
		position.y = base_y + sin(lifetime * 2.2) * 35.0
	
	if not intro_completed:
		return
		
	# 2. Attack Cycles
	attack_timer += delta
	special_attack_timer += delta
	dash_timer += delta
	
	# Regular fireball attack (every 2.8 seconds)
	if attack_timer >= 2.8 and not is_dashing:
		attack_timer = 0.0
		_shoot_fireball()
		
	# Triple fire breath burst (every 6.2 seconds)
	if special_attack_timer >= 6.2 and not is_dashing:
		special_attack_timer = 0.0
		_fire_breath_burst()
		
	# Charge Dash attack (every 11.5 seconds)
	if dash_timer >= 11.5 and not is_dashing:
		dash_timer = 0.0
		_start_dash_attack()
		
	# Process Dash States
	if is_dashing:
		_process_dash(delta)
		
	queue_redraw()

func _shoot_fireball() -> void:
	# Open jaw
	var tween = create_tween()
	tween.tween_property(self, "jaw_open_amount", 10.0, 0.12)
	tween.tween_property(self, "jaw_open_amount", 0.0, 0.12).set_delay(0.2)
	
	# Spawn projectile after slight delay
	var proj = Area2D.new()
	proj.set_script(projectile_script)
	proj.type = 1 # ProjectileType.DARK_FIREBALL
	proj.direction = -1.0 # Fire left
	proj.position = global_position + Vector2(-36, 12)
	get_parent().add_child(proj)

func _fire_breath_burst() -> void:
	# Open jaw wide
	var tween = create_tween()
	tween.tween_property(self, "jaw_open_amount", 14.0, 0.15)
	
	# Spawn 3 fireballs sequentially
	for i in range(3):
		var fire_tween = create_tween()
		fire_tween.tween_callback(func():
			var proj = Area2D.new()
			proj.set_script(projectile_script)
			proj.type = 1 # ProjectileType.DARK_FIREBALL
			proj.direction = -1.0
			proj.speed = 360.0 + (i * 50.0) # Variable speeds
			proj.position = global_position + Vector2(-36, 12)
			proj.position.y += randf_range(-16, 16) # Y spread
			get_parent().add_child(proj)
		).set_delay(0.25 * i)
		
	tween.tween_property(self, "jaw_open_amount", 0.0, 0.15).set_delay(1.0)

func _start_dash_attack() -> void:
	is_dashing = true
	dash_stage = 1 # Windup
	
	# Windup: Shake and pull back right
	var tween = create_tween()
	tween.tween_property(self, "position:x", 410.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		# Dash forward left!
		dash_stage = 2
		var dash_tween = create_tween()
		dash_tween.tween_property(self, "position:x", 80.0, 0.55).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		dash_tween.tween_callback(func():
			# Retreat slowly
			dash_stage = 3
			var retreat_tween = create_tween()
			retreat_tween.tween_property(self, "position:x", 360.0, 1.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			retreat_tween.tween_callback(func():
				is_dashing = false
				dash_stage = 0
			)
		)
	)

func _process_dash(delta: float) -> void:
	# Flap wings faster during dash
	wing_timer += delta * 12.0
	if dash_stage == 2:
		jaw_open_amount = 12.0
	elif dash_stage == 3:
		jaw_open_amount = move_toward(jaw_open_amount, 0.0, delta * 30.0)

func _on_body_entered(body: Node2D) -> void:
	if body is Bird:
		body.die()

func _draw() -> void:
	var wing_angle = sin(wing_timer) * 0.6
	
	# Colors
	var dark_body = Color(0.12, 0.12, 0.15)
	var horn_color = Color(0.24, 0.24, 0.28)
	var magma_glow = Color(0.9, 0.25, 0.02) # Lava core glow
	var wing_color = Color(0.08, 0.08, 0.10)
	
	# Draw Huge Dragon Wings in background (layered behind body)
	var right_wing = PackedVector2Array([
		Vector2(10, -20),
		Vector2(60 + cos(wing_angle)*20.0, -85 + sin(wing_angle)*30.0),
		Vector2(75 + cos(wing_angle)*10.0, -35),
		Vector2(30, 10),
		Vector2(10, -20)
	])
	var left_wing = PackedVector2Array([
		Vector2(-10, -20),
		Vector2(-70 - cos(wing_angle)*20.0, -85 + sin(wing_angle)*30.0),
		Vector2(-85 - cos(wing_angle)*10.0, -35),
		Vector2(-30, 10),
		Vector2(-10, -20)
	])
	draw_colored_polygon(right_wing, wing_color)
	draw_colored_polygon(left_wing, wing_color)
	
	# Draw Glowing Magma Core (Chest)
	var chest_pulse = 1.0 + sin(lifetime * 8.0) * 0.15
	draw_circle(Vector2.ZERO, 30.0, Color(0.22, 0.02, 0.0, 0.4)) # Glow boundary
	draw_circle(Vector2.ZERO, 18.0, magma_glow * chest_pulse)
	draw_circle(Vector2.ZERO, 9.0, Color.YELLOW * chest_pulse)
	
	# Draw Horns
	var right_horn = PackedVector2Array([Vector2(12, -42), Vector2(32, -72), Vector2(18, -42)])
	var left_horn = PackedVector2Array([Vector2(-12, -42), Vector2(-32, -72), Vector2(-18, -42)])
	draw_colored_polygon(right_horn, horn_color)
	draw_colored_polygon(left_horn, horn_color)
	
	# Draw Giant Snout/Head (Ash Dragon skull shape)
	draw_circle(Vector2(0, -32), 20.0, dark_body) # Head crown
	draw_rect(Rect2(-15, -32, 30, 26), dark_body) # Skull body
	
	# Snout extending forward-left
	var snout_pts = PackedVector2Array([
		Vector2(-15, -18),
		Vector2(-40, -10),
		Vector2(-40, 2),
		Vector2(-9, 7),
		Vector2(-15, -18)
	])
	draw_colored_polygon(snout_pts, dark_body)
	
	# Draw Glowing Red Eyes
	draw_circle(Vector2(-11, -24), 4.0, Color.BLACK)
	draw_circle(Vector2(-13, -24), 2.0, Color.RED)
	draw_circle(Vector2(-14, -24), 0.8, Color.YELLOW)
	
	# Draw Lower Jaw (Animated opening on jaw_open_amount)
	var jaw_pts = PackedVector2Array([
		Vector2(-11, 4),
		Vector2(-36, 4 + jaw_open_amount),
		Vector2(-26, 12 + jaw_open_amount),
		Vector2(-5, 7),
		Vector2(-11, 4)
	])
	draw_colored_polygon(jaw_pts, Color(0.08, 0.08, 0.11))
	
	# Draw glowing orange flame leak from mouth when open
	if jaw_open_amount > 2.0:
		draw_circle(Vector2(-24, 3 + (jaw_open_amount/2.0)), jaw_open_amount * 0.35, Color(1.0, 0.38, 0.0, 0.85))
