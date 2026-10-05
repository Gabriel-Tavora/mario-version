extends Node
## Autoload "ESP32Input": recebe os botões do ESP32 por UDP e os transforma
## em ações do Input Map (como se fosse o teclado).
##
## Project Settings -> Globals (Autoload) -> adicione este script como "ESP32Input".

const PORT := 4210
const TIMEOUT := 0.5  # sem pacotes por este tempo = solta todos os botões

# Letra enviada pelo ESP32 -> ações do Input Map que ela aciona.
# Nomes conferidos com o Input Map do projeto.
const ACTIONS := {
	"L": ["player_left", "ui_left"],
	"R": ["player_right", "ui_right"],
	"D": ["player_duck", "ui_down"],
	"U": ["ui_up"],
	"J": ["player_jump", "ui_accept"],
	"A": ["player_attack"],
	"B": ["player_run"],
	"P": ["pause"],
}

var _udp := PacketPeerUDP.new()
var _state := {}            # letra -> true/false (apertado)
var _last_packet_time := 0.0
var _warned := {}           # ações inexistentes já avisadas


func _ready() -> void:
	# Continua funcionando com o jogo pausado (menu de pause)
	process_mode = Node.PROCESS_MODE_ALWAYS

	var err := _udp.bind(PORT)
	if err != OK:
		push_error("ESP32Input: não consegui abrir a porta UDP %d (erro %d)" % [PORT, err])
	else:
		print("ESP32Input: ouvindo na porta UDP ", PORT)


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0

	while _udp.get_available_packet_count() > 0:
		var text := _udp.get_packet().get_string_from_utf8()
		_parse(text)
		_last_packet_time = now

	# Se o ESP32 sumir (bateria, WiFi), solta tudo para o Mario não ficar andando
	if not _state.is_empty() and now - _last_packet_time > TIMEOUT:
		_release_all()


## "L=0;R=1;D=0;J=1;" -> atualiza cada botão
func _parse(text: String) -> void:
	for pair in text.split(";", false):
		var kv := pair.split("=")
		if kv.size() != 2:
			continue
		_set_key(kv[0].strip_edges(), kv[1].strip_edges() == "1")


func _set_key(key: String, pressed: bool) -> void:
	if _state.get(key, false) == pressed:
		return  # nada mudou

	_state[key] = pressed

	for action in ACTIONS.get(key, []):
		if not InputMap.has_action(action):
			if not _warned.has(action):
				_warned[action] = true
				push_warning("ESP32Input: a ação '%s' não existe no Input Map" % action)
			continue

		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		event.strength = 1.0 if pressed else 0.0
		Input.parse_input_event(event)


func _release_all() -> void:
	for key in _state.keys():
		if _state[key]:
			_set_key(key, false)
