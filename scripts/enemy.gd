class_name Enemy extends CharacterBody2D

@export var raycast: RayCast2D

@export var speed: float = 50.0
@export var max_pace_distance: float = 50.0
@export var start_attack_range: float = 8.0 # Distance in pixels to trigger an attack
@export var attack_speed: float = 1.0 # Speed of the attack animation

var pace_distance: float = 0.0
var direction: int = 1
var player: Player = null
var is_attacking: bool = false
var is_alive: bool = true

func _ready() -> void:
	# Find the player in the scene tree
	var scene_root = get_tree().current_scene
	if scene_root:
		player = scene_root.get_node_or_null("Player")
	
	# Connect to animation finished signal if animation player exists
	if $Body/AnimationPlayer:
		$Body/AnimationPlayer.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if not is_alive:
		velocity.x = 0
		# Apply gravity even if it's considered dead
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		return

	# Check for player proximity and start attack animation
	# Do this early to prevent movement in the same frame as attack starts
	if player and player.is_alive and not is_attacking:
		var distance_to_player = global_position.distance_to(player.global_position)
		if is_facing_player() and distance_to_player <= start_attack_range:
			# Start attack animation
			start_attack()

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Freeze movement during attack
	if not is_attacking:
		if is_on_floor():
			velocity.x = speed
			pace_distance += speed * delta
			if pace_distance >= max_pace_distance:
				direction = - direction
				pace_distance = 0

		if !raycast.is_colliding():
			# If the enemy would walk off the platform, make them turn around
			direction = - direction
			# And reset the pace distance
			pace_distance = 0
	else:
		# Stop horizontal movement during attack
		velocity.x = 0

	if velocity.x != 0:
		$Body.scale.x = sign(direction)
		
	velocity.x = speed * sign(direction)
	move_and_slide()

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