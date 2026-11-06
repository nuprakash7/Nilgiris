class_name MarketArt
extends Control
## Small replaceable construction thumbnail; no per-offer 3D viewport.
var card_id: String = ""
var texture: Texture2D
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var image: Texture2D = texture if texture != null else CardVisuals.illustration(card_id)
	var dimensions := image.get_size()
	var factor: float = minf(size.x / dimensions.x, size.y / dimensions.y)
	var fitted: Vector2 = dimensions * factor
	draw_texture_rect(image, Rect2((size - fitted) * 0.5, fitted), false)
