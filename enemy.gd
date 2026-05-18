extends Area2D
class_name GargoyleEnemy

signal defeated

var speed: float = 210.0
var hp: int = 10
var amp: float = 25.0
var freq: float = 4.5
var base_y: float = 0.0
var lifetime: float = 0.0
var wing_flap_timer: float = 0.0

func _ready() -> void:
	base_y = position.y
	
	# Add a collision shape programmatically
	var col_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 15.0
	col_shape.shape = circle
	add_child(col_shape)
	
	# Connect body entered
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	lifetime += delta
	wing_flap_timer += delta * 12.0
	
	position.x -= speed * delta
	position.y = base_y + sin(lifetime * freq) * amp
	
	# Redraw for flapping animation
	queue_redraw()
	
	# Delete if off screen
	if position.x < -100:
		queue_free()

func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		defeated.emit()
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die()

func _draw() -> void:
	# Draw gothic dark wing glow shadow
	draw_circle(Vector2.ZERO, 16.0, Color(0.2, 0.02, 0.35, 0.2))
	
	# Draw Head and Body (Dark purple / ash-black)
	draw_circle(Vector2.ZERO, 10.0, Color(0.18, 0.14, 0.23)) # Head
	draw_circle(Vector2(0, 5), 8.0, Color(0.11, 0.08, 0.16))   # Body
	
	# Draw Glowing Red Eyes
	draw_circle(Vector2(-3, -2), 1.5, Color.RED)
	draw_circle(Vector2(3, -2), 1.5, Color.RED)
	
	# Draw Bat Wings (Flapping based on wing_flap_timer)
	var wing_angle = sin(wing_flap_timer) * 0.8
	var right_wing = PackedVector2Array([
		Vector2(6, 2),
		Vector2(20 + cos(wing_angle)*8.0, -10 + sin(wing_angle)*12.0),
		Vector2(14, 8),
		Vector2(6, 2)
	])
	var left_wing = PackedVector2Array([
		Vector2(-6, 2),
		Vector2(-20 - cos(wing_angle)*8.0, -10 + sin(wing_angle)*12.0),
		Vector2(-14, 8),
		Vector2(-6, 2)
	])
	draw_colored_polygon(right_wing, Color(0.06, 0.04, 0.09))
	draw_colored_polygon(left_wing, Color(0.06, 0.04, 0.09))
