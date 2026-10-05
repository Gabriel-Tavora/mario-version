class_name Hammer
extends Area2D
## Cena do martelo. Estrutura esperada:
##
## Hammer (Area2D)  <- este script
## ├── CollisionShape2D
## ├── GPUParticles2D   (nome: Particles | One Shot = true | Local Coords = false)
## └── AudioStreamPlayer2D (nome: HitSound, opcional)
##
## Fica como filho do Player. O player chama setup() no _ready().

signal hit(target: Node)

## Frames da animação "Attack" em que a hitbox fica ligada,
## e a posição da hitbox (relativa ao Player, olhando pra direita) em cada um.
@export var hit_frames: Dictionary = {
	3: Vector2(14, -8),
	4: Vector2(18, 2),
}
## Frame em que as partículas disparam.
@export var particle_frame: int = 4
@export var attack_animation: StringName = &"Attack"

@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var particles: GPUParticles2D = $Particles
@onready var hit_sound: AudioStreamPlayer2D = get_node_or_null("HitSound")

var player: Player
var sprite: AnimatedSprite2D
var is_attacking := false
var _already_hit: Array[Node] = []


func _ready() -> void:
	shape.disabled = true
	monitoring = true
	body_entered.connect(_on_target_entered)
	area_entered.connect(_on_target_entered)


## Chame uma vez no _ready() do Player: hammer.setup(self, animated_sprite)
func setup(p_player: Player, p_sprite: AnimatedSprite2D) -> void:
	player = p_player
	sprite = p_sprite
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.animation_changed.connect(_on_animation_changed)


## Inicia o golpe. Retorna false se já estiver atacando.
func start_attack() -> bool:
	if is_attacking:
		return false

	is_attacking = true
	_already_hit.clear()
	sprite.play(attack_animation)
	return true


## Chame no die() e no power_down() do Player.
func cancel() -> void:
	is_attacking = false
	_already_hit.clear()
	shape.set_deferred("disabled", true)
	particles.emitting = false


func _on_frame_changed() -> void:
	if sprite.animation != attack_animation:
		return

	var f := sprite.frame
	var active := hit_frames.has(f)
	shape.set_deferred("disabled", not active)

	if active:
		var offset: Vector2 = hit_frames[f]
		# Espelha a posição quando o Mario olha pra esquerda
		if sprite.flip_h:
			offset.x = -offset.x
		position = offset

	if f == particle_frame:
		particles.global_position = global_position
		particles.restart()
		particles.emitting = true
		if hit_sound:
			hit_sound.play()


func _on_animation_finished() -> void:
	if sprite.animation == attack_animation:
		cancel()


func _on_animation_changed() -> void:
	# Se outra animação interromper o ataque, desliga tudo
	if is_attacking and sprite.animation != attack_animation:
		cancel()


func _on_target_entered(target: Node) -> void:
	if target == player or target in _already_hit:
		return

	_already_hit.append(target)

	if target is InteractableBlock:
		target.hit_by_player(player)
	elif target.has_method("take_hammer_hit"):
		target.take_hammer_hit()
	elif target.get_parent() and target.get_parent().has_method("take_hammer_hit"):
		# Caso o Area2D do inimigo seja filho do corpo principal
		target.get_parent().take_hammer_hit()

	hit.emit(target)
