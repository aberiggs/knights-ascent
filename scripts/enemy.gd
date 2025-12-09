class_name Enemy extends CharacterBody2D

@export var raycast: RayCast2D

@export var speed: float = 50.0
@export var max_pace_distance: float = 50.0

@export var start_attack_range: float = 8.0 # Distance in pixels to trigger an attack
@export var attack_speed: float = 1.0 # Speed of the attack animation

@export var view_distance: float = 200.0 # Distance in pixels to see the player
@export var view_height: float = 15.0 # Distance in pixels to see the player vertically

var target_position: Vector2
var direction: int = 1
var player: Player = null
var is_attacking: bool = false
var is_alive: bool = true

var wall_collision_layer: int = 1
var player_collision_layer: int = 2

func _ready() -> void:
	# Store the initial spawn position
	target_position = global_position

	# Find the player in the scene tree
	var scene_root = get_tree().current_scene
	if scene_root:
		player = scene_root.get_node_or_null("Player")
	
	# Connect to animation finished signal if animation player exists
	if $Body/AnimationPlayer:
		$Body/AnimationPlayer.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	# Add the gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	if not is_alive:
		velocity.x = 0
		move_and_slide()
		return

	# Check for player proximity and start attack animation
	# Do this early to prevent movement in the same frame as attack starts
	if can_attack():
		start_attack()

	# Freeze movement during attack
	if not is_attacking and is_on_floor():
		if can_see_player():
			chase_player()
		else:
			pace()
	elif is_attacking:
		# Stop horizontal movement during attack
		velocity.x = 0
		# But make sure we face the player while attacking
		$Body.scale.x = sign(player.global_position.x - global_position.x)

	if velocity.x != 0:
		$Body.scale.x = sign(direction)

	if velocity.y != 0:
		# If the enemy falls off a platform, reset the target position
		target_position = global_position

	move_and_slide()

func pace() -> void:
	var current_direction = direction

	# First, check if the enemy has walked too far from the spawn position
	if abs(global_position.x - target_position.x) >= max_pace_distance:
		# If so, go back to the spawn position
		direction = sign(target_position.x - global_position.x)

	# Next, check if the enemy is colliding with a wall
	if is_on_wall():
		direction = - current_direction

	if at_edge_of_platform():
		# If the enemy would walk off the platform, turn around
		direction = - current_direction

	velocity.x = sign(direction) * speed

func can_attack() -> bool:
	if player and player.is_alive and not is_attacking:
		var distance_to_player = global_position.distance_to(player.global_position)
		return is_facing_player() and distance_to_player <= start_attack_range

	return false

func start_attack() -> void:
	"""Start the attack animation and freeze movement."""

	if $Body/AnimationPlayer and $Body/AnimationPlayer.has_animation("attack"):
		is_attacking = true
		$Body/AnimationPlayer.play("attack", -1, attack_speed)
		$Body/AttackHitbox.monitoring = true

func _on_animation_finished(anim_name: String) -> void:
	"""Called when an animation finishes. Apply damage if attack animation finished."""
	if not $Body/AnimationPlayer:
		return

	if is_attacking and anim_name == "attack":
		is_attacking = false
		$Body/AttackHitbox.monitoring = false

	if anim_name == "die":
		# Remove the enemy
		queue_free()

	if $Body/AnimationPlayer.has_animation("idle"):
		$Body/AnimationPlayer.play("idle")

func is_facing_player() -> bool:
	if player:
		return (direction > 0 and global_position.x < player.global_position.x) or (direction < 0 and global_position.x > player.global_position.x)
	return false

func apply_damage() -> void:
	"""Apply damage to the enemy."""
	# For now, all enemies are 1 hit kills
	if is_alive:
		die()

func die() -> void:
	"""What happens when the enemy dies?"""
	is_alive = false
	$Body/AnimationPlayer.play("die")

func perform_attack_hitcheck() -> void:
	"""Perform a hit check for the attack."""
	var hitbox = $Body/AttackHitbox

	var overlapping_bodies = hitbox.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body is Player:
			body.apply_damage()

func at_edge_of_platform() -> bool:
	if not $Body/RayCast2D.is_colliding():
		return true
	return false

func can_see_player() -> bool:
	var x_dist = abs(player.global_position.x - global_position.x)
	var y_dist = player.global_position.y - global_position.y # Positive if player is above
	if x_dist > view_distance or y_dist > view_height:
		return false

	return is_facing_player()

func chase_player() -> void:
	"""Chase the player."""
	if at_edge_of_platform():
		velocity.x = 0
		return

	direction = sign(player.global_position.x - global_position.x)
	velocity.x = direction * speed
