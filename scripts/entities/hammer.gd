class_name HammerItem
extends CharacterBody2D
## Item coletável do martelo. Age como a FireFlower:
## sai do bloco, cai com gravidade e dá o poder ao tocar no Mario.
##
## Cena:
## Hammer (CharacterBody2D)  <- este script
## ├── CollisionShape2D
## ├── AnimatedSprite2D      (animação "idle")
## └── PickupArea (Area2D)
##     └── CollisionShape2D

@onready var pickup_area: Area2D = $PickupArea
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var gravity := 900.0
## Quantas voltas de 360° ele dá enquanto sai do bloco
@export var emerge_turns := 1


func _ready() -> void:
	pickup_area.body_entered.connect(_on_pickup_area_body_entered)
	sprite.play("idle")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if global_position.y > 1000:
		queue_free()

	move_and_slide()


## Chamado pelo bloco enquanto o item sobe/desce para fora dele.
## Gira o sprite 360° (emerge_turns voltas) durante `duration` segundos.
func play_emerge_spin(duration: float) -> void:
	sprite.rotation = 0.0

	var tween := create_tween()
	tween.tween_property(sprite, "rotation", TAU * emerge_turns, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		if is_instance_valid(sprite):
			sprite.rotation = 0.0)


func _on_pickup_area_body_entered(body: Node) -> void:
	if body is Player and body.can_collect_hammer():
		body.collect_hammer()
		queue_free()
