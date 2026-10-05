shader_type spatial;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_tex : hint_roughness_r, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 world_pos;
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
	vec2 p = world_pos.xz/.7;
	float grain = texture(albedo_tex,p).r;
	float patches = .5+.5*sin(world_pos.x*4.2+sin(world_pos.z*3.7));
	float seat = exp(-pow((abs(UV.x)-.874)/.19,2.0));
	ALBEDO = vec3(.29,.285,.267)*mix(.70,1.25,grain)*COLOR.rgb*(1.0-seat*.34)*( .87+.26*patches);
	NORMAL_MAP = texture(normal_tex,p).rgb;
	NORMAL_MAP_DEPTH = .5;
	ROUGHNESS = max(.87,texture(rough_tex,p).r);
	SPECULAR = .22;
}
