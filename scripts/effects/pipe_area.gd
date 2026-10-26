@icon("res://textures/Sprites/Editor/Icons/Pipe.png")
class_name WarpPipe
extends Node2D
## Cano de entrada E saída nas 4 direções.
##
## Estrutura da cena:
## WarpPipe (Node2D)       <- este script; posicione no CENTRO da boca do cano
## └── Hitbox (Area2D)     <- faixa fina na frente da boca do cano
##     └── CollisionShape2D   (mask = layer do Player)
##
## Onde colocar o Hitbox, conforme a direção:
##   DOWN  -> faixa em CIMA da boca (Mario em pé sobre o cano)
##   UP    -> faixa EMBAIXO da boca (Mario pula/fica sob o cano)
##   LEFT  -> faixa à DIREITA da boca (Mario anda para a esquerda)
##   RIGHT -> faixa à ESQUERDA da boca (Mario anda para a direita)
##
## Ida e volta (ex.: fase 1 <-> bônus):
##   Cano da fase 1:  pipe_id = "bonus_ida"   level_scene = bonus.tscn   target_pipe_id = "bonus_saida"
##   Cano do bônus:   pipe_id = "bonus_saida" level_scene = fase1.tscn   target_pipe_id = "volta_fase1"
##   Cano de saída na fase 1: pipe_id = "volta_fase1" (pode desmarcar Can Enter)
## Ao trocar de fase, o Mario sai do cano cujo pipe_id = target_pipe_id.

enum Direction { DOWN, UP, LEFT, RIGHT }

## Cano de destino guardado entre trocas de cena
static var _pending_exit_id := ""

## Para onde o Mario se move ao ENTRAR no cano (ao sair, vai no sentido contrário)
@export var direction: Direction = Direction.DOWN
## Fase para onde o cano leva
@export_file("*.tscn") var level_scene := ""

@export_group("Ligação entre canos")
## Nome deste cano (único na fase)
@export var pipe_id := ""
## Em qual cano da outra fase o Mario vai sair
@export var target_pipe_id := ""
## Desmarque para canos que só servem de saída
@export var can_enter := true
## Ajuste fino da posição final do Mario ao sair
@export var exit_offset := Vector2.ZERO

@export_group("Input")
@export var down_action := "player_duck"
@export var up_action := "player_jump"
@export var left_action := "player_left"
@export var right_action := "player_right"

@export_group("Ajustes")
## Quanto o Mario pode estar fora do centro (canos verticais) e ainda entrar
@export var center_tolerance := 8.0
## Duração da entrada/saída
@export var sink_time := 0.7
## Distância extra além do tamanho do Mario, para sumir por completo
@export var extra_sink := 4.0
## Z Index do Mario durante a entrada (menor que o do tilemap do cano)
@export var pipe_z_index := -2

@export_group("Animações")
## Animação em canos verticais
@export var face_forward_animation := "FaceForward"
## Animação em canos laterais
@export var side_animation := "Walk"

@onready var hitbox: Area2D = $Hitbox

var player: Player = null
var _used := false


func _ready() -> void:
	hitbox.body_entered.connect(_on_body_entered)
	hitbox.body_exited.connect(_on_body_exited)

	# Viemos de outra fase por um cano ligado a este?
	if pipe_id != "" and _pending_exit_id == pipe_id:
		_pending_exit_id = ""
		_used = true
		_exit_from_pipe.call_deferred()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player = body


func _on_body_exited(body: Node2D) -> void:
	if body == player:
		player = null


func _physics_process(_delta: float) -> void:
	if _used or not can_enter or player == null:
		return
	if player.is_power_down or player.is_dead:
		return

	if _can_enter() and Input.is_action_pressed(_get_action()):
		_enter()


func _can_enter() -> bool:
	var centered_x := absf(player.global_position.x - global_position.x) <= center_tolerance

	match direction:
		Direction.DOWN:
			return player.is_on_floor() and centered_x
		Direction.UP:
			return centered_x and player.global_position.y >= global_position.y - 2.0
		Direction.LEFT, Direction.RIGHT:
			return player.is_on_floor()
	return false


func _get_action() -> String:
	match direction:
		Direction.DOWN: return down_action
		Direction.UP: return up_action
		Direction.LEFT: return left_action
		_: return right_action


