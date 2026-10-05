class_name PlayerHammer
extends CharacterBody2D
## Martelo arremessado pelo Mario Hammer.
##
## Cena player_hammer:
## PlayerHammer (CharacterBody2D)
## ├── CollisionShape2D
## ├── Sprite2D
## │   └── Animation2 (AnimationPlayer)
## ├── Hitbox (Area2D)
## │   └── CollisionShape2D
## └── VisibleOnScreenNotifier2D

@export var throw_speed := 330.0
@export var throw_angle_deg := 60.0
@export var gravity := 900.0
@export var max_fall_speed := 400.0
@export var bounce_damping := 0.55
@export var max_bounces := 3
@export var lifetime := 4.0

const MAX_HAMMERS := 4

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

var player: Player = null
var direction := 1

var _life := 0.0
var _bounces := 0
var _hit_blocks: Array[Node] = []
var _hit_enemies: Array[Node] = []


func _ready() -> void:
	add_to_group("player_hammer")

	var hammers := get_tree().get_nodes_in_group("player_hammer")

	if hammers.size() > MAX_HAMMERS:
		queue_free()
		return

	_life = lifetime

	if is_instance_valid(player):
		add_collision_exception_with(player)
		player.add_collision_exception_with(self)

	var angle := deg_to_rad(throw_angle_deg)

	velocity = Vector2(
		cos(angle) * throw_speed * direction,
		-sin(angle) * throw_speed
	)

	if is_instance_valid(player):
		velocity.x += player.velocity.x * 0.3

	sprite.scale.x = direction

	var players := find_children("*", "AnimationPlayer", true, false)

	if players.size() > 0:
		var animation_player := players[0] as AnimationPlayer
		animation_player.play("Spin")

	hitbox.body_entered.connect(_on_target_entered)
	hitbox.area_entered.connect(_on_target_entered)

	screen_notifier.screen_exited.connect(_on_screen_exited)


func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta

	if velocity.y > max_fall_speed:
		velocity.y = max_fall_speed

	var collision := move_and_collide(velocity * delta)

	if collision:
		_bounces += 1

		if _bounces > max_bounces:
			queue_free()
			return

		velocity = velocity.bounce(collision.get_normal())
		velocity *= bounce_damping

	_life -= delta

	if _life <= 0.0:
		queue_free()


func _on_target_entered(target: Node) -> void:
	if target == player:
		return

	if target is InteractableBlock:
		if _hit_blocks.has(target):
			return

		_hit_blocks.append(target)
		target.hit_by_player(player)
		return

	var enemy := _find_enemy(target)

	if not is_instance_valid(enemy):
		return

	if _hit_enemies.has(enemy):
		return

	if enemy.get("is_dead"):
		return

	_hit_enemies.append(enemy)

	if enemy.has_method("take_hammer_hit"):
		enemy.take_hammer_hit()
	elif enemy.has_method("take_fire_hit"):
		enemy.take_fire_hit()


func _find_enemy(target: Node) -> Node:
	var candidates: Array[Node] = []

	if is_instance_valid(target):
		candidates.append(target)

	if is_instance_valid(target.owner):
		candidates.append(target.owner)

	if is_instance_valid(target.get_parent()):
		candidates.append(target.get_parent())

	for candidate in candidates:
		if candidate.has_method("take_hammer_hit"):
			return candidate

		if candidate.has_method("take_fire_hit"):
			return candidate

	return null


func _on_screen_exited() -> void:
	queue_free()
