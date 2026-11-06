class_name RoundRain
extends Control
## Brief view-only rain. Tween-driven drawing never consumes the rules RNG.
signal finished
var active: bool = false
var _phase: float = 0
var _motion: Tween
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()
func start(duration: float) -> void:
	if _motion != null: _motion.kill()
	active = true
	_phase = 0
	show()
	_motion = create_tween()
	_motion.tween_method(_set_phase, 0.0, 1.0, maxf(0.05, duration))
	_motion.tween_callback(_finish)
func _set_phase(value: float) -> void:
	_phase = value
	queue_redraw()
func _finish() -> void:
	active = false
	hide()
	finished.emit()
func _draw() -> void:
	var top: float = minf(200, size.y * 0.25)
	var height: float = maxf(1, size.y * 0.71 - top)
	var opacity: float = sin(_phase * PI) * 0.62
	for index in range(100):
		var x: float = fposmod(index * 137.3 - _phase * 110, size.x)
		var y: float = top + fposmod(index * 59.7 + _phase * 650, height)
		var length: float = 12 + (index % 4) * 5
		draw_line(Vector2(x, y), Vector2(x - 6, minf(top + height, y + length)), Color(0.76, 0.87, 0.88, opacity), 1.2, true)
