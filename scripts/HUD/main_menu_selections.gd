extends Control
## Menu reutilizável (tela inicial, game over, escolha de fase...).
## Monta as opções a partir de listas e avisa por sinais qual foi escolhida.
##
## Estrutura esperada da cena:
## Menu (Control)                     <- este script
## └── VBoxContainer
##     └── Selection1                 <- MODELO: é duplicado para cada opção e depois removido
##         ├── BaseLabel (Label)      <- texto da opção
##         └── TextureRect            <- a seta (aparece só na opção selecionada)
##
## Uso:
##   $Menu.options = ["Jogar", "Opções", "Sair"]
##   $Menu.option_1_selected.connect(_on_play)     # ou option_selected(index)

signal option_selected(index: int)   # 0, 1, 2... (mais genérico)
signal option_1_selected
signal option_2_selected
signal option_3_selected
signal option_4_selected
signal option_5_selected
signal option_6_selected
signal menu_exited

@export var options: Array[String] = []
## Cor de cada opção (se faltar, usa branco)
@export var option_colours: Array[Color] = []
## Permite sair do menu com a ação de voltar
@export var can_exit := false
## Atenção: "ui_cancel" usa Escape, a mesma tecla da ação "pause".
## Dentro do menu de pause, escolha outra ação.
@export var back_action := "ui_cancel"
@export var initial_active := false
## Navegação circular (descer na última volta para a primeira)
@export var wrap_around := true
## Continua funcionando com o jogo pausado
@export var work_while_paused := true

var active := false
var selected_index := 0
var option_nodes: Array[Control] = []

@onready var container: VBoxContainer = $VBoxContainer
@onready var template: Control = $VBoxContainer/Selection1


func _ready() -> void:
	if work_while_paused:
		process_mode = Node.PROCESS_MODE_ALWAYS

	for i in options.size():
		if options[i] == "":
			continue

		var colour := option_colours[i] if i < option_colours.size() else Color.WHITE
		_add_option_node(options[i], colour)

	template.queue_free()
	_update_selection()

	if initial_active:
		open_menu()
	else:
		close_menu()


func _add_option_node(text: String, colour: Color) -> void:
	var node := template.duplicate() as Control

	var label := node.get_node_or_null("BaseLabel") as Label
	if label:
		label.text = text
		label.modulate = colour

	option_nodes.append(node)
	container.add_child(node)


func _process(_delta: float) -> void:
	if not active:
		return

	var previous := selected_index

	if Input.is_action_just_pressed("ui_down"):
		selected_index += 1
	if Input.is_action_just_pressed("ui_up"):
		selected_index -= 1

	if not option_nodes.is_empty():
		if wrap_around:
			selected_index = posmod(selected_index, option_nodes.size())
		else:
			selected_index = clampi(selected_index, 0, option_nodes.size() - 1)

	if selected_index != previous:
		_update_selection()

	if can_exit and InputMap.has_action(back_action) \
			and Input.is_action_just_pressed(back_action):
		exit()
		return

	if Input.is_action_just_pressed("ui_accept"):
		_accept()


## Mostra a seta só na opção selecionada
func _update_selection() -> void:
	for i in option_nodes.size():
		var arrow := option_nodes[i].get_node_or_null("TextureRect") as CanvasItem
		if arrow:
			arrow.modulate.a = 1.0 if i == selected_index else 0.0


func _accept() -> void:
	if option_nodes.is_empty():
		return

	SoundManager.play_coin()
	option_selected.emit(selected_index)

	# Sinais numerados (1 a 6), mantidos por compatibilidade
	var number := selected_index + 1
	if number <= 6:
		emit_signal("option_%d_selected" % number)


func open_menu() -> void:
	selected_index = 0
	_update_selection()
	show()

	# Espera um frame para o mesmo clique que abriu não selecionar uma opção
	await get_tree().physics_frame
	active = true


func exit() -> void:
	SoundManager.play_bump()
	close_menu()
	menu_exited.emit()


func close_menu() -> void:
	hide()
	active = false
