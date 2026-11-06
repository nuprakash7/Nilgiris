class_name InstrumentSymbol
extends Control
## Small line-work symbols; replaced independently of text and gameplay.
@export var kind: String = "coin"
const INK := Color(0.86, 0.73, 0.48)
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(26, 26)
func _draw() -> void:
	var c := size * 0.5
	match kind:
		"settings":
			draw_arc(c, 7, 0, TAU, 32, INK, 1.5, true)
			draw_arc(c, 3, 0, TAU, 24, INK, 1.4, true)
			for index in range(8):
				var direction := Vector2(cos(index * TAU / 8), sin(index * TAU / 8))
				draw_line(c + direction * 7, c + direction * 11, INK, 2, true)
		"coin":
			var radius: float = minf(size.x, size.y) * 0.35
			draw_arc(c, radius, 0, TAU, 48, INK, maxf(1.6, radius * 0.14), true)
			draw_arc(c, radius * 0.67, 0, TAU, 40, INK, maxf(0.8, radius * 0.07), true)
		"clock":
			draw_arc(c, 9, 0, TAU, 32, INK, 1.3, true)
			draw_line(c, c + Vector2(0, -6), INK, 1.5, true)
			draw_line(c, c + Vector2(5, 2), INK, 1.5, true)
		"draw", "discard", "search":
			draw_rect(Rect2(c - Vector2(9, 7), Vector2(12, 16)), INK, false, 1.2)
			draw_rect(Rect2(c - Vector2(4, 10), Vector2(12, 16)), INK, false, 1.2)
			if kind == "discard": draw_line(c + Vector2(2, 2), c + Vector2(9, 9), INK, 2, true)
			if kind == "search": draw_arc(c + Vector2(5, 5), 4, 0, TAU, 16, INK, 1.5, true)
		"shield", "reduceNextHit", "hitProtection", "grace":
			draw_polyline(PackedVector2Array([c + Vector2(-8, -8), c + Vector2(8, -8), c + Vector2(7, 5), c + Vector2(0, 10), c + Vector2(-7, 5), c + Vector2(-8, -8)]), INK, 1.5, true)
		"threat":
			draw_arc(c, 8, PI, TAU, 24, INK, 1.4, true)
			draw_line(c + Vector2(-10, 0), c + Vector2(10, 0), INK, 1.4, true)
			for x in [-6, 0, 6]: draw_line(c + Vector2(x, 4), c + Vector2(x - 3, 10), INK, 1.4, true)
		"bounce":
			draw_arc(c, 8, 0.5, TAU - 0.5, 24, INK, 1.5, true)
			draw_line(c + Vector2(8, -4), c + Vector2(3, -6), INK, 1.5, true)
		_:
			draw_polyline(PackedVector2Array([c + Vector2(-9, 7), c + Vector2(0, -9), c + Vector2(9, 7), c + Vector2(-9, 7)]), INK, 1.3, true)
			draw_line(c + Vector2(-8, 7), c + Vector2(8, -3), INK, 1.0, true)
