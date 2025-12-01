extends CharacterBody2D

@export var raycast: RayCast2D

@export var speed: float = 50.0
@export var max_pace_distance: float = 50.0
@export var start_attack_range: float = 8.0 # Distance in pixels to trigger an attack

var pace_distance: float = 0.0
var direction: int = 1
var player: CharacterBody2D = null
var is_attacking: bool = false

func _ready() -> void:
	add_to_group("enemies")

	# Find the player in the scene tree
	var scene_root = get_tree().current_scene
	if scene_root:
		player = scene_root.get_node_or_null("Player")
	
	# Connect to animation finished signal if animation player exists
	if $Body/AnimationPlayer:
		$Body/AnimationPlayer.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	# Check for player proximity and start attack animation
	# Do this early to prevent movement in the same frame as attack starts
	if player and not is_attacking:
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
			velocity.x = speed * direction
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
		$Body.scale.x = sign(velocity.x)
		
	move_and_slide()

func start_attack() -> void:
	"""Start the attack animation and freeze movement."""
	if $Body/AnimationPlayer and $Body/AnimationPlayer.has_animation("attack"):
		is_attacking = true
		$Body/AnimationPlayer.play("attack")
		$Body/AttackHitbox.monitoring = true

func _on_animation_finished(anim_name: String) -> void:
	"""Called when an animation finishes. Apply damage if attack animation finished."""
	if $Body/AnimationPlayer and $Body/AnimationPlayer.has_animation("idle"):
		$Body/AnimationPlayer.play("idle")


	if is_attacking and anim_name == "attack":
		is_attacking = false
		$Body/AttackHitbox.monitoring = false

func is_facing_player() -> bool:
	if player:
		return (direction > 0 and global_position.x < player.global_position.x) or (direction < 0 and global_position.x > player.global_position.x)
	return false

func apply_damage() -> void:
	"""Apply damage to the enemy."""
	# TODO: Implement proper damage logic
	# For now, delete the enemy	
	queue_free()

func perform_attack_hitcheck() -> void:
	"""Perform a hit check for the attack."""
	var hitbox = $Body/AttackHitbox

	var overlapping_bodies = hitbox.get_overlapping_bodies()
	for body in overlapping_bodies:
		# TODO: Maybe handle through a class/inferface later?
		if body.is_in_group("player"):
			body.apply_damage()