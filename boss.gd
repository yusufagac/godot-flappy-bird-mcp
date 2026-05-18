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

# Dynamic parameterized boss properties
var boss_name: String = "ASYLUM DEMON"
var boss_tier: int = 1
var body_color: Color = Color(0.2, 0.25, 0.2)
var wing_color: Color = Color(0.12, 0.15, 0.12)
var core_color: Color = Color(0.5, 0.7, 0.1)
var horn_color: Color = Color(0.25, 0.25, 0.22)

# Timers
var attack_timer: float = 0.0
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

func set_tier(tier: int) -> void:
	boss_tier = tier
	
	match boss_tier:
		1:
			boss_name = "ASYLUM DEMON"
			max_hp = 100
			body_color = Color(0.22, 0.25, 0.22) # Moss green/grey
			wing_color = Color(0.12, 0.15, 0.12)
			core_color = Color(0.4, 0.7, 0.1) # Corrupted green glow
			horn_color = Color(0.25, 0.25, 0.22)
		2:
			boss_name = "BELL GARGOYLE"
			max_hp = 115
			body_color = Color(0.35, 0.24, 0.15) # Copper bronze
			wing_color = Color(0.25, 0.18, 0.1)
			core_color = Color(0.85, 0.45, 0.1) # Bronze orange glow
			horn_color = Color(0.4, 0.32, 0.2)
		3:
			boss_name = "CAPRA DEMON"
			max_hp = 125
			body_color = Color(0.1, 0.1, 0.12) # Dark charcoal
			wing_color = Color(0.06, 0.06, 0.08)
			core_color = Color(0.7, 0.05, 0.05) # Angry blood red glow
			horn_color = Color(0.8, 0.8, 0.78) # Pale ivory bone horns
		4:
			boss_name = "GAPING DRAGON"
			max_hp = 135
			body_color = Color(0.42, 0.28, 0.3) # Fleshy pink
			wing_color = Color(0.28, 0.18, 0.2)
			core_color = Color(0.75, 0.25, 0.45) # Rib cage purple glow
			horn_color = Color(0.32, 0.22, 0.22)
		5:
			boss_name = "CHAOS WITCH QUELAAG"
			max_hp = 150
			body_color = Color(0.28, 0.04, 0.04) # Molten red
			wing_color = Color(0.15, 0.0, 0.0)
			core_color = Color(0.95, 0.25, 0.0) # Hot orange lava glow
			horn_color = Color(0.2, 0.05, 0.05)
		6:
			boss_name = "GREAT GREY WOLF SIF"
			max_hp = 170
			body_color = Color(0.28, 0.3, 0.36) # Slate grey-blue
			wing_color = Color(0.18, 0.2, 0.24)
			core_color = Color(0.2, 0.5, 0.85) # Magic moonlight blue
			horn_color = Color(0.24, 0.25, 0.28)
		7:
			boss_name = "IRON GOLEM"
			max_hp = 190
			body_color = Color(0.25, 0.22, 0.2) # Cast iron
			wing_color = Color(0.15, 0.12, 0.1)
			core_color = Color(0.7, 0.35, 0.1) # Rusty orange glow
			horn_color = Color(0.3, 0.25, 0.22)
		8:
			boss_name = "DRAGON SLAYER ORNSTEIN"
			max_hp = 210
			body_color = Color(0.55, 0.45, 0.15) # Gold
			wing_color = Color(0.4, 0.3, 0.1)
			core_color = Color(0.1, 0.75, 1.0) # Electric lightning cyan
			horn_color = Color(0.65, 0.55, 0.2)
		9:
			boss_name = "GRAVELORD NITO"
			max_hp = 230
			body_color = Color(0.06, 0.06, 0.08) # Shadow black shroud
			wing_color = Color(0.02, 0.02, 0.04)
			core_color = Color(0.38, 0.38, 0.42) # Skeleton mist bone white
			horn_color = Color(0.55, 0.55, 0.55)
		10:
			boss_name = "GWYN, LORD OF CINDER"
			max_hp = 250
			body_color = Color(0.18, 0.14, 0.1) # Charred king
			wing_color = Color(0.1, 0.05, 0.02)
			core_color = Color(1.0, 0.35, 0.0) # Solar blinding orange
			horn_color = Color(0.3, 0.22, 0.15)
			
	hp = max_hp

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
	wing_timer += delta * (12.0 if is_dashing else 8.0)
	
	# 1. Hovering & vertical sweeping (bell gargoyle & Ornstein sweep more!)
	if not is_dashing:
		var sweep_amp = 35.0
		if boss_tier == 2 or boss_tier == 8:
			sweep_amp = 65.0 # Sweeps vertically aggressively!
		position.y = base_y + sin(lifetime * (2.2 if boss_tier != 8 else 3.5)) * sweep_amp
	
	if not intro_completed:
		return
		
	# 2. Attack Cycles
	attack_timer += delta
	var attack_cooldown = 2.4 - (boss_tier * 0.08) # Bosses shoot faster at higher levels!
	if attack_timer >= attack_cooldown:
		attack_timer = 0.0
		_trigger_tier_attack()
		
	# Process Dash States
	if is_dashing:
		_process_dash(delta)
		
	queue_redraw()

