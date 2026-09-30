shader_type spatial;
// Metre-based mineral grain and subdued age variation; no photo textures.
uniform vec4 base_color : source_color = vec4(0.6, 0.6, 0.6, 1.0);
uniform float surface_roughness = 0.8;
uniform float surface_metallic = 0.0;
uniform float weathering = 0.14;
varying vec3 world_position;

float hash(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}
float noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), f.x),
	               mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
	           mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
	               mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z);
}
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float broad = noise3(world_position * 0.55);
	float grain = noise3(world_position * 13.0);
	float damp = (1.0 - smoothstep(0.1, 2.0, world_position.y)) * 0.18;
	ALBEDO = base_color.rgb * (1.0 - weathering * (0.65 * broad + 0.35 * grain) - damp);
	ROUGHNESS = clamp(surface_roughness + (grain - 0.5) * 0.08, 0.1, 1.0);
	METALLIC = surface_metallic;
}
