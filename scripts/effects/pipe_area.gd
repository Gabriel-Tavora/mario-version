@icon("res://textures/Sprites/Editor/Icons/Pipe.png")
class_name WarpPipe
extends Node2D
## Cano de entrada (o Mario entra segurando agachar em cima dele).
##
## Estrutura da cena:
## WarpPipe (Node2D)       <- este script; posicione no CENTRO da boca do cano
## └── Hitbox (Area2D)     <- faixa fina em cima do cano
##     └── CollisionShape2D   (mask = layer do Player)
##
## O cano em si (visual e colisão) continua sendo o seu tile normal.

## Fase para onde o cano leva
@export_file("*.tscn") var level_scene := ""
## Ação que faz o Mario entrar (agachar)
@export var enter_action := "player_duck"
## Quanto o Mario pode estar fora do centro e ainda entrar (em px)
@export var center_tolerance := 8.0
## Duração da descida
@export var sink_time := 0.7
## Descida extra além da altura do Mario, para sumir por completo
@export var extra_sink := 4.0
## Z Index do Mario durante a descida (menor que o do tilemap do cano)
@export var pipe_z_index := -2
## Animação do Mario enquanto entra
@export var face_forward_animation := "FaceForward"

@onready var hitbox: Area2D = $Hitbox

var player: Player = null
var _used := false


func _ready() -> void:
	hitbox.body_entered.connect(_on_body_entered)
	hitbox.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player = body


func _on_body_exited(body: Node2D) -> void:
	if body == player:
		player = null


func _physics_process(_delta: float) -> void:
	if _used or player == null:
		return

	if not player.is_on_floor() or player.is_power_down:
		return

	if player.get("is_dead") == true:
		return

	if absf(player.global_position.x - global_position.x) > center_tolerance:
		return

	if Input.is_action_pressed(enter_action):
		_enter()


func _enter() -> void:
	_used = true

	var p := player
	var old_z := p.z_index

	# Congela os estados e a física do Mario durante a entrada
	p.velocity = Vector2.ZERO
	p.set_physics_process(false)
	p.is_invulnerable = true
	p.global_position.x = global_position.x
	p.z_index = pipe_z_index

	p.animated_sprite.speed_scale = 1.0
	if p.animated_sprite.sprite_frames.has_animation(face_forward_animation):
		p.animated_sprite.play(face_forward_animation)

	SoundManager.play_enter_pipe()

	# Desce para dentro do cano
	var shape := p.standing_shape.shape as RectangleShape2D
	var sink: float = shape.size.y + extra_sink
	var tween := create_tween()
	tween.tween_property(p, "global_position:y", p.global_position.y + sink, sink_time)
	await tween.finished

	if level_scene != "":
		get_tree().change_scene_to_file(level_scene)
		return

	# Sem fase destino configurada: desfaz tudo (útil para testar o cano)
	p.global_position.y -= sink
	p.z_index = old_z
	p.is_invulnerable = false
	p.set_physics_process(true)
	_used = false
