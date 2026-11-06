class_name BrassTrim
extends RefCounted
## Shared, replaceable vector skin. No textures or game-state dependencies.
const GOLD := Color(0.79, 0.58, 0.29)
const HIGHLIGHT := Color(0.98, 0.8, 0.48)
const DARK := Color(0.055, 0.075, 0.065, 0.93)

static func polygon(rect: Rect2, cut: float = 6) -> PackedVector2Array:
	var a: Vector2 = rect.position
	var b: Vector2 = rect.end
	return PackedVector2Array([a + Vector2(cut, 0), Vector2(b.x - cut, a.y), Vector2(b.x, a.y + cut), b - Vector2(0, cut), b - Vector2(cut, 0), Vector2(a.x + cut, b.y), Vector2(a.x, b.y - cut), a + Vector2(0, cut), a + Vector2(cut, 0)])

static func plate(canvas: CanvasItem, rect: Rect2) -> void:
	canvas.draw_colored_polygon(polygon(Rect2(rect.position + Vector2(1, 3), rect.size)), Color(0.03, 0.045, 0.035, 0.4))
	canvas.draw_colored_polygon(polygon(rect), DARK)
	canvas.draw_polyline(polygon(rect), GOLD, 2, true)
	canvas.draw_polyline(polygon(rect.grow(-3), 4), Color(HIGHLIGHT, 0.45), 0.8, true)
	# Sparse scored lines suggest a dark drafting surface without bitmap artwork.
	for index in range(9):
		var at: Vector2 = rect.position + Vector2(16 + fposmod(index * 97.0, maxf(1, rect.size.x - 32)), 12 + fposmod(index * 23.0, maxf(1, rect.size.y - 24)))
		canvas.draw_line(at, at + Vector2(10, -3), Color(0.65, 0.67, 0.52, 0.035), 1, true)
