shader_type spatial;
// Shallow flooded rice plots; original procedural ripples, no external asset.
varying vec3 world_pos;
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float a = sin(world_pos.x * 1.8 + world_pos.z * 2.2 + TIME * 0.75);
	float b = cos(world_pos.x * 3.1 - world_pos.z * 1.5 + TIME * 0.5);
	ALBEDO = vec3(0.075, 0.125, 0.10);
	NORMAL_MAP = vec3(0.5 + a * 0.07, 0.5 + b * 0.05, 1.0);
	NORMAL_MAP_DEPTH = 0.4;
	ROUGHNESS = 0.14;
	SPECULAR = 0.9;
	METALLIC = 0.2;
}
