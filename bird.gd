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

var is_kindled: bool = false
var powerup_ammo: int = 0
var kindle_pulse_timer: float = 0.0
var projectile_script = load("res://projectile.gd")

var collision_shape: CollisionShape2D

func _ready() -> void:
	# Add a collision shape if not already present
	collision_shape = get_node_or_null("CollisionShape2D")
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		var circle = CircleShape2D.new()
		circle.radius = 14.0
		collision_shape.shape = circle
		add_child(collision_shape)
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
	
	if is_kindled:
		kindle_pulse_timer += delta * 12.0
		
	queue_redraw()

func flap() -> void:
	if not is_alive:
		return
	velocity.y = JUMP_VELOCITY
	# Restart flap wing animation speed
	wing_anim_timer = 0.0
	
	# Shoot soul fireball if kindled!
	if is_kindled and powerup_ammo > 0:
		_shoot_soul_fireball()
		powerup_ammo -= 1
		if powerup_ammo <= 0:
			is_kindled = false

func kindle(ammo: int) -> void:
	if not is_alive:
		return
	is_kindled = true
	powerup_ammo = ammo

func _shoot_soul_fireball() -> void:
	var proj = Area2D.new()
	proj.set_script(projectile_script)
	proj.type = 0 # ProjectileType.SOUL_FIREBALL
	proj.direction = 1.0 # Shoot right
	proj.position = global_position + Vector2(24, 0)
	get_parent().add_child(proj)

func die() -> void:
	if is_alive:
		is_alive = false
		is_kindled = false
		powerup_ammo = 0
		velocity.y = JUMP_VELOCITY * 0.5 # Small bump on death
		hit_obstacle.emit()

# Procedural vector drawing for premium aesthetic without asset files
func _draw() -> void:
	# Draw shadow
	draw_circle(Vector2(2, 2), 16.0, Color(0, 0, 0, 0.2))
	
	# Draw Glowing Flame Aura if Kindled
	if is_kindled:
		var pulse = sin(kindle_pulse_timer) * 2.0
		draw_circle(Vector2.ZERO, 22.0 + pulse, Color(1.0, 0.45, 0.0, 0.35)) # Outer fire aura
		draw_circle(Vector2.ZERO, 18.0, Color(1.0, 0.75, 0.0, 0.65))        # Inner core fire
		
		# Draw small rising fire embers
		var ember_y = sin(kindle_pulse_timer * 1.5) * 5.0
		draw_circle(Vector2(-16, -6 + ember_y), 3.0, Color(1.0, 0.5, 0.0, 0.8))
		draw_circle(Vector2(-12, 6 - ember_y), 2.0, Color(1.0, 0.85, 0.0, 0.9))
	
	# Draw Body (Yellow Gradient / Kindled Ember charcoal body)
	var body_color = Color(1.0, 0.85, 0.2)
	if is_kindled:
		body_color = Color(0.9, 0.4, 0.08) # Kindled glowing core body
	draw_circle(Vector2.ZERO, 16.0, body_color)
	
	# Draw Beak (Orange Triangle)
	var beak_pts = PackedVector2Array([
		Vector2(14, -4),
		Vector2(24, 0),
		Vector2(14, 4)
	])
	draw_colored_polygon(beak_pts, Color(1.0, 0.5, 0.1) if not is_kindled else Color(1.0, 0.3, 0.0))
	
	# Draw Wing (Animated flap)
	var wing_pos = Vector2(-6, 2 + wing_offset_y)
	var wing_color1 = Color(0.9, 0.7, 0.1)
	var wing_color2 = Color(1.0, 0.85, 0.2)
	if is_kindled:
		wing_color1 = Color(0.8, 0.15, 0.0)
		wing_color2 = Color(1.0, 0.55, 0.0)
	draw_circle(wing_pos, 8.0, wing_color1)
	draw_circle(wing_pos + Vector2(1, 1), 6.0, wing_color2)
	
	# Draw Eye (White + Black Pupil / Glowing gold)
	var eye_pos = Vector2(6, -6)
	draw_circle(eye_pos, 5.0, Color.WHITE)
	if is_kindled:
		draw_circle(eye_pos + Vector2(1, 0), 2.5, Color(1.0, 0.85, 0.0)) # Glowing gold eye
		draw_circle(eye_pos + Vector2(1, 0), 1.0, Color.RED)
	else:
		draw_circle(eye_pos + Vector2(1, 0), 2.0, Color.BLACK)
