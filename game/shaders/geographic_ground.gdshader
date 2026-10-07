shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D grass_albedo : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D grass_normal : hint_normal,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D soil_albedo : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
varying vec3 position;
void vertex(){ position=VERTEX; }
void fragment(){
	vec2 uv=UV;
	vec3 grass=texture(grass_albedo,uv).rgb;
	vec3 soil=texture(soil_albedo,uv*.7).rgb;
	float variation=.90+.10*sin(uv.x*.073+sin(uv.y*.13))*sin(uv.y*.039);
	ALBEDO=mix(grass,soil,COLOR.a)*COLOR.rgb*variation;
	NORMAL_MAP=texture(grass_normal,uv).rgb;
	NORMAL_MAP_DEPTH=.45;
	ROUGHNESS=.94;
	SPECULAR=.15;
}