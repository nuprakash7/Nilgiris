class_name BlockoutGeometry
extends RefCounted
## Small shared builders for replaceable blockout meshes. No gameplay behavior.


static func material(color: Color, unshaded: bool = false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 1.0
	if unshaded:
		result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		result.disable_fog = true
	return result


static func box(parent: Node3D, size: Vector3, position: Vector3, surface: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = surface
	if surface is BaseMaterial3D and surface.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.position = position
	parent.add_child(instance)
	return instance


static func label(parent: Node3D, text: String, position: Vector3, size: int, width: float, color: Color) -> Label3D:
	var result := Label3D.new()
	result.text = text
	result.position = position
	result.font_size = size
	result.pixel_size = 0.01
	result.width = width
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.modulate = color
	result.outline_size = 0
	result.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(result)
	return result
