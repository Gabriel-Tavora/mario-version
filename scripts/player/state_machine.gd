class_name StateMachine
extends Node

@export var initial_state: State
var current_state: State

@onready var idle: State = $Idle
@onready var run: State = $Run
@onready var air: State = $Air
@onready var duck: State = $Duck
@onready var skid: State = $Skid
@onready var dead: State = $Dead
@onready var spin_jump: State = $SpinJump

func init(player: Player) -> void:
	for child in get_children():
		if child is State:
			child.player = player
			child.state_machine = self

	if initial_state:
		change_state(initial_state)

func change_state(new_state: State) -> void:
	if current_state == new_state:
		return

	if current_state:
		current_state.exit()

	current_state = new_state
	current_state.enter()

func process_physics(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)
