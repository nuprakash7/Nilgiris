class_name DiamondCheckpoint
extends Button
## Vector diamond and normal button focus/tooltip behavior.
var damage_text: String = ""
var effect_text: String = ""
var empty_checkpoint: bool = true
var current: bool = false
var resolved: bool = false
func _ready() -> void:
	for state: String in ["normal", "hover", "focus", "pressed", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
func _draw() -> void:
	var center := size * 0.5 - Vector2(0, 5 if not effect_text.is_empty() else 0)
	var radius: float = 6 if empty_checkpoint else minf(size.x * 0.42, 23)
	var gold: Color = BrassTrim.HIGHLIGHT if current or has_focus() or is_hovered() else BrassTrim.GOLD
	if resolved: gold = Color(0.6, 0.64, 0.48)
	var points := PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius, 0), center + Vector2(0, radius), center + Vector2(-radius, 0), center + Vector2(0, -radius)])
	draw_colored_polygon(points, Color(0.09, 0.12, 0.1, 0.5))
	draw_polyline(points, gold, 1.5 if current else 1, true)
	var font: Font = get_theme_font("font")
	var ink: Color = get_theme_color("font_color")
	if not damage_text.is_empty():
		var font_size: int = 19 if damage_text.length() <= 2 else 14
		var baseline: float = center.y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
		draw_string(font, Vector2(0, baseline), damage_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, ink)
	if not effect_text.is_empty():
		draw_string(font, Vector2(0, size.y - 2), effect_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, ink)
	if current: draw_circle(Vector2(center.x, 2), 2, gold)
	if resolved: draw_line(Vector2(center.x - 3, 2), Vector2(center.x + 3, 2), gold, 1.4, true)
