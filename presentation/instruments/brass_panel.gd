class_name BrassPanel
extends PanelContainer
## A local instrument housing, independently replaceable by artists.
func _ready() -> void:
	var empty := StyleBoxEmpty.new()
	empty.content_margin_left = 12
	empty.content_margin_right = 12
	empty.content_margin_top = 6
	empty.content_margin_bottom = 6
	add_theme_stylebox_override("panel", empty)
	resized.connect(queue_redraw)
func _draw() -> void:
	BrassTrim.plate(self, Rect2(Vector2(2, 2), size - Vector2(4, 5)))
