extends Node3D

@onready var _atmosphere_display = $AtmosphereDisplay
@onready var _ui = $AtmosphereUI

var _atmosphere: Atmosphere


func _ready() -> void:
	_atmosphere = Atmosphere.new()
	_atmosphere_display.atmosphere = _atmosphere
	_ui.bind(_atmosphere)
	_ui.load_requested.connect(_on_atmosphere_loaded)


func _on_atmosphere_loaded(loaded: Atmosphere) -> void:
	_atmosphere = loaded
	_atmosphere_display.atmosphere = _atmosphere
	_ui.sync_from(_atmosphere)
