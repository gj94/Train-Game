shader_type spatial;
// Terrain: tropical grass blended with red laterite soil, world-space UVs,
// two texture scales + distance-based scale to hide tiling, macro colour noise.

uniform sampler2D grass_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_rough : hint_roughness_r, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D soil_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D soil_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D noise_tex : filter_linear, repeat_enable;

uniform float tile = 3.5;                 // metres per texture repeat up close
uniform vec3 grass_tint : source_color = vec3(0.53, 0.70, 0.42);
uniform float soil_amount : hint_range(0.0, 1.0) = 0.12;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

vec3 sample3(sampler2D t, vec2 p, float far_mix) {
	vec3 near_c = mix(texture(t, p / tile).rgb, texture(t, p / (tile * 3.7) + vec2(0.37, 0.71)).rgb, 0.45);
	vec3 far_c = textureLod(t, p / (tile * 11.0) + vec2(0.13, 0.29), 3.0).rgb;
	return mix(near_c, far_c, far_mix);
}

void fragment() {
	vec2 p = wpos.xz;
	float dist = length(wpos - CAMERA_POSITION_WORLD);
	float far_mix = smoothstep(40.0, 350.0, dist);
	float n_macro = texture(noise_tex, p / 520.0).r;
	float n_mid = texture(noise_tex, p / 160.0 + vec2(0.5)).r;

	vec3 grass = sample3(grass_albedo, p, far_mix) * grass_tint * mix(0.72, 1.18, n_macro);
	vec3 soil = sample3(soil_albedo, p, far_mix);
	float soil_w = smoothstep(0.74 - soil_amount * 0.35, 0.84, n_mid * 0.7 + n_macro * 0.3);

	ALBEDO = mix(grass, soil, soil_w);
	vec3 nm_g = texture(grass_normal, p / tile).rgb;
	vec3 nm_s = texture(soil_normal, p / tile).rgb;
	NORMAL_MAP = mix(nm_g, nm_s, soil_w);
	NORMAL_MAP_DEPTH = mix(1.0, 0.3, far_mix);
	ROUGHNESS = mix(texture(grass_rough, p / tile).r, 0.92, soil_w);
	SPECULAR = 0.3;
}