func _get_dir_vector() -> Vector2:
	match direction:
		Direction.DOWN: return Vector2.DOWN
		Direction.UP: return Vector2.UP
		Direction.LEFT: return Vector2.LEFT
		_: return Vector2.RIGHT


func _is_vertical() -> bool:
	return direction == Direction.DOWN or direction == Direction.UP


## Distância que o Mario percorre dentro do cano
func _sink_distance(p: Player) -> float:
	var shape := p.standing_shape.shape as RectangleShape2D
	var size := shape.size.y if _is_vertical() else shape.size.x
	return size + extra_sink


## Congela o Mario e escolhe a animação (entrada e saída)
func _freeze_player(p: Player) -> void:
	p.velocity = Vector2.ZERO
	p.set_physics_process(false)
	p.is_attacking = false
	if is_instance_valid(p.hammer):
		p.hammer.cancel()
	p.is_invulnerable = true
	p.z_index = pipe_z_index

	var anim := face_forward_animation
	if not _is_vertical():
		anim = side_animation

	p.animated_sprite.speed_scale = 1.0
	if p.animated_sprite.sprite_frames.has_animation(anim):
		p.animated_sprite.play(anim)


func _release_player(p: Player, old_z: int) -> void:
	p.z_index = old_z
	p.is_invulnerable = false
	p.set_physics_process(true)


# ============================================================
#  Entrada
# ============================================================

func _enter() -> void:
	_used = true

	var p := player
	var old_z := p.z_index

	_freeze_player(p)
	if _is_vertical():
		p.global_position.x = global_position.x
	else:
		p.animated_sprite.flip_h = direction == Direction.LEFT

	SoundManager.play_enter_pipe()

	var offset := _get_dir_vector() * _sink_distance(p)
	var tween := create_tween()
	tween.tween_property(p, "global_position", p.global_position + offset, sink_time)
	await tween.finished

	if level_scene != "":
		_pending_exit_id = target_pipe_id
		get_tree().change_scene_to_file(level_scene)
		return

	# Sem fase destino: desfaz tudo (útil para testar)
	p.global_position -= offset
	_release_player(p, old_z)
	_used = false


# ============================================================
#  Saída (chegando de outra fase)
# ============================================================

func _exit_from_pipe() -> void:
	var p := _find_player(get_tree().current_scene)
	if p == null:
		_used = false
		return

	var old_z := p.z_index
	var exit_dir := -_get_dir_vector()  # sai no sentido contrário ao de entrada
	var final_pos := _exit_position(p) + exit_offset
	var start_pos := final_pos - exit_dir * _sink_distance(p)

	_freeze_player(p)
	if not _is_vertical():
		p.animated_sprite.flip_h = exit_dir.x < 0.0
	p.global_position = start_pos

	# Câmera já começa no Mario (sem deslizar desde o início da fase)
	var cam := get_viewport().get_camera_2d()
	if cam:
		cam.reset_smoothing()

	SoundManager.play_enter_pipe()

	var tween := create_tween()
	tween.tween_property(p, "global_position", final_pos, sink_time)
	await tween.finished

	_release_player(p, old_z)
	_used = false


## Onde o Mario fica quando termina de sair, conforme a direção do cano
func _exit_position(p: Player) -> Vector2:
	var shape := p.standing_shape.shape as RectangleShape2D
	match direction:
		Direction.DOWN:
			# Cano virado para cima: termina em pé sobre a boca
			return Vector2(global_position.x, global_position.y - p.feet_offset)
		Direction.UP:
			# Cano virado para baixo: termina com a cabeça na boca e cai
			return Vector2(global_position.x, global_position.y + shape.size.y - p.feet_offset)
		Direction.LEFT:
			# Cano virado para a direita: termina logo à direita da boca
			return Vector2(global_position.x + shape.size.x / 2.0, global_position.y - p.feet_offset)
		_:
			# Cano virado para a esquerda: termina logo à esquerda da boca
			return Vector2(global_position.x - shape.size.x / 2.0, global_position.y - p.feet_offset)


func _find_player(node: Node) -> Player:
	if node is Player:
		return node
	for child in node.get_children():
		var found := _find_player(child)
		if found:
			return found
	return null
