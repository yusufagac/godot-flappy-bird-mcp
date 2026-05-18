extends Area2D
class_name Projectile

enum ProjectileType {
	SOUL_FIREBALL = 0,
	DARK_FIREBALL_STRAIGHT = 1,
	DARK_FIREBALL_ZIGZAG = 2,
	DARK_FIREBALL_HOMING = 3,
	DARK_FIREBALL_METEOR = 4,
	DARK_FIREBALL_VOLCANIC = 5,
	DARK_FIREBALL_BEAM = 6,
	DARK_FIREBALL_EXPANDING = 7
}

var type: int = 0
var speed: float = 480.0
var direction: float = 1.0  # 1.0 = right (player), -1.0 = left (boss)
var damage: int = 10

# Custom movement parameters
var lifetime: float = 0.0
var initial_y: float = 0.0
var vertical_speed: float = 0.0
var bird_ref: Node2D = null
var velocity_vector: Vector2 = Vector2.ZERO

func _ready() -> void:
	initial_y = position.y
	
	# Add a collision shape programmatically
	var col_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 8.0
	col_shape.shape = circle
	add_child(col_shape)
	
	# Find bird in scene dynamically for homing tracking
	var parent = get_parent()
	if parent:
		if parent.has_node("Bird"):
			bird_ref = parent.get_node("Bird")
		else:
			for child in parent.get_children():
				if child.name.contains("Bird"):
					bird_ref = child
					break
	
	# Connect collision signals
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	lifetime += delta
	
	# If velocity vector is explicitly set, use vector physics
	if velocity_vector != Vector2.ZERO:
		position += velocity_vector * delta
	else:
		match type:
			0, 1: # SOUL_FIREBALL or DARK_FIREBALL_STRAIGHT
				position.x += speed * direction * delta
			2: # DARK_FIREBALL_ZIGZAG (Sine wave vertical oscillation)
				position.x += speed * direction * delta
				position.y = initial_y + sin(lifetime * 10.0) * 45.0
			3: # DARK_FIREBALL_HOMING (Track bird Y coordinate gently)
				position.x += speed * direction * delta
				if bird_ref and is_instance_valid(bird_ref) and bird_ref.is_alive:
					position.y = move_toward(position.y, bird_ref.global_position.y, delta * 150.0)
			4: # DARK_FIREBALL_METEOR (Fires from top down-left)
				position.x -= speed * 0.75 * delta
				position.y += speed * 0.65 * delta
			5: # DARK_FIREBALL_VOLCANIC (Shoots up, falls with gravity)
				position.x -= speed * 0.6 * delta
				if lifetime == delta:
					vertical_speed = -400.0 # initial eruptive boost
				vertical_speed += 800.0 * delta # Gravity drag
				position.y += vertical_speed * delta
			6: # DARK_FIREBALL_BEAM (Rapid laser sweep)
				position.x += speed * 1.6 * direction * delta
			7: # DARK_FIREBALL_EXPANDING
				position.x += speed * direction * delta

	# Redraw for glowing flicker animation
	queue_redraw()
	
	# Delete if off-screen
	if position.x < -150 or position.x > 650 or position.y < -100 or position.y > 800:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if type == 0: # SOUL_FIREBALL
		# Fired by player, hits boss or enemies
		if body.has_method("take_damage"):
			body.take_damage(damage)
			queue_free()
	else: # DARK_FIREBALL variations
		# Fired by boss, hits player
		if body.has_method("die"):
			body.die()
			queue_free()

func _on_area_entered(area: Area2D) -> void:
	if type == 0: # SOUL_FIREBALL
		# Fired by player, hits gargoyle/enemy
		if area.has_method("take_damage"):
			area.take_damage(damage)
			queue_free()
		elif area.name.contains("Boss") or area.get_parent().name.contains("Boss"):
			var parent = area.get_parent()
			if parent.has_method("take_damage"):
				parent.take_damage(damage)
				queue_free()

func _draw() -> void:
	var time = Time.get_ticks_msec() / 100.0
	var flicker = sin(time) * 1.5
	
	match type:
		0: # SOUL_FIREBALL (Glowing magical blue/cyan magic arrow style)
			draw_circle(Vector2.ZERO, 10.0 + flicker, Color(0.1, 0.5, 1.0, 0.35))
			draw_circle(Vector2.ZERO, 7.0, Color(0.3, 0.75, 1.0, 0.8))
			draw_circle(Vector2.ZERO, 3.5, Color.WHITE)
		1, 2, 7: # Dark Volcanic Fireballs (Straight, zigzag, circular expanders)
			draw_circle(Vector2.ZERO, 12.0 + flicker, Color(1.0, 0.3, 0.05, 0.35))
			draw_circle(Vector2.ZERO, 8.0, Color(0.8, 0.15, 0.02, 0.8))
			draw_circle(Vector2.ZERO, 4.0, Color(1.0, 0.8, 0.2))
		3: # Homing magic (Glowing purple/magenta souls style)
			draw_circle(Vector2.ZERO, 14.0 + flicker, Color(0.65, 0.05, 0.85, 0.35))
			draw_circle(Vector2.ZERO, 9.0, Color(0.45, 0.0, 0.6, 0.8))
			draw_circle(Vector2.ZERO, 4.5, Color(0.9, 0.6, 1.0))
		4: # Meteor Rain (Fiery red/charcoal giant meteor)
			draw_circle(Vector2.ZERO, 15.0 + flicker, Color(0.95, 0.08, 0.0, 0.4))
			draw_circle(Vector2.ZERO, 10.0, Color(0.55, 0.05, 0.02, 0.85))
			draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.55, 0.1))
		5: # Volcanic Eruption (Molten bright lava yellow)
			draw_circle(Vector2.ZERO, 11.0 + flicker, Color(1.0, 0.65, 0.0, 0.4))
			draw_circle(Vector2.ZERO, 8.0, Color(1.0, 0.4, 0.0, 0.8))
			draw_circle(Vector2.ZERO, 3.5, Color.YELLOW)
		6: # Giant Lava Sweeping Laser Beam (Thick glowing red laser bar)
			draw_line(Vector2(-18, 0), Vector2(18, 0), Color(1.0, 0.2, 0.0, 0.3), 18.0)
			draw_line(Vector2(-14, 0), Vector2(14, 0), Color(0.9, 0.05, 0.05, 0.8), 10.0)
			draw_line(Vector2(-8, 0), Vector2(8, 0), Color.WHITE, 4.0)
