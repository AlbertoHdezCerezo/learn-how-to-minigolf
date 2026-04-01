extends GutTest

# -- Initialization --

func test_creating_state_machine_without_owner_returns_minus_one_as_current_state() -> void:
	var sm := StateMachine.new()
	assert_eq(sm.current_state(), -1, "current_state() should be -1 when not started")


func test_creating_state_machine_with_null_owner_returns_minus_one_as_current_state() -> void:
	var sm := StateMachine.new(null)
	assert_eq(sm.current_state(), -1, "current_state() should be -1 with null owner")


# -- add_state + start --

func test_starting_state_machine_sets_current_state_to_initial_state() -> void:
	var sm := StateMachine.new()
	sm.add_state(0, [1])
	sm.add_state(1, [0])
	sm.start(0)
	assert_eq(sm.current_state(), 0, "current_state() should be 0 after starting with state 0")


func test_starting_state_machine_emits_entering_and_entered_signals_on_initial_state() -> void:
	var sm := StateMachine.new()
	var state := sm.add_state(0)
	watch_signals(state)
	sm.start(0)
	assert_signal_emitted(state, "entering_state", "entering_state should fire when start() is called")
	assert_signal_emitted(state, "entered_state", "entered_state should fire when start() is called")


func test_starting_state_machine_calls_on_enter_callback_with_minus_one_as_from_state() -> void:
	var sm := StateMachine.new()
	var result := { "from": -99 }
	sm.add_state(0, [1], func(from: int): result["from"] = from)
	sm.start(0)
	assert_eq(result["from"], -1, "on_enter callback should receive -1 as from_state on initial start")


# -- transit --

func test_transiting_to_allowed_state_updates_current_state() -> void:
	var sm := StateMachine.new()
	sm.add_state(0, [1])
	sm.add_state(1, [0])
	sm.start(0)
	sm.transit(1)
	assert_eq(sm.current_state(), 1, "current_state() should be 1 after transiting from 0 to 1")


func test_transiting_emits_state_changed_signal_with_from_and_to_ids() -> void:
	var sm := StateMachine.new()
	sm.add_state(0, [1])
	sm.add_state(1, [0])
	sm.start(0)
	watch_signals(sm)
	sm.transit(1)
	assert_signal_emitted_with_parameters(sm, "state_changed", [0, 1])


func test_transiting_emits_entering_and_entered_signals_on_target_state() -> void:
	var sm := StateMachine.new()
	sm.add_state(0, [1])
	var state_1 := sm.add_state(1, [0])
	sm.start(0)
	watch_signals(state_1)
	sm.transit(1)
	assert_signal_emitted(state_1, "entering_state", "entering_state should fire on target state during transit")
	assert_signal_emitted(state_1, "entered_state", "entered_state should fire on target state during transit")


func test_transiting_calls_on_enter_callback_with_previous_state_id() -> void:
	var sm := StateMachine.new()
	sm.add_state(0, [1])
	var result := { "from": -99 }
	sm.add_state(1, [0], func(from: int): result["from"] = from)
	sm.start(0)
	sm.transit(1)
	assert_eq(result["from"], 0, "on_enter callback should receive 0 as from_state when transiting from state 0")


func test_transiting_to_disallowed_state_keeps_current_state_unchanged() -> void:
	var sm := StateMachine.new()
	sm.add_state(0, [1])
	sm.add_state(1, [])
	sm.add_state(2, [0])
	sm.start(0)
	sm.transit(2)
	assert_push_error("cannot transit from")
	assert_eq(sm.current_state(), 0, "current_state() should remain 0 after disallowed transit to state 2")


func test_transiting_before_start_keeps_state_uninitialized() -> void:
	var sm := StateMachine.new()
	sm.add_state(0, [1])
	sm.add_state(1, [0])
	sm.transit(1)
	assert_push_error("not started")
	assert_eq(sm.current_state(), -1, "current_state() should remain -1 when transit is called before start")


# -- is_in --

func test_is_in_returns_true_when_machine_is_in_queried_state() -> void:
	var sm := StateMachine.new()
	sm.add_state(0, [1])
	sm.add_state(1, [0])
	sm.start(0)
	assert_true(sm.is_in(0), "is_in(0) should be true when current state is 0")


func test_is_in_returns_false_when_machine_is_in_different_state() -> void:
	var sm := StateMachine.new()
	sm.add_state(0, [1])
	sm.add_state(1, [0])
	sm.start(0)
	assert_false(sm.is_in(1), "is_in(1) should be false when current state is 0")


func test_is_in_returns_false_when_machine_has_not_started() -> void:
	var sm := StateMachine.new()
	sm.add_state(0)
	assert_false(sm.is_in(0), "is_in(0) should be false before start() is called")


# -- get_state --

func test_get_state_returns_registered_state_with_correct_id_and_transitions() -> void:
	var sm := StateMachine.new()
	sm.add_state(0, [1, 2])
	var state := sm.get_state(0)
	assert_not_null(state, "get_state(0) should return a non-null StateMachineState")
	assert_eq(state.id, 0, "Returned state id should be 0")
	assert_eq(state.allowed_transitions, [1, 2] as Array[int], "Returned state allowed_transitions should be [1, 2]")


func test_get_state_returns_null_for_unregistered_state_id() -> void:
	var sm := StateMachine.new()
	assert_null(sm.get_state(99), "get_state(99) should return null for an unregistered state")


# -- StateMachineState.can_transit_to --

func test_state_can_transit_to_returns_true_for_allowed_transitions() -> void:
	var state := StateMachineState.new(0, [1, 2] as Array[int])
	assert_true(state.can_transit_to(1), "can_transit_to(1) should be true when 1 is in allowed_transitions")
	assert_true(state.can_transit_to(2), "can_transit_to(2) should be true when 2 is in allowed_transitions")


func test_state_can_transit_to_returns_false_for_disallowed_transitions() -> void:
	var state := StateMachineState.new(0, [1] as Array[int])
	assert_false(state.can_transit_to(2), "can_transit_to(2) should be false when 2 is not in allowed_transitions")


func test_state_can_transit_to_returns_false_for_all_when_no_transitions_allowed() -> void:
	var state := StateMachineState.new(0, [] as Array[int])
	assert_false(state.can_transit_to(0), "can_transit_to(0) should be false with empty allowed_transitions")
	assert_false(state.can_transit_to(1), "can_transit_to(1) should be false with empty allowed_transitions")
