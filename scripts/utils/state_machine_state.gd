class_name StateMachineState
extends RefCounted

## A single state in a StateMachine.
##
## Each state is identified by an int (typically an enum value). It has a set
## of states it can transition to, and an optional callback that runs when
## entered. Two signals allow external code to hook into the lifecycle:
##
##   sm.get_state(State.IDLE).entered_state.connect(func(from: int):
##       print("entered idle from ", from)
##   )
##
## Both signals and the callback receive the previous state as an int.
##
## [signal entering_state] emits before the on_enter callback runs.
## [signal entered_state] emits after the on_enter callback completes.

signal entering_state(from_state: int)
signal entered_state(from_state: int)

var id: int
var allowed_transitions: Array[int]
var _on_enter: Callable


## [param state_id] Integer identifying this state (typically an enum value).
## [param transitions] Array of state ids this state is allowed to transition to.
## [param on_enter] Optional callback invoked when entering this state.
##   Receives the previous state id as its argument.
func _init(state_id: int, transitions: Array[int] = [], on_enter: Callable = Callable()) -> void:
	id = state_id
	allowed_transitions = transitions
	_on_enter = on_enter


## Returns true if this state is allowed to transition to [param target].
func can_transit_to(target: int) -> bool:
	return target in allowed_transitions


## Runs the enter lifecycle: emits entering_state, calls the on_enter
## callback (if provided), then emits entered_state.
## [param from_state] The id of the state we are transitioning from.
func enter(from_state: int = -1) -> void:
	entering_state.emit(from_state)
	if _on_enter.is_valid(): _on_enter.call(from_state)
	entered_state.emit(from_state)
