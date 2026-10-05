shader_type spatial;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_tex : hint_roughness_r, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 world_pos;
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
	vec2 p = UV / 6.0; // captured aggregate resolves to roughly 30–60 mm stones
	vec3 gravel = texture(albedo_tex,p).rgb;
	float macro = sin(world_pos.x*.075+sin(world_pos.z*.33))*sin(world_pos.z*.11+world_pos.x*.024);
	float grey = dot(gravel,vec3(.3,.59,.11));
	gravel = mix(vec3(grey),gravel,.32)*vec3(.67,.665,.65);
	float rust = exp(-pow((abs(UV.x)-.874)/.24,2.0));
	float oil = exp(-pow(UV.x/.46,2.0))*(.6+.4*sin(UV.y*.15));
	ALBEDO = mix(gravel,gravel*vec3(.76,.58,.44),rust*.26)*(1.0-oil*.16)*(1.0+macro*.13);
	NORMAL_MAP = texture(normal_tex,p).rgb;
	NORMAL_MAP_DEPTH = 1.2;
	ROUGHNESS = max(.88,texture(rough_tex,p).r);
	SPECULAR = .18;
}
