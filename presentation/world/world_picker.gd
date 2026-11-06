class_name WorldPicker
extends Node
## One event-driven physics ray for all world cards and bridge slots.

signal target_changed(target: Area3D)
signal target_pressed(target: Area3D)
signal drag_started(card: WorldCard)
signal drag_moved(screen_position: Vector2)
signal drag_finished(slot: BridgeSlot)

const DRAG_THRESHOLD := 8.0
var _pressed_card: WorldCard
var _press_position: Vector2
var dragging: bool = false

var hand_cards: Array[WorldCard] = []
var camera: Camera3D
var target: Area3D


func _ready() -> void:
	get_window().focus_exited.connect(_cancel_drag)


func _cancel_drag() -> void:
	if _pressed_card != null:
		_finish_drag(null)


func _input(event: InputEvent) -> void:
	# Capture release even over HUD controls, so a drag cannot become stuck.
	if _pressed_card == null:
		return
	if event.is_action_pressed("ui_cancel"):
		_finish_drag(null)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		if not dragging and event.position.distance_to(_press_position) >= DRAG_THRESHOLD:
			dragging = true
			_pressed_card.collision_layer = 0
			drag_started.emit(_pressed_card)
		if dragging:
			_set_target(pick(event.position))
			drag_moved.emit(event.position)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var card := _pressed_card
		if dragging:
			var slot := pick(event.position) as BridgeSlot
			if get_viewport().gui_get_hovered_control() != null:
				slot = null
			_finish_drag(slot)
		else:
			_pressed_card = null
			target_pressed.emit(card)
		get_viewport().set_input_as_handled()


func _finish_drag(slot: BridgeSlot) -> void:
	if _pressed_card != null:
		_pressed_card.collision_layer = 1
	_pressed_card = null
	dragging = false
	drag_finished.emit(slot)


func _unhandled_input(event: InputEvent) -> void:
	if camera == null:
		return
	if event is InputEventMouseMotion:
		_set_target(pick(event.position))
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_set_target(pick(event.position))
			if target is WorldCard and target.enabled:
				_pressed_card = target
				_press_position = event.position
			elif target != null:
				target_pressed.emit(target)
			get_viewport().set_input_as_handled()


func pick(screen_position: Vector2) -> Area3D:
	# Stable resting fan polygons give every exposed card strip a deterministic
	# target, independent of hover animation and physics overlap ordering.
	if not dragging:
		for index in range(hand_cards.size() - 1, -1, -1):
			var card: WorldCard = hand_cards[index]
			if card.visible and card.enabled and Geometry2D.is_point_in_polygon(screen_position, card.screen_polygon(camera)):
				return card
		if target is WorldCard and target.visible and target.enabled and Geometry2D.is_point_in_polygon(screen_position, target.screen_polygon(camera, true)):
			return target
	var origin: Vector3 = camera.project_ray_origin(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + camera.project_ray_normal(screen_position) * 150.0, 1)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var result: Dictionary = camera.get_world_3d().direct_space_state.intersect_ray(query)
	return result.get("collider") as Area3D


func clear_target() -> void:
	_set_target(null)


func _set_target(value: Area3D) -> void:
	if target == value:
		return
	if target is WorldCard:
		target.set_hovered(false)
	target = value
	if target is WorldCard:
		target.set_hovered(true)
	target_changed.emit(target)
