class_name BackdropLayer
extends Resource
## Camera-space placement in metres; depth is positive away from the camera.
@export var position := Vector3(0, -1.8, 48)
@export var size := Vector3(48, 16, 6)
@export var colour := Color(0.24, 0.40, 0.28)
@export_range(0, 2) var contrast: float = 1.0
@export_range(0, 1) var haze: float = 0.08
