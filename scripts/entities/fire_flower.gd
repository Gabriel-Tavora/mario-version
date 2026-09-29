class_name FireFlower
extends CharacterBody2D

@onready var pickup_area: Area2D = $PickupArea
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	pickup_area.body_entered.connect(_on_pickup_area_body_entered)

func _on_pickup_area_body_entered(body: Node) -> void:
	if body is Player:
		body.collect_fire_flower()
		queue_free()
