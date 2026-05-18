extends Area2D
class_name PowerUp

const SPEED: float = 180.0
var amp: float = 20.0
var freq: float = 3.5
var base_y: float = 0.0
var lifetime: float = 0.0

func _ready() -> void:
	base_y = position.y
	
	# Add a collision shape programmatically
	var col_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 16.0
	col_shape.shape = circle
	add_child(col_shape)
	
	# Connect signal
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	lifetime += delta
	position.x -= SPEED * delta
	
	# Hover bobbing animation in Y axis
	position.y = base_y + sin(lifetime * freq) * amp
	
	# Redraw for glowing animations
	queue_redraw()
	
	# Delete if off screen
	if position.x < -100:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("kindle"):
		body.kindle(5) # Give 5 Kindled fireballs!
		queue_free()

func _draw() -> void:
	var pulse = sin(lifetime * 8.0) * 1.5
	
	# Draw Glowing Gold Aura behind the Estus Flask
	draw_circle(Vector2.ZERO, 16.0 + pulse, Color(1.0, 0.75, 0.1, 0.35))
	
	# Draw Flask Neck
	draw_rect(Rect2(-3, -12, 6, 8), Color(0.8, 0.7, 0.5)) # Neck rim
	draw_rect(Rect2(-4, -14, 8, 3), Color(0.5, 0.3, 0.1)) # Cork
	
	# Draw Flask Base (Gothic Flask Shape: bulbous bottom)
	draw_circle(Vector2(0, 0), 10.0, Color(0.95, 0.85, 0.65, 0.6)) # Outer glass body
	draw_circle(Vector2(0, 2), 7.5, Color(1.0, 0.55, 0.02))       # Glowing Estus Liquid inside
	draw_circle(Vector2(0, 2), 4.5, Color(1.0, 0.85, 0.1))        # Core liquid glow
	
	# Glass shine (accent white dot)
	draw_circle(Vector2(-3.5, -3.5), 2.0, Color.WHITE)
