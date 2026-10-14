class_name PlayerHammer
extends CharacterBody2D
## Martelo arremessado pelo Mario Hammer.
##
## Cena player_hammer:
## player_hammer (CharacterBody2D)       <- este script
## ├── CollisionShape2D                  (CircleShape2D ~ raio 4) <- tira o aviso amarelo
## ├── Sprite2D
## │   └── Animation2 (AnimationPlayer com a animação "Spin")
## └── Hitbox (Area2D)                   (mask = inimigos e blocos)
##     └── CollisionShape2D

## Velocidade total do arremesso e ângulo (60° = sobe bastante e vai pra frente)
@export var throw_speed := 330.0
@export var throw_angle_deg := 60.0
@export var gravity := 900.0
@export var max_fall_speed := 400.0
## Quanto da velocidade sobra depois de quicar (0 = não quica, 1 = quica igual)
@export var bounce_damping := 0.55
@export var max_bounces := 3
@export var lifetime := 4.0

## Martelo de INIMIGO (ex.: Hammer Bro): machuca o Mario e ignora inimigos e blocos
@export var hurts_player := false
## false = atravessa o cenário em vez de quicar (martelo do Hammer Bro)
@export var collides_with_world := true

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: Area2D = $Hitbox

# Defina ANTES de add_child(): h.player = self; h.direction = 1 ou -1
var player: Player = null
var direction := 1

var _life := 0.0
var _bounces := 0
var _hit_blocks: Array[Node] = []


func _ready() -> void:
	# Só os martelos do Mario entram no limite de martelos na tela
	if not hurts_player:
		add_to_group("player_hammer")
	_life = lifetime

	# Nasce colado no Mario: sem isto ele empurra o Mario e quica na hora
	if is_instance_valid(player):
		add_collision_exception_with(player)
		player.add_collision_exception_with(self)

	# Arremesso em arco: sobe com o ângulo escolhido e depois cai com a gravidade
	var angle := deg_to_rad(throw_angle_deg)
	velocity = Vector2(
		cos(angle) * throw_speed * direction,
		-sin(angle) * throw_speed
	)
	if is_instance_valid(player):
		velocity.x += player.velocity.x * 0.3

	# Espelha o sprite (e o sentido do giro) quando joga pra esquerda
	sprite.scale.x = direction

	var players := find_children("*", "AnimationPlayer", true, false)
	if players.size() > 0:
		(players[0] as AnimationPlayer).play("Spin")

	hitbox.body_entered.connect(_on_target_entered)
	hitbox.area_entered.connect(_on_target_entered)


func _physics_process(delta: float) -> void:
	velocity.y = min(velocity.y + gravity * delta, max_fall_speed)

	if collides_with_world:
		var collision := move_and_collide(velocity * delta)
		if collision:
			_bounces += 1
			if _bounces > max_bounces:
				queue_free()
				return
			velocity = velocity.bounce(collision.get_normal()) * bounce_damping
	else:
		global_position += velocity * delta

	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_target_entered(target: Node) -> void:
	# Martelo de inimigo: só machuca o Mario, ignora o resto
	if hurts_player:
		if target is Player:
			target.die()
		return

	if target == player:
		return

	# Blocos: ativa uma vez por bloco
	if target is InteractableBlock:
		if target in _hit_blocks:
			return
		_hit_blocks.append(target)
		target.hit_by_player(player)
		return

	# Inimigos: o martelo continua voando depois de acertar
	var enemy := _find_enemy(target)
	if enemy == null:
		return

	# Inimigo já morrendo: passa direto
	if enemy.get("is_dead") == true:
		return

	if enemy.has_method("take_hammer_hit"):
		enemy.take_hammer_hit()
	else:
		enemy.take_fire_hit()


## O Area2D do inimigo pode ser filho do corpo principal
func _find_enemy(target: Node) -> Node:
	var candidates: Array[Node] = [target, target.owner, target.get_parent()]
	for c in candidates:
		if c and (c.has_method("take_hammer_hit") or c.has_method("take_fire_hit")):
			return c
	return null
