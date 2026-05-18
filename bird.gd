extends CharacterBody2D
class_name Bird

signal hit_obstacle

const GRAVITY: float = 900.0
const JUMP_VELOCITY: float = -320.0
const MAX_FALL_SPEED: float = 600.0
const ROT_UP: float = -0.4  # Tilt up when jumping (rads)
const ROT_DOWN: float = 1.2 # Tilt down when falling (rads)

var is_alive: bool = true
var wing_anim_timer: float = 0.0
var wing_offset_y: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# Add a collision shape if not already present
	velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if not is_alive:
		# Fall to ground
		if global_position.y < 680:
			velocity.y += GRAVITY * delta
			move_and_slide()
		rotation = lerp_angle(rotation, ROT_DOWN, 6.0 * delta)
		return

	# Apply gravity
	velocity.y += GRAVITY * delta
	if velocity.y > MAX_FALL_SPEED:
		velocity.y = MAX_FALL_SPEED

	# Movement
	move_and_slide()

	# Rotation juice based on vertical velocity
	if velocity.y < 0:
		rotation = lerp_angle(rotation, ROT_UP, 12.0 * delta)
	else:
		rotation = lerp_angle(rotation, ROT_DOWN, 4.0 * delta)

	# Wing flap animation logic
	wing_anim_timer += delta * 15.0
	wing_offset_y = sin(wing_anim_timer) * 4.0
	queue_redraw()

func flap() -> void:
	if not is_alive:
		return
	velocity.y = JUMP_VELOCITY
	# Restart flap wing animation speed
	wing_anim_timer = 0.0

func die() -> void:
	if is_alive:
		is_alive = false
		velocity.y = JUMP_VELOCITY * 0.5 # Small bump on death
		hit_obstacle.emit()

# Procedural vector drawing for premium aesthetic without asset files
func _draw() -> void:
	# Draw shadow
	draw_circle(Vector2(2, 2), 16.0, Color(0, 0, 0, 0.2))
	
	# Draw Body (Yellow Gradient effect using HSL-like colors)
	draw_circle(Vector2.ZERO, 16.0, Color(1.0, 0.85, 0.2)) # Yellow
	
	# Draw Beak (Orange Triangle)
	var beak_pts = PackedVector2Array([
		Vector2(14, -4),
		Vector2(24, 0),
		Vector2(14, 4)
	])
	draw_colored_polygon(beak_pts, Color(1.0, 0.5, 0.1))
	
	# Draw Wing (Animated flap)
	var wing_pos = Vector2(-6, 2 + wing_offset_y)
	draw_circle(wing_pos, 8.0, Color(0.9, 0.7, 0.1))
	draw_circle(wing_pos + Vector2(1, 1), 6.0, Color(1.0, 0.85, 0.2))
	
	# Draw Eye (White + Black Pupil)
	var eye_pos = Vector2(6, -6)
	draw_circle(eye_pos, 5.0, Color.WHITE)
	draw_circle(eye_pos + Vector2(1, 0), 2.0, Color.BLACK)
