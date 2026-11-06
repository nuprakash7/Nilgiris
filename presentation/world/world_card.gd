class_name WorldCard
extends Area3D
## A real mesh, world-space text, and a ray-pickable surface; no rule evaluation.

enum Role { REWARD, HAND }
const SIZE := Vector3(3.15, 4.7, 0.12)
const INK := Color(0.16, 0.14, 0.11)

var action_id: String = ""
var role: Role = Role.HAND
var enabled: bool = false
var definition: Dictionary = {}
var detail: String = ""
var _selected: bool = false
var _hovered: bool = false
var _visual: Node3D
var _frame: MeshInstance3D
var _illustration: MeshInstance3D
var artwork: Dictionary[String, Texture2D] = {}
var _paper: MeshInstance3D
var _title: Label3D
var _power: Label3D
var _gold: Label3D
var _effect: Label3D
var _detail: Label3D
var _lift: Tween
var _front_lift: float = 4.0
var _materials: Dictionary


func build(materials: Dictionary) -> void:
	_materials = materials
	collision_layer = 1
	collision_mask = 0
	var shape := BoxShape3D.new()
	shape.size = SIZE + Vector3(0.12, 0.08, 0.12)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)
	_visual = Node3D.new()
	_visual.name = "Face"
	add_child(_visual)
	_frame = BlockoutGeometry.box(_visual, SIZE + Vector3(0.10, 0.10, 0), Vector3.ZERO, materials.frame)
	_frame.name = "Frame"
	_paper = _texture_plane(CardVisuals.FACE, Vector2(SIZE.x, SIZE.y), Vector3(0, 0, 0.14))
	_paper.name = "Paper"
	_illustration = _texture_plane(CardVisuals.SPIKE, Vector2(2.65, 1.8), Vector3(0, 0.55, 0.17))
	_illustration.name = "Illustration"
	_illustration.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	_title = BlockoutGeometry.label(_visual, "", Vector3(0, 1.68, 0.19), 27, 270, INK)
	_power = BlockoutGeometry.label(_visual, "", Vector3(-0.925, -1.86, 0.20), 39, 78, Color(1, 0.97, 0.86))
	_gold = BlockoutGeometry.label(_visual, "", Vector3(0.925, -1.86, 0.20), 39, 78, Color(1, 0.97, 0.86))
	_effect = BlockoutGeometry.label(_visual, "", Vector3(0, -0.49, 0.20), 18, 270, INK)
	_detail = BlockoutGeometry.label(_visual, "CONSTRUCT", Vector3(0, -1.05, 0.20), 16, 270, INK)

func _texture_plane(texture: Texture2D, dimensions: Vector2, at: Vector3) -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.disable_fog = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.albedo_texture = texture
	var mesh := QuadMesh.new()
	mesh.size = dimensions
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_visual.add_child(instance)
	return instance


func replace_card_art(scene: PackedScene) -> void:
	# Dynamic text and selection frame remain independent of the art backing.
	_paper.visible = false
	_visual.add_child(scene.instantiate())


func present(card: Dictionary, subtitle: String, id: String, card_role: Role, available: bool) -> void:
	definition = card
	detail = subtitle
	action_id = id
	role = card_role
	enabled = available
	_title.text = String(card.name).to_upper()
	set_power(int(card.baseIntegrity))
	_effect.text = CardText.compact(card)
	_detail.text = "CONSTRUCT" if _effect.text.is_empty() else ""
	_effect.font_size = 16 if _effect.text.length() > 150 else 18
	_illustration.scale = Vector3.ONE * (0.75 if _effect.text.length() > 90 else 1.0)
	_illustration.position.y = 0.78 if _effect.text.length() > 90 else 0.55
	_illustration.material_override.albedo_texture = artwork.get(String(card.id), CardVisuals.illustration(String(card.id)))
	_update_frame()


func set_placement_gold(amount: int, paid: bool) -> void:
	_gold.text = "%d" % (0 if paid else amount)
	_gold.modulate = Color(0.8, 0.77, 0.65) if paid else Color(1, 0.97, 0.86)


func set_power(value: int) -> void:
	_power.text = "%d" % value
	_power.font_size = 38 if absi(value) < 100 else 30


func move_drag_visual(camera: Camera3D, screen_position: Vector2) -> void:
	if _lift != null:
		_lift.kill()
	var depth: float = maxf(2.0, -camera.to_local(_visual.global_position).z)
	_visual.global_position = camera.project_position(screen_position, depth)
	_visual.global_basis = camera.global_basis.scaled(_visual.global_basis.get_scale())


func reset_drag_visual() -> void:
	_visual.position = Vector3.ZERO
	_visual.rotation = Vector3.ZERO
	_visual.scale = Vector3.ONE
	_update_lift()


func set_selected(value: bool) -> void:
	if _selected == value:
		return
	_selected = value
	_update_frame()
	_update_lift()


func set_hovered(value: bool) -> void:
	if _hovered == value:
		return
	_hovered = value
	_update_frame()
	_update_lift()


func _update_frame() -> void:
	_frame.material_override = _materials.gold if _selected or (_hovered and enabled) else _materials.frame


func set_fan_pose(at: Vector3, angle: float, front_lift: float) -> void:
	position = at
	rotation = Vector3(0, 0, angle)
	_front_lift = front_lift
	if _selected or _hovered: _update_lift()


func screen_polygon(camera: Camera3D, raised: bool = false) -> PackedVector2Array:
	var frame: Transform3D = _visual.global_transform if raised else global_transform
	var points := PackedVector2Array()
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		points.append(camera.unproject_position(frame * Vector3(corner.x * SIZE.x * 0.5, corner.y * SIZE.y * 0.5, 0.14)))
	return points


func _update_lift() -> void:
	if _lift != null: _lift.kill()
	var raised: bool = _selected or (_hovered and enabled)
	_lift = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_lift.tween_property(_visual, "position", Vector3(0, 1.25, _front_lift) if raised else Vector3.ZERO, 0.14)
	_lift.tween_property(_visual, "rotation:z", -rotation.z if raised else 0.0, 0.14)
	_lift.tween_property(_visual, "scale", Vector3.ONE * (1.08 if raised else 1.0), 0.14)
