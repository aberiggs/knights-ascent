extends CharacterBody2D


@export var speed: float = 120.0
@export var jump_velocity: float = -250
@export var gravity_scale: float = 1.0
@export var fall_reset_threshold: float = 200.0 # Y position threshold for reset (positive = below spawn)

var spawn_position: Vector2


func _ready() -> void:
	# Store the initial spawn position
	spawn_position = global_position


func _physics_process(delta: float) -> void:
	# Check if player has fallen too far below the spawn point
	if global_position.y > spawn_position.y + fall_reset_threshold:
		reset_position()
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta * gravity_scale

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	
	if direction != 0:
		$AnimatedSprite2D.flip_h = direction < 0

	move_and_slide()


func reset_position() -> void:
	"""Reset player to spawn position and stop velocity."""
	global_position = spawn_position
	velocity = Vector2.ZERO
