class_name StateMachine
extends RefCounted

## A simple state machine that manages transitions between StateMachineStates.
##
## States are identified by int values (typically enum members). The owner's
## `State` enum is discovered automatically for readable error messages.
##
## Usage:
##   enum State { IDLE, AIMING, BLOCKED }
##
##   var sm := StateMachine.new(self)
##   sm.add_state(State.IDLE, [State.AIMING])
##   sm.add_state(State.AIMING, [State.IDLE, State.BLOCKED], func(from: int):
##       print("now aiming, came from ", from)
##   )
##   sm.add_state(State.BLOCKED, [State.IDLE])
##   sm.start(State.IDLE)
##   sm.transit(State.AIMING)  # works
##   sm.transit(State.BLOCKED) # error — AIMING does not allow IDLE → BLOCKED

signal state_changed(from_state: int, to_state: int)

var _states: Dictionary = {}
var _current: StateMachineState = null
var _enum: Dictionary = {}


## [param owner] The object that defines the State enum. The enum is
## discovered via get_script().get_script_constant_map()["State"].
func _init(owner: Object = null) -> void:
	if owner == null: return
	if not owner.get_script():
		push_error("StateMachine: owner '%s' has no script attached." % owner)
		return
	var constants: Dictionary = owner.get_script().get_script_constant_map()
	if "State" not in constants:
		push_error("StateMachine: owner script '%s' does not define an enum 'State'." % owner.get_script().resource_path)
		return
	_enum = constants["State"]


## Registers a state. Must be called before [method start].
## [param state_id] Integer identifying the state (typically an enum value).
## [param transitions] States this state can transition to.
## [param on_enter] Optional callback when entering this state.
## Returns the created StateMachineState so signals can be connected.
func add_state(state_id: int, transitions: Array[int] = [], on_enter: Callable = Callable()) -> StateMachineState:
	var state := StateMachineState.new(state_id, transitions, on_enter)
	_states[state_id] = state
	return state


## Sets the initial state and runs its enter lifecycle.
## Must be called once before any [method transit] calls.
func start(state_id: int) -> void:
	if state_id not in _states:
		push_error("StateMachine: unknown state %s" % _name_of(state_id))
		return
	_current = _states[state_id]
	_current.enter()


## Transitions from the current state to [param target_id].
## Logs an error if: the machine hasn't started, the target state doesn't
## exist, or the current state doesn't allow the transition.
func transit(target_id: int) -> void:
	if _current == null:
		push_error("StateMachine: not started. Call start() first.")
		return
	if target_id not in _states:
		push_error("StateMachine: unknown state %s" % _name_of(target_id))
		return
	if not _current.can_transit_to(target_id):
		push_error("StateMachine: cannot transit from %s to %s. Allowed: %s" % [
			_name_of(_current.id), _name_of(target_id),
			_names_of(_current.allowed_transitions)
		])
		return

	var from := _current.id
	_current = _states[target_id]
	_current.enter(from)
	state_changed.emit(from, target_id)


## Returns the id of the current state, or -1 if not started.
func current_state() -> int:
	return _current.id if _current else -1


## Returns the StateMachineState for [param state_id], or null if not found.
func get_state(state_id: int) -> StateMachineState:
	return _states.get(state_id)


## Returns true if the current state matches [param state_id].
func is_in(state_id: int) -> bool:
	return _current != null and _current.id == state_id


func _name_of(state_id: int) -> String:
	return _enum.find_key(state_id) if _enum.find_key(state_id) else str(state_id)


func _names_of(state_ids: Array[int]) -> String:
	var names: Array[String] = []
	for id in state_ids: names.append(_name_of(id))
	return "[%s]" % ", ".join(names)
