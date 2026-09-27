shader_type spatial;
// Strip of laterite soil / spilled ballast beside the track. UV.x runs across
// the strip (0..1), UV.y along it in metres. Edges are broken up with noise.

render_mode cull_disabled;

uniform sampler2D soil_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D soil_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D gravel_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D noise_tex : filter_linear, repeat_enable;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float across = abs(UV.x - 0.5) * 2.0;           // 0 at track centre, 1 at strip edge
	float n = texture(noise_tex, wpos.xz / 9.0).r;
	if (across > 0.62 + n * 0.45) {
		discard;
	}
	vec2 p = wpos.xz / 3.0;
	float gravel_w = smoothstep(0.55, 0.35, across + n * 0.2);
	ALBEDO = mix(texture(soil_albedo, p).rgb * vec3(1.0, 0.92, 0.86), texture(gravel_albedo, p).rgb * 0.95, gravel_w);
	NORMAL_MAP = texture(soil_normal, p).rgb;
	ROUGHNESS = 0.95;
}
