shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never;
uniform vec4 light_color : source_color = vec4(1.0,0.04,0.01,1.0);
uniform bool lit = false;
varying float expansion;
void vertex() {
	// A bounded optical footprint preserves a small bright source through pixel
	// sampling/TAA. It is depth-tested, directional and never drawn through scenery.
	float distance_m = length((MODELVIEW_MATRIX * vec4(0.0,0.0,0.0,1.0)).xyz);
	float pixel_width = 2.0 * distance_m / (abs(PROJECTION_MATRIX[1][1]) * VIEWPORT_SIZE.y);
	expansion = lit ? clamp(pixel_width * 4.5 / 0.18,1.0,38.0) : 1.0;
	VERTEX.xy *= expansion;
}
void fragment() {
	float radius = length(UV-vec2(0.5))*2.0;
	float core = 1.0-smoothstep(0.54,0.79,radius);
	float halo = (1.0-smoothstep(0.28,1.0,radius))*0.14;
	float facing = smoothstep(0.40,0.80,dot(normalize(NORMAL),normalize(VIEW)));
	if (radius>1.0 || facing<0.01) discard;
	// Ribbed lens is visible close up; the unlit aperture remains dark.
	float ribs = 0.94+0.06*sin(UV.y*130.0);
	ALBEDO = lit ? light_color.rgb*ribs : vec3(0.018,0.024,0.026)*ribs;
	EMISSION = lit ? light_color.rgb*2.8*core : vec3(0.0);
	ALPHA = (lit ? max(core,halo) : core)*facing;
}
