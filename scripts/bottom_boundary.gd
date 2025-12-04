extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_bottom_boundary_body_entered)

func _on_bottom_boundary_body_entered(body: Node2D) -> void:
	if body is Player or body is Enemy:
		body.die()
