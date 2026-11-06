class_name IntegrityReadout
extends Control
## One progress dial: committed Progress + live round Integrity, never model health.
const IVORY := Color(0.96, 0.92, 0.79)
const BRASS := Color(0.83, 0.68, 0.42)
var value: int = 0
var target: int = 250
var round_value: int = 0
var reading: float = 0.0
var _needle_motion: Tween
var _initialized: bool = false
var _pulse: float = 0
var _delta: String = ""
var _motion: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func present(amount: int, maximum: int = 250, current_round: int = 0) -> void:
	target = maxi(1, maximum)
	round_value = current_round
	if _initialized and amount != value:
		pulse(amount - value)
		if _needle_motion != null: _needle_motion.kill()
		_needle_motion = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_needle_motion.tween_method(_set_reading, reading, float(amount), 0.45)
	elif not _initialized:
		reading = amount
	value = amount
	_initialized = true
	queue_redraw()

func _set_reading(amount: float) -> void:
	reading = amount
	queue_redraw()

func reset() -> void:
	if _motion != null: _motion.kill()
	if _needle_motion != null: _needle_motion.kill()
	reading = 0
	value = 0
	round_value = 0
	_initialized = false
	_pulse = 0
	_delta = ""

func _set_pulse(amount: float) -> void:
	_pulse = amount
	queue_redraw()

func _text(at: Vector2, text: String, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(0.06, 0.09, 0.08, 0.9))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _centered(at: Vector2, text: String, font_size: int, color: Color) -> void:
	var width: float = ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_text(at - Vector2(width * 0.5, 0), text, font_size, color)

func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.5 - 6
	var scale: float = radius / 100.0
	draw_circle(center + Vector2(1, 3), radius + 3, Color(0.035, 0.05, 0.04, 0.45))
	draw_circle(center, radius, BrassTrim.DARK)
	draw_arc(center, radius, 0, TAU, 96, BrassTrim.GOLD, 2.5, true)
	draw_arc(center, radius - 4, 0, TAU, 96, Color(BrassTrim.HIGHLIGHT, 0.5), 1, true)
	for tick in range(40):
		var angle: float = tick * TAU / 40.0
		var length: float = 9 if tick % 5 == 0 else 4
		var direction := Vector2(cos(angle), sin(angle))
		draw_line(center + direction * (radius - 7), center + direction * (radius - 7 - length), BrassTrim.GOLD, 1, true)
	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var screw: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius
		draw_circle(screw, 4 * scale, BrassTrim.GOLD)
		draw_line(screw - Vector2(2, 0), screw + Vector2(2, 0), BrassTrim.DARK, 1, true)
	var shield_center: Vector2 = center + Vector2(0, -58 * scale)
	draw_polyline(PackedVector2Array([shield_center + Vector2(-10, -6) * scale, shield_center + Vector2(10, -6) * scale, shield_center + Vector2(9, 7) * scale, shield_center + Vector2(0, 16) * scale, shield_center + Vector2(-9, 7) * scale, shield_center + Vector2(-10, -6) * scale]), BRASS, 1.4, true)
	_centered(center + Vector2(0, -30 * scale), "INTEGRITY", roundi(18 * scale), IVORY)
	_centered(center + Vector2(0, 5 * scale), str(value), roundi(34 * scale), IVORY)
	_centered(center + Vector2(0, 27 * scale), "/ %d" % target, roundi(16 * scale), BRASS)
	_centered(center + Vector2(0, 48 * scale), "ROUND %d" % round_value, roundi(15 * scale), IVORY)
	if _pulse > 0:
		_centered(center + Vector2(0, 68 * scale), _delta, roundi(16 * scale), Color(BRASS, _pulse))
	var fraction: float = clampf(reading / target, 0, 1)
	var needle: float = -PI * 0.5 + fraction * TAU
	if fraction > 0:
		draw_arc(center, radius - 19 * scale, -PI * 0.5, needle, 96, BRASS, 3 * scale, true)
	var direction := Vector2(cos(needle), sin(needle))
	draw_line(center + direction * (radius - 8 * scale), center + direction * (radius - 28 * scale), IVORY, 2.5 * scale, true)



func pulse(delta: int) -> void:
	_delta = "%+d" % delta
	if _motion != null: _motion.kill()
	_pulse = 1.0
	_motion = create_tween()
	_motion.tween_method(_set_pulse, 1.0, 0.0, 0.85)
	queue_redraw()
