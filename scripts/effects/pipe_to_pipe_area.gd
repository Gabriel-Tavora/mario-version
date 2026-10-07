class_name PipeToPipeArea
extends Node2D
## Cano que leva o Mario a OUTRO cano da mesma fase.
## O Mario entra, some, viaja (em linha reta ou por um caminho) e sai no outro cano.
##
## Estrutura da cena:
## PipeToPipeArea (Node2D)    <- este script; no centro da boca do cano (na superfície)
## ├── Hitbox (Area2D)        <- faixa fina na boca do cano (mask = layer do Player)
## │   └── CollisionShape2D
## └── Path (Path2D)          <- OPCIONAL: caminho que o Mario segue dentro do cano
##
## Para ida e volta: configure os DOIS canos, cada um com o outro em
## "Connecting Pipe". Para mão única: marque "Exit Only" no cano de saída.

@export_enum("Up", "Down", "Left", "Right") var entering_direction := "Down"
## Cano de destino
@export var connecting_pipe: PipeToPipeArea = null
## Só serve de saída (o Mario não entra por ele)
@export var exit_only := false
## Velocidade da viagem dentro do cano (px/s)
@export var travel_speed := 200.0
## Duração de entrar/sair do cano
@export var sink_time := 0.5
## Descida extra além do tamanho do Mario, para sumir por completo
@export var extra_sink := 4.0
## Quanto o Mario pode estar fora do centro e ainda entrar (px)
@export var center_tolerance := 8.0
## Z Index do Mario ao entrar/sair (menor que o do tilemap do cano)
@export var pipe_z_index := -2
## Onde o Mario fica ao SAIR por este cano (relativo ao nó).
## (0, -15) = em pé na superfície, com o nó posicionado no topo do cano
@export var exit_offset := Vector2(0, -15)

@onready var hitbox: Area2D = $Hitbox
@onready var path_node: Path2D = get_node_or_null("Path")

# Trava global: só um cano em uso por vez
static var _busy := false

var player: Player = null
# Depois de usar, só reativa quando o botão for solto (evita entrar de novo)
var _locked := false


func _ready() -> void:
	hitbox.body_entered.connect(_on_body_entered)
	hitbox.body_exited.connect(_on_body_exited)

	# Sprite só de referência no editor
	var editor_sprite := get_node_or_null("Sprite")
	if editor_sprite:
		editor_sprite.hide()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player = body


func _on_body_exited(body: Node2D) -> void:
	if body == player:
		player = null


func _physics_process(_delta: float) -> void:
	if exit_only or connecting_pipe == null or player == null:
		return

	if PipeToPipeArea._busy:
		return

	if _locked:
		if not Input.is_action_pressed(_enter_action()):
			_locked = false
		return

	if player.is_power_down or player.get("is_dead") == true:
		return

	if entering_direction != "Up" and not player.is_on_floor():
		return

	if entering_direction == "Up" or entering_direction == "Down":
		if absf(player.global_position.x - global_position.x) > center_tolerance:
			return

	if Input.is_action_pressed(_enter_action()):
		_travel(player)


func _enter_action() -> String:
	match entering_direction:
		"Up":
			return "ui_up"        # você não tem "player_up": usa a seta (e o botão U do ESP32)
		"Left":
			return "player_left"
		"Right":
			return "player_right"
		_:
			return "player_duck"


## Direção em que o Mario se move para ENTRAR neste cano
func _enter_vector() -> Vector2:
	match entering_direction:
		"Up":
			return Vector2.UP
		"Left":
			return Vector2.LEFT
		"Right":
			return Vector2.RIGHT
		_:
			return Vector2.DOWN


func _sink_distance(p: Player, vec: Vector2) -> float:
	var shape := p.standing_shape.shape as RectangleShape2D
	var size: float = shape.size.x if absf(vec.x) > 0.0 else shape.size.y
	return size + extra_sink


## Animação do Mario enquanto se move para dentro/fora do cano
func _play_pipe_animation(p: Player, move_vec: Vector2) -> void:
	p.animated_sprite.speed_scale = 1.0
	var frames := p.animated_sprite.sprite_frames

	if absf(move_vec.x) > 0.0:
		p.animated_sprite.flip_h = move_vec.x < 0.0
		if frames.has_animation("Walk"):
			p.animated_sprite.play("Walk")
	elif frames.has_animation("FaceForward"):
		p.animated_sprite.play("FaceForward")


func _move_to(p: Player, target: Vector2, time: float) -> void:
	var tween := create_tween()
	tween.tween_property(p, "global_position", target, time)
	await tween.finished


func _travel(p: Player) -> void:
	PipeToPipeArea._busy = true

	var dest := connecting_pipe
	var old_z := p.z_index
	var old_layer := p.collision_layer

	# Congela o Mario (estados, física, colisões e dano)
	p.velocity = Vector2.ZERO
	p.set_physics_process(false)
	p.is_invulnerable = true
	p.collision_layer = 0
	p.z_index = pipe_z_index

	# 1) Entra neste cano
	var enter_vec := _enter_vector()
	if enter_vec.x == 0.0:
		p.global_position.x = global_position.x   # centraliza na boca do cano
	var inside := p.global_position + enter_vec * _sink_distance(p, enter_vec)

	_play_pipe_animation(p, enter_vec)
	SoundManager.play_enter_pipe()
	await _move_to(p, inside, sink_time)

	# 2) Viaja escondido até o outro cano
	p.hide()

	var dest_vec := dest._enter_vector()
	var dest_end := dest.global_position + dest.exit_offset
	var dest_start := dest_end + dest_vec * dest._sink_distance(p, dest_vec)

	await _follow_path(p, inside, dest_start)

	# 3) Sai pelo outro cano (movimento oposto ao de entrar nele)
	p.global_position = dest_start
	p.show()
	dest._play_pipe_animation(p, -dest_vec)
	SoundManager.play_enter_pipe()
	await _move_to(p, dest_end, sink_time)

	# 4) Devolve o controle
	p.z_index = old_z
	p.collision_layer = old_layer
	p.is_invulnerable = false
	p.velocity = Vector2.ZERO
	p.set_physics_process(true)
	p.state_machine.change_state(p.state_machine.idle)

	_locked = true
	dest._locked = true
	PipeToPipeArea._busy = false


## Segue o Path2D (se existir) ou vai em linha reta até o destino
func _follow_path(p: Player, from: Vector2, to: Vector2) -> void:
	if path_node != null and path_node.curve != null \
			and path_node.curve.get_baked_length() > 0.0:
		var curve := path_node.curve
		var length := curve.get_baked_length()
		var tween := create_tween()
		tween.tween_method(
			func(offset: float) -> void:
				p.global_position = path_node.to_global(curve.sample_baked(offset)),
			0.0, length, length / travel_speed
		)
		await tween.finished
	else:
		var time := maxf(from.distance_to(to) / travel_speed, 0.05)
		await _move_to(p, to, time)

	p.global_position = to
