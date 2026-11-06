shader_type spatial;
render_mode cull_disabled, fog_disabled;
uniform sampler2D artwork : source_color, hint_default_white, filter_linear_mipmap, repeat_disable;
uniform sampler2D normal_texture : hint_normal;
uniform bool use_normal_map = false;
uniform float normal_strength = 1.0;
uniform float roughness_value = 1.0;
uniform float metallic_value = 0.0;
uniform vec4 base_colour : source_color = vec4(1.0);
uniform vec4 layer_colour : source_color = vec4(1.0);
uniform vec4 mist_colour : source_color = vec4(0.66, 0.77, 0.79, 1.0);
uniform float contrast = 1.0;
uniform float haze = 0.0;
uniform float mist_intensity = 0.15;
varying float local_height;
void vertex() { local_height = VERTEX.y; }
void fragment() {
	vec4 tex = texture(artwork, UV) * base_colour;
	if (tex.a < 0.5) { discard; }
	vec3 pigment = clamp((tex.rgb - vec3(0.5)) * contrast + vec3(0.5), vec3(0.0), vec3(1.0));
	float low_mist = (1.0 - smoothstep(-12.0, 1.0, local_height)) * mist_intensity;
	float atmosphere = clamp(haze + low_mist * (1.0 - haze), 0.0, 1.0);
	ALBEDO = pigment * layer_colour.rgb * (1.0 - atmosphere);
	EMISSION = mist_colour.rgb * atmosphere;
	ROUGHNESS = roughness_value;
	METALLIC = metallic_value;
	if (use_normal_map) { NORMAL_MAP = texture(normal_texture, UV).rgb; NORMAL_MAP_DEPTH = normal_strength; }
}
