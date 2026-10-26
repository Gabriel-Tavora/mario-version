class_name PlayerStateMachine
extends Node
## Gerencia os estados do Mario. Cada filho é um PlayerState.

@onready var dead: PlayerState = $Dead
@onready var idle: PlayerState = $Idle
@onready var run: PlayerState = $Run
@onready var air: PlayerState = $Air
@onready var duck: PlayerState = $Duck
@onready var skid: PlayerState = $Skid
@onready var spin_jump: PlayerState = $SpinJump
@onready var ground_pound: PlayerState = $GroundPound
@onready var slide: PlayerState = $Slide

var current_state: PlayerState
var player: Player


func init(p: Player) -> void:
	player = p
	for child in get_children():
		if child is PlayerState:
			child.player = p
			child.state_machine = self
	change_state(idle)


func change_state(new_state: PlayerState) -> void:
	if new_state == null or new_state == current_state:
		return
	if current_state:
		current_state.exit()
	current_state = new_state
	current_state.enter()


func process_physics(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)
