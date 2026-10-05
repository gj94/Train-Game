shader_type spatial;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_tex : hint_roughness_r, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 world_pos;
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
	float wear = COLOR.r;
	float mottling = texture(rough_tex,world_pos.xz*.65).r;
	vec3 rust = mix(vec3(.105,.068,.045),vec3(.24,.15,.085),mottling);
	float streak = .5+.5*sin(UV.x*2600.0);
	ALBEDO = mix(rust,vec3(.48,.5,.51)*mix(.94,1.0,streak),wear);
	ROUGHNESS = mix(.88,.29+.07*mottling,wear);
	METALLIC = mix(.15,.92,wear);
	SPECULAR = .5;
}
