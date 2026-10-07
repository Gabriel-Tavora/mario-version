extends Node
## Transição em círculo (iris) reutilizável. Anexe ao nó que contém o
## AnimationPlayer com a animação "circleAnim" (ex.: um CanvasLayer),
## dentro de CADA fase para o círculo abrir quando ela começa.
##
## Importante: no AnimationPlayer, deixe Autoplay vazio e Loop desligado.

@export var animation_name := "circleAnim"
## Abre o círculo automaticamente quando a cena começa
@export var open_on_start := true

var player: AnimationPlayer = null


func _ready() -> void:
	# O próprio nó ou um descendente com a animação
	player = self as AnimationPlayer
	if player == null:
		for node in find_children("*", "AnimationPlayer", true, false):
			var candidate := node as AnimationPlayer
			if candidate and candidate.has_animation(animation_name):
				player = candidate
				break

	if player == null:
		push_warning("CircleTransition: não achei a animação '%s'." % animation_name)
		return

	if open_on_start:
		open()


## Abre o círculo (animação ao contrário)
func open() -> void:
	if player == null:
		return
	player.play_backwards(animation_name)
	player.advance(0)
	await player.animation_finished


## Fecha o círculo (animação normal)
func close() -> void:
	if player == null:
		return
	player.play(animation_name)
	await player.animation_finished
