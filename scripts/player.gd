extends CharacterBody2D


@export var speed: float = 75.0
@export var jump_velocity: float = -125.0
@export var gravity_scale: float = 0.5
@export var wall_slide_speed: float = 50.0 # Max falling speed when sliding on wall
@export var max_movement_cooldown: float = 200.0 # Time in milliseconds before player can move again

var spawn_position: Vector2
var movement_cooldown: float = 0.0 # Time in milliseconds before player can move again

func _ready() -> void:
	# Store the initial spawn position
	spawn_position = global_position
	
	# Connect to bottom boundary if it exists
	# Find the bottom boundary in the scene tree
	var scene_root = get_tree().current_scene
	if scene_root:
		var bottom_boundary = scene_root.get_node_or_null("BottomBoundary")
		if bottom_boundary and bottom_boundary.has_signal("body_entered"):
			bottom_boundary.body_entered.connect(_on_bottom_boundary_body_entered)


func _physics_process(delta: float) -> void:
	# Check if player is on a wall (not on floor)
	var is_on_wall_now := is_on_wall() and not is_on_floor()
	var wall_normal := get_wall_normal() if is_on_wall_now else Vector2.ZERO

	if is_on_floor() and movement_cooldown > 0:
		# Reset when player hits floor
		movement_cooldown = 0
	elif movement_cooldown > 0:
		movement_cooldown -= delta * 1000

	# Handle gravity - reduce gravity when wall sliding
	if not is_on_floor():
		velocity += get_gravity() * delta * gravity_scale

	# Handle wall sliding - limit fall speed when sliding on wall
	if is_on_wall_now and velocity.y > 0:
		velocity.y = min(velocity.y, wall_slide_speed)

	# Handle jump (regular jump from floor)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	if movement_cooldown <= 0:
		var direction := Input.get_axis("move_left", "move_right")
		if direction:
			velocity.x = direction * speed
		else:
			velocity.x = move_toward(velocity.x, 0, 20)

		
	# Handle wall jump (after movement input so it can override velocity)
	if Input.is_action_just_pressed("jump") and is_on_wall_now:
		# Jump away from the wall
		velocity.x = wall_normal.x * speed
		# Jump up from the wall
		velocity.y = jump_velocity
		# Set a movement cooldown to prevent instantly moving back to the wall
		movement_cooldown = max_movement_cooldown
	
	if (velocity.x != 0):
		$AnimatedSprite2D.flip_h = velocity.x < 0

	move_and_slide()

func _on_bottom_boundary_body_entered(body: Node2D) -> void:
	# Reset position when player enters the bottom boundary
	if body == self:
		reset_position()

func reset_position() -> void:
	"""Reset player to spawn position and stop velocity."""
	global_position = spawn_position
	velocity = Vector2.ZERO

func apply_damage() -> void:
	"""Apply damage to the player. For now, just resets position."""
	reset_position()
