shader_type spatial;
// Shallow flooded rice plots; original procedural ripples, no external asset.
varying vec3 world_pos;
uniform float ripple_strength = 1.0;
uniform float water_roughness = 0.14;
uniform float rice_rows = 0.0;
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float a = sin(world_pos.x * 1.8 + world_pos.z * 2.2 + TIME * 0.75);
	float b = cos(world_pos.x * 3.1 - world_pos.z * 1.5 + TIME * 0.5);
	ALBEDO = vec3(0.075, 0.125, 0.10);
	NORMAL_MAP = vec3(0.5 + a * 0.07 * ripple_strength, 0.5 + b * 0.05 * ripple_strength, 1.0);
	NORMAL_MAP_DEPTH = 0.4;
	vec2 cell = floor(world_pos.xz * 2.0);
	float seed = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
	vec2 shoot = fract(world_pos.xz * 2.0) - vec2(0.5 + (seed - 0.5) * 0.26, 0.5);
	float planted = (1.0 - smoothstep(0.13, 0.45, length(shoot))) * rice_rows;
	ALBEDO = mix(ALBEDO, vec3(0.11, 0.22, 0.025) * (0.8 + seed * 0.4), planted);
	ROUGHNESS = mix(water_roughness, 0.88, planted);
	SPECULAR = mix(0.9, 0.12, rice_rows);
	METALLIC = mix(0.2, 0.0, rice_rows);
}
