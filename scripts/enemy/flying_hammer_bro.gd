class_name HammerBro
extends Enemy
## Hammer Bro: fica parado, vira para o Mario e arremessa martelos em arco.
## Usa a MESMA cena do martelo do Mario (player_hammer.tscn), configurada
## para machucar o Mario e atravessar o cenário.
##
## A cena precisa dos mesmos nós de um goomba, pois a classe Enemy os exige:
## AnimatedSprite2D, PhysicsShape, StompArea, HurtArea e VisibleOnScreenNotifier2D.

const HAMMER_SCENE := preload("res://scenes/effects/player_hammer.tscn")

## true = sempre olha e joga na direção do Mario
@export var face_player := true
## Direção fixa quando face_player = false (1 direita, -1 esquerda)
@export var throw_direction := 1
## true = não usa gravidade (fica preso a uma plataforma)
@export var on_platform := false
## true = a arte do Hammer Bro olha para a ESQUERDA por padrão
@export var sprite_faces_left := false

## Tempo entre os arremessos (segundos) e variação aleatória
@export var throw_interval := 2.0
@export var throw_interval_random := 0.6
## Só joga se o Mario estiver a esta distância (px)
@export var detect_range := 220.0
## Velocidade do arremesso do martelo
@export var hammer_speed := 300.0

@export var idle_animation := "idle"
@export var throw_animation := "throw"
## Tempo da animação até o martelo sair da mão
@export var throw_delay := 0.2

const GRAVITY := 900.0

var _throw_timer := 0.0
var _throwing := false
var _player: Player = null


func _ready() -> void:
	# Se os nomes dos nós na cena forem diferentes, tenta achar pelo tipo/nome.
	# Se faltar algum nó essencial, avisa qual e desliga o inimigo (sem travar o jogo).
	if not _resolve_nodes():
		set_physics_process(false)
		return

	super()  # liga o pisão e o dano do Enemy
	_throw_timer = throw_interval


## Os nós que a classe Enemy exige. Os nomes padrão são:
## AnimatedSprite2D, PhysicsShape, StompArea, HurtArea, VisibleOnScreenNotifier2D.
func _resolve_nodes() -> bool:
	if sprite == null:
		sprite = _first_of_type("AnimatedSprite2D") as AnimatedSprite2D

	if visible_on_screen_notifier_2d == null:
		visible_on_screen_notifier_2d = _first_of_type("VisibleOnScreenNotifier2D") as VisibleOnScreenNotifier2D

	if physics_shape == null:
		for child in get_children():
			if child is CollisionShape2D:
				physics_shape = child as CollisionShape2D
				break

	for node in find_children("*", "Area2D", true, false):
		var area_name := String(node.name).to_lower()
		if stomp_area == null and area_name.contains("stomp"):
			stomp_area = node as Area2D
		elif hurt_area == null and (area_name.contains("hurt") or area_name.contains("hit")):
			hurt_area = node as Area2D

	var missing: PackedStringArray = []
	if sprite == null:
		missing.append("AnimatedSprite2D (o sprite precisa ser desse tipo)")
	if physics_shape == null:
		missing.append("PhysicsShape (CollisionShape2D filho direto)")
	if stomp_area == null:
		missing.append("StompArea (Area2D)")
	if hurt_area == null:
		missing.append("HurtArea (Area2D)")
	if visible_on_screen_notifier_2d == null:
		missing.append("VisibleOnScreenNotifier2D")

	if not missing.is_empty():
		push_error("HammerBro: faltam estes nós na cena: " + ", ".join(missing))
		return false

	return true


func _first_of_type(type_name: String) -> Node:
	var found := find_children("*", type_name, true, false)
	return found[0] if found.size() > 0 else null


func _physics_process(delta: float) -> void:
	# Morto: só cai (igual ao Enemy)
	if is_dead:
		velocity.y += GRAVITY * delta
		move_and_slide()
		if global_position.y > 1000.0:
			queue_free()
		return

	if not visible_on_screen_notifier_2d.is_on_screen():
		return

	if not on_platform:
		velocity.y += GRAVITY * delta
		move_and_slide()

	var player := _get_player()
	if player == null:
		return

	# Olha para o Mario (ou para a direção fixa)
	if face_player:
		dir = 1 if player.global_position.x > global_position.x else -1
	else:
		dir = throw_direction

	if sprite_faces_left:
		sprite.flip_h = dir > 0
	else:
		sprite.flip_h = dir < 0

	if global_position.distance_to(player.global_position) > detect_range:
		return

	_throw_timer -= delta
	if _throw_timer <= 0.0 and not _throwing:
		_throw_cycle()


## Anima, espera o ponto da mão e solta o martelo
func _throw_cycle() -> void:
	_throwing = true
	_throw_timer = throw_interval + randf_range(-throw_interval_random, throw_interval_random)

	if sprite.sprite_frames.has_animation(throw_animation):
		sprite.play(throw_animation)

	await get_tree().create_timer(throw_delay, false).timeout
	if is_dead:
		return

	throw_hammer()

	await get_tree().create_timer(0.3, false).timeout
	if not is_dead and sprite.sprite_frames.has_animation(idle_animation):
		sprite.play(idle_animation)

	_throwing = false


func throw_hammer() -> void:
	var hammer: PlayerHammer = HAMMER_SCENE.instantiate()

	# Configura ANTES de entrar na árvore (o _ready do martelo usa estes valores)
	hammer.hurts_player = true
	hammer.collides_with_world = false
	hammer.direction = dir
	hammer.throw_speed = hammer_speed

	get_parent().add_child(hammer)
	hammer.global_position = global_position - Vector2(0, 8)

	# Se quiser um som: crie play_hammer_throw() no SoundManager e chame aqui


func damage() -> void:
	die()


func _get_player() -> Player:
	if is_instance_valid(_player):
		return _player

	_player = get_tree().get_first_node_in_group("player") as Player
	if _player:
		return _player

	for node in get_tree().current_scene.find_children("*", "CharacterBody2D", true, false):
		if node is Player:
			_player = node as Player
			return _player

	return null


# Bola de fogo e martelo do Mario matam o Hammer Bro (retornam true se matou)
func take_fire_hit() -> bool:
	return _hit()


func take_hammer_hit() -> bool:
	return _hit()


func _hit() -> bool:
	if is_dead:
		return false
	die()
	return true