func _trigger_tier_attack() -> void:
	var choice = randi() % 100
	
	match boss_tier:
		1: # ASYLUM DEMON (Straight fireballs or slow dash charge)
			if choice < 65:
				_shoot_projectile(1) # STRAIGHT
			else:
				_start_dash_attack(400.0) # Slow dash
		2: # BELL GARGOYLE (Zigzag fireballs or double vertical shoots)
			_shoot_projectile(2) # ZIGZAG
		3: # CAPRA DEMON (Circular expanding rings & highly aggressive bone charge)
			if choice < 50:
				_shoot_ring_attack(6) # 6 expanding fireballs
			else:
				_start_dash_attack(680.0) # Fast body dash!
		4: # GAPING DRAGON (Volcanic upward eruptions or perimeter explosion zones)
			if choice < 55:
				_shoot_volcanic_ground_eruption()
			else:
				_spawn_area_bursts(3)
		5: # CHAOS WITCH QUELAAG (Volleys of meteor rain falling from sky)
			_shoot_meteors(4)
		6: # GREAT GREY WOLF SIF (Moonlight tracking homing orbs or sweep dashes)
			if choice < 50:
				_shoot_projectile(3) # HOMING MAGIC
			else:
				_start_dash_attack(740.0) # Fast sweeping double dash
		7: # IRON GOLEM (Sequential twisting spiral wave)
			_shoot_spiral_wave()
		8: # DRAGON SLAYER ORNSTEIN (Extreme speed zigzag lightning shots or electric charges)
			if choice < 60:
				var proj = _shoot_projectile(2) # Zigzag
				if proj:
					proj.speed = 580.0 # lightning fast!
			else:
				_start_dash_attack(850.0) # Lightning charge!
		9: # GRAVELORD NITO (Skeleton volcanic fire eruptions & meteor showers)
			if choice < 50:
				_shoot_volcanic_ground_eruption()
			else:
				_shoot_meteors(6)
		10: # GWYN, LORD OF CINDER (Sweeping giant lava laser beam, homing spheres, & expanded rings)
			if choice < 40:
				_shoot_giant_lava_beam()
			elif choice < 70:
				_shoot_ring_attack(8)
			else:
				_shoot_projectile(3) # Homing magic spheres

# --- Attack Helper Implementations ---

func _shoot_projectile(proj_type: int) -> Area2D:
	var tween = create_tween()
	tween.tween_property(self, "jaw_open_amount", 10.0, 0.12)
	tween.tween_property(self, "jaw_open_amount", 0.0, 0.12).set_delay(0.2)
	
	var proj = Area2D.new()
	proj.set_script(projectile_script)
	proj.type = proj_type
	proj.direction = -1.0 # Fire left
	proj.position = global_position + Vector2(-36, 12)
	get_parent().add_child(proj)
	return proj

func _shoot_ring_attack(count: int) -> void:
	var tween = create_tween()
	tween.tween_property(self, "jaw_open_amount", 14.0, 0.15)
	tween.tween_property(self, "jaw_open_amount", 0.0, 0.15).set_delay(0.4)
	
	for i in range(count):
		var angle = (float(i) / count) * PI * 2.0
		var proj = Area2D.new()
		proj.set_script(projectile_script)
		proj.type = 7 # EXPANDING
		proj.velocity_vector = Vector2(cos(angle), sin(angle)) * 260.0
		proj.position = global_position + Vector2(-20, 0)
		get_parent().add_child(proj)

func _spawn_area_bursts(count: int) -> void:
	for i in range(count):
		var fire_tween = create_tween()
		fire_tween.tween_callback(func():
			var rx = randf_range(60, 300)
			var ry = randf_range(120, 520)
			# Spawn a small exploding cross-hazard at target coords
			for j in range(4):
				var angle = (float(j) / 4) * PI * 2.0
				var proj = Area2D.new()
				proj.set_script(projectile_script)
				proj.type = 7
				proj.velocity_vector = Vector2(cos(angle), sin(angle)) * 140.0
				proj.position = Vector2(rx, ry)
				get_parent().add_child(proj)
		).set_delay(0.3 * i)

func _shoot_meteors(count: int) -> void:
	for i in range(count):
		var fire_tween = create_tween()
		fire_tween.tween_callback(func():
			var proj = Area2D.new()
			proj.set_script(projectile_script)
			proj.type = 4 # METEOR
			proj.position = Vector2(randf_range(100, 480), -20) # Spawn off top
			get_parent().add_child(proj)
		).set_delay(0.2 * i)

func _shoot_volcanic_ground_eruption() -> void:
	for i in range(4):
		var fire_tween = create_tween()
		fire_tween.tween_callback(func():
			var proj = Area2D.new()
			proj.set_script(projectile_script)
			proj.type = 5 # VOLCANIC
			proj.position = Vector2(randf_range(100, 380), 630) # Spawn off bottom ground
			get_parent().add_child(proj)
		).set_delay(0.25 * i)

