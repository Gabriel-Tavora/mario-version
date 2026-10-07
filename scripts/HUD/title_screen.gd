extends Control

@export_file("*.tscn") var first_level := "res://scenes/fases/fase_1.tscn"
@export_file("*.tscn") var settings_scene := ""
## Nome da animação de círculo (iris) no AnimationPlayer da cena
@export var circle_animation := "circleAnim"

var menu = null
var circle_player: AnimationPlayer = null
var _starting := false


func _ready() -> void:
	get_tree().paused = false

	menu = _find_menu()
	if menu == null:
		push_error("MainMenu: não achei o nó do menu. Adicione um filho com o script menu.gd (de preferência chamado 'Menu').")
		return

	# Ordem das opções no Inspector do Menu: 1 = Jogar, 2 = Configurações, 3 = Sair
	menu.connect("option_1_selected", start_game)
	menu.connect("option_2_selected", open_settings)
	menu.connect("option_3_selected", quit_game)

	circle_player = _find_circle_player()

	# Quando o jogo inicia, o círculo ABRE (animação tocada ao contrário)
	await _circle_open()
	menu.open_menu()


func _find_menu() -> Node:
	var by_name := get_node_or_null("Menu")
	if by_name and by_name.has_method("open_menu"):
		return by_name

	for node in find_children("*", "Control", true, false):
		if node.has_method("open_menu"):
			return node

	return null


## Acha o AnimationPlayer que tem a animação do círculo
func _find_circle_player() -> AnimationPlayer:
	for node in find_children("*", "AnimationPlayer", true, false):
		var player := node as AnimationPlayer
		if player and player.has_animation(circle_animation):
			return player

	push_warning("MainMenu: não achei a animação '%s' em nenhum AnimationPlayer." % circle_animation)
	return null


## Toca a animação ao contrário (abre o círculo) e espera terminar
func _circle_open() -> void:
	if circle_player == null:
		return

	circle_player.play_backwards(circle_animation)
	circle_player.advance(0)  # aplica o primeiro frame já, sem piscar a tela
	await circle_player.animation_finished


## Toca a animação normal (fecha o círculo) e espera terminar
func _circle_close() -> void:
	if circle_player == null:
		return

	circle_player.play(circle_animation)
	await circle_player.animation_finished


func start_game() -> void:
	if first_level == "" or _starting:
		if first_level == "":
			push_warning("MainMenu: defina 'First Level' no Inspector.")
		return

	_starting = true
	await _circle_close()

	GameManager.new_game()
	get_tree().change_scene_to_file(first_level)


func open_settings() -> void:
	if settings_scene == "":
		push_warning("MainMenu: defina 'Settings Scene' no Inspector (ainda não existe).")
		return

	get_tree().change_scene_to_file(settings_scene)


func quit_game() -> void:
	get_tree().quit()
