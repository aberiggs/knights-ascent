extends CharacterBody2D

@export var raycast: RayCast2D
@export var animated_sprite: AnimatedSprite2D

@export var speed: float = 50.0
@export var max_pace_distance: float = 50.0
@export var start_attack_range: float = 8.0 # Distance in pixels to trigger an attack
@export var attack_range: float = 12.0 # Distance in pixels to apply damage
@export var damage_cooldown_time: float = 0.25 # Cooldown in seconds between damage applications

var pace_distance: float = 0.0
var direction: int = 1
var damage_cooldown: float = 0.0
var player: CharacterBody2D = null
var is_attacking: bool = false

func _ready() -> void:
	# Find the player in the scene tree
	var scene_root = get_tree().current_scene
	if scene_root:
		player = scene_root.get_node_or_null("Player")
	
	# Connect to animation finished signal if animated_sprite exists
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	# Update damage cooldown
	if damage_cooldown > 0:
		damage_cooldown -= delta
	
	# Check for player proximity and start attack animation
	# Do this early to prevent movement in the same frame as attack starts
	if player and damage_cooldown <= 0 and not is_attacking:
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

	scale.x = scale.y * direction
		
	move_and_slide()

func start_attack() -> void:
	"""Start the attack animation and freeze movement."""
	if animated_sprite and animated_sprite.sprite_frames.has_animation("attack"):
		is_attacking = true
		animated_sprite.play("attack")

func _on_animation_finished() -> void:
	"""Called when an animation finishes. Apply damage if attack animation finished."""
	if is_attacking and animated_sprite.animation == "attack":
		is_attacking = false
		
		# Check if player is still in range
		if player:
			var distance_to_player = global_position.distance_to(player.global_position)
			if is_facing_player() and distance_to_player <= attack_range:
				if player.has_method("apply_damage"):
					player.apply_damage()
		
		# Set cooldown and return to default animation
		damage_cooldown = damage_cooldown_time
		if animated_sprite.sprite_frames.has_animation("default"):
			animated_sprite.play("default")

func is_facing_player() -> bool:
	if player:
		return (direction > 0 and global_position.x < player.global_position.x) or (direction < 0 and global_position.x > player.global_position.x)
	return false