func _shoot_spiral_wave() -> void:
	for i in range(5):
		var fire_tween = create_tween()
		fire_tween.tween_callback(func():
			var angle = (float(i) / 5) * PI + PI # Sequentially angled waves leftward
			var proj = Area2D.new()
			proj.set_script(projectile_script)
			proj.type = 7
			proj.velocity_vector = Vector2(cos(angle), sin(angle)) * 280.0
			proj.position = global_position + Vector2(-36, 12)
			get_parent().add_child(proj)
		).set_delay(0.15 * i)

func _shoot_giant_lava_beam() -> void:
	var tween = create_tween()
	tween.tween_property(self, "jaw_open_amount", 16.0, 0.4)
	
	# Spawn a vertical line of rapid sweeping beams!
	tween.tween_callback(func():
		var start_y = randf_range(160, 400)
		for i in range(5):
			var proj = Area2D.new()
			proj.set_script(projectile_script)
			proj.type = 6 # BEAM
			proj.direction = -1.0
			proj.speed = 650.0
			proj.position = Vector2(global_position.x - 30, start_y + (i * 24) - 48)
			get_parent().add_child(proj)
	).set_delay(0.4)
	
	tween.tween_property(self, "jaw_open_amount", 0.0, 0.2).set_delay(1.0)

func _start_dash_attack(dash_speed: float) -> void:
	is_dashing = true
	dash_stage = 1 # Windup
	dash_x_target = position.x
	
	# Pull back right
	var tween = create_tween()
	tween.tween_property(self, "position:x", 425.0, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		# Dash forward off-screen left!
		dash_stage = 2
		var dash_tween = create_tween()
		dash_tween.tween_property(self, "position:x", -100.0, 0.65).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		dash_tween.tween_callback(func():
			# Re-emerge from right
			position.x = 550.0
			dash_stage = 3
			var retreat_tween = create_tween()
			retreat_tween.tween_property(self, "position:x", dash_x_target, 1.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			retreat_tween.tween_callback(func():
				is_dashing = false
				dash_stage = 0
			)
		)
	)

func _process_dash(delta: float) -> void:
	# Flap wings rapidly during a charge
	wing_timer += delta * 12.0
	if dash_stage == 2:
		jaw_open_amount = 12.0
	elif dash_stage == 3:
		jaw_open_amount = move_toward(jaw_open_amount, 0.0, delta * 30.0)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die()

func _draw() -> void:
	var wing_angle = sin(wing_timer) * 0.6
	
	# Drawing components based on our level-specific palette
	# Layered wings
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
	
	# Glowing Magma Chest Core
	var chest_pulse = 1.0 + sin(lifetime * 8.0) * 0.15
	draw_circle(Vector2.ZERO, 30.0, Color(core_color.r, core_color.g, core_color.b, 0.35))
	draw_circle(Vector2.ZERO, 18.0, core_color * chest_pulse)
	draw_circle(Vector2.ZERO, 9.0, Color.WHITE * chest_pulse)
	
	# Horns
	var right_horn = PackedVector2Array([Vector2(12, -42), Vector2(32, -72), Vector2(18, -42)])
	var left_horn = PackedVector2Array([Vector2(-12, -42), Vector2(-32, -72), Vector2(-18, -42)])
	draw_colored_polygon(right_horn, horn_color)
	draw_colored_polygon(left_horn, horn_color)
	
	# Head crown
	draw_circle(Vector2(0, -32), 20.0, body_color)
	draw_rect(Rect2(-15, -32, 30, 26), body_color)
	
	# Snout extending forward-left
	var snout_pts = PackedVector2Array([
		Vector2(-15, -18),
		Vector2(-40, -10),
		Vector2(-40, 2),
		Vector2(-9, 7),
		Vector2(-15, -18)
	])
	draw_colored_polygon(snout_pts, body_color)
	
	# Glowing Eyes
	draw_circle(Vector2(-11, -24), 4.0, Color.BLACK)
	draw_circle(Vector2(-13, -24), 2.0, core_color)
	draw_circle(Vector2(-14, -24), 0.8, Color.WHITE)
	
	# Lower Jaw (Animated opening on jaw_open_amount)
	var jaw_pts = PackedVector2Array([
		Vector2(-11, 4),
		Vector2(-36, 4 + jaw_open_amount),
		Vector2(-26, 12 + jaw_open_amount),
		Vector2(-5, 7),
		Vector2(-11, 4)
	])
	draw_colored_polygon(jaw_pts, Color(body_color.r * 0.7, body_color.g * 0.7, body_color.b * 0.7))
	
	# Draw glowing flames leak from mouth when open
	if jaw_open_amount > 2.0:
		draw_circle(Vector2(-24, 3 + (jaw_open_amount/2.0)), jaw_open_amount * 0.35, core_color)
