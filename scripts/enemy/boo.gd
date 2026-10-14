class_name Boo
extends CharacterBody2D
## Boo: persegue o Mario quando ele olha para o OUTRO lado e se esconde
## (fica parado, tapando o rosto) quando o Mario olha para ele.
##
## Estrutura da cena:
## Boo (CharacterBody2D)            <- este script
## ├── AnimatedSprite2D             (animações: Chase, Hide e Turn)
## ├── HurtArea (Area2D)            (machuca o Mario; mask = layer do Player)
## │   └── CollisionShape2D
## └── VisibleOnScreenNotifier2D    (opcional: só persegue quando está na tela)
##
## O Boo voa atravessando paredes (não usa colisão com o cenário).
## Não pode ser pisado nem morto por fogo, martelo ou casco (como no SMW).

@export var move_speed := 50.0
## Quanto o Boo "flutua" para cima e para baixo ao se aproximar (px)
@export var wave_height := 4.0
## true = a arte do Boo olha para a ESQUERDA por padrão
@export var sprite_faces_left := true
@export var chase_animation := "Chase"
@export var hide_animation := "Hide"
@export var turn_animation := "Turn"
## Duração de cada metade da virada (antes e depois de espelhar o sprite)
@export var turn_time := 0.5
## Só se move enquanto estiver visível na tela
@export var only_when_on_screen := true

# Compatibilidade com fogo, martelo e casco (eles checam is_dead)
var is_dead := false

var hiding := false
var turning := false
var direction := 1   # lado do Mario em relação ao Boo: -1 esquerda, 1 direita
var wave := 0.0

var _facing := -1     # para onde o sprite está virado agora
var _player: Player = null
@onready var turn_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var hurt_area: Area2D = get_node_or_null("HurtArea")
@onready var screen_notifier: VisibleOnScreenNotifier2D = get_node_or_null("VisibleOnScreenNotifier2D")


func _ready() -> void:
	# Se os nomes na cena forem diferentes, pega o primeiro nó do tipo certo
	if sprite == null:
		sprite = _first_of_type("AnimatedSprite2D") as AnimatedSprite2D
	if hurt_area == null:
		hurt_area = _first_of_type("Area2D") as Area2D

	if sprite == null or hurt_area == null:
		push_error("Boo: a cena precisa de um AnimatedSprite2D e de uma Area2D (HurtArea).")
		set_physics_process(false)
		return

	hurt_area.body_entered.connect(_on_hurt_area_body_entered)

	_player = _find_player()
	if _player:
		direction = _direction_to_player()
		_facing = direction

	_apply_facing()
	_play(chase_animation)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if only_when_on_screen and screen_notifier and not screen_notifier.is_on_screen():
		return

	if not is_instance_valid(_player):
		_player = _find_player()
		if _player == null:
			return

	direction = _direction_to_player()
	wave += 16.0 * delta

	# O Mario olha para o Boo?  ->  o Boo se esconde
	var was_hiding := hiding
	hiding = _player_facing() != direction

	if was_hiding and not hiding:
		if turn_sound and not turn_sound.playing:
			turn_sound.play()

	var target := _player.global_position + Vector2(0, sin(wave) * wave_height)
	var direction_vector := global_position.direction_to(target)

	if hiding:
		velocity = velocity.lerp(Vector2.ZERO, delta * 10.0)
	else:
		velocity = velocity.lerp(move_speed * direction_vector, delta)

	# Virou de lado? Toca a animação de virar (sem travar a física)
	if _facing != direction and not turning:
		_turn()

	if not turning:
		_play(hide_animation if hiding else chase_animation)

	global_position += velocity * delta


## Para onde o Mario está olhando: -1 esquerda, 1 direita
func _player_facing() -> int:
	return -1 if _player.animated_sprite.flip_h else 1


## Lado do Mario em relação ao Boo
func _direction_to_player() -> int:
	return 1 if _player.global_position.x > global_position.x else -1


func _turn() -> void:
	turning = true

	if sprite.sprite_frames.has_animation(turn_animation):
		sprite.play(turn_animation)
		await get_tree().create_timer(turn_time, false).timeout

		_facing = direction
		_apply_facing()
		await get_tree().create_timer(turn_time, false).timeout
	else:
		# Sem animação de virar: espelha na hora
		_facing = direction
		_apply_facing()

	turning = false


func _apply_facing() -> void:
	if sprite_faces_left:
		sprite.flip_h = _facing < 0
	else:
		sprite.flip_h = _facing > 0


func _play(animation_name: String) -> void:
	if sprite.sprite_frames.has_animation(animation_name) \
			and sprite.animation != animation_name:
		sprite.play(animation_name)


func _first_of_type(type_name: String) -> Node:
	var found := find_children("*", type_name, true, false)
	return found[0] if found.size() > 0 else null


func _find_player() -> Player:
	var from_group := get_tree().get_first_node_in_group("player") as Player
	if from_group:
		return from_group

	for node in get_tree().current_scene.find_children("*", "CharacterBody2D", true, false):
		if node is Player:
			return node as Player

	return null


func _on_hurt_area_body_entered(body: Node2D) -> void:
	if is_dead:
		return

	if body is Player:
		body.die()


# --- Imune a tudo: a bola/martelo/casco só estouram nele (retornam false) ---

func take_fire_hit() -> bool:
	return false


func take_hammer_hit() -> bool:
	return false


func take_shell_hit() -> bool:
	return false
