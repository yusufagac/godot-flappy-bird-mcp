extends Area2D
class_name Projectile

enum ProjectileType { SOUL_FIREBALL, DARK_FIREBALL }

var type: ProjectileType = ProjectileType.SOUL_FIREBALL
var speed: float = 480.0
var direction: float = 1.0  # 1.0 = right (player), -1.0 = left (boss)
var damage: int = 10

func _ready() -> void:
	# Add a collision shape programmatically
	var col_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 8.0
	col_shape.shape = circle
	add_child(col_shape)
	
	# Connect collision signals
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	position.x += speed * direction * delta
	
	# Redraw for glowing flicker animation
	queue_redraw()
	
	# Delete if off-screen
	if position.x < -100 or position.x > 600:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if type == ProjectileType.SOUL_FIREBALL:
		# Fired by player, hits boss
		if body.has_method("take_damage"):
			body.take_damage(damage)
			queue_free()
	elif type == ProjectileType.DARK_FIREBALL:
		# Fired by boss, hits player
		if body is Bird:
			body.die()
			queue_free()

func _on_area_entered(area: Area2D) -> void:
	if type == ProjectileType.SOUL_FIREBALL:
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
	
	if type == ProjectileType.SOUL_FIREBALL:
		# Beautiful glowing blue/cyan magic fireball (Soul Arrow style)
		draw_circle(Vector2.ZERO, 10.0 + flicker, Color(0.1, 0.5, 1.0, 0.35)) # Glow aura
		draw_circle(Vector2.ZERO, 7.0, Color(0.3, 0.75, 1.0, 0.8))  # Soul color
		draw_circle(Vector2.ZERO, 3.5, Color.WHITE)                 # Core
	else:
		# Beautiful dark volcanic orange fireball (Lord of Cinder style)
		draw_circle(Vector2.ZERO, 12.0 + flicker, Color(1.0, 0.3, 0.05, 0.35)) # Orange glow aura
		draw_circle(Vector2.ZERO, 8.0, Color(0.8, 0.15, 0.02, 0.8))  # Dark red fire
		draw_circle(Vector2.ZERO, 4.0, Color(1.0, 0.8, 0.2))         # Core yellow
