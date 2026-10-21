shader_type spatial;
instance uniform float extreme_detail : instance_index(15) = 0.0;
#include "extreme_surface_detail.gdshaderinc"
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_tex : hint_roughness_r, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 world_pos;
varying vec3 extreme_cast_position;
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
	if(extreme_detail>0.0) { extreme_cast_position = VERTEX; }
}
void fragment() {
	vec2 p = world_pos.xz/.7;
	float grain = texture(albedo_tex,p).r;
	float patches = .5+.5*sin(world_pos.x*4.2+sin(world_pos.z*3.7));
	float seat = exp(-pow((abs(UV.x)-.874)/.19,2.0));
	float film = texture(rough_tex,world_pos.xz/2.2).r;
	ALBEDO = vec3(.235,.225,.201)*mix(.70,1.25,grain)*COLOR.rgb*(1.0-seat*.34)*( .78+.28*patches)*mix(.74,1.0,film);
	NORMAL_MAP = texture(normal_tex,p).rgb;
	NORMAL_MAP_DEPTH = .8;
	ROUGHNESS = max(.87,texture(rough_tex,p).r);
	SPECULAR = .22;
	if(extreme_detail>0.0) {
		float strength = clamp(extreme_detail,0.0,1.0);
		// The cast follows each sleeper, including moving/rebased MultiMeshes.
		// Its local x/z projection matches the authored near-mesh UV tangents.
		vec2 cast_p = extreme_cast_position.xz/.7+vec2(COLOR.r*13.1,COLOR.r*7.7);
		float cast_grain = texture(albedo_tex,cast_p).r;
		float cast_rough = texture(rough_tex,cast_p).r;
		float resolved = extreme_detail_filter(extreme_cast_position.xz*45.0);
		// A compacted dirt band belongs at the ballast contact, not over the
		// whole crown. Existing rail-seat grime and per-sleeper tint remain.
		float contact = 1.0-smoothstep(.16,.265,extreme_cast_position.y);
		float pores = (1.0-smoothstep(.07,.15,cast_grain))*resolved;
		vec3 cast_color = vec3(.235,.225,.201)*mix(.66,1.36,cast_grain)*COLOR.rgb;
		cast_color *= (1.0-seat*.34)*mix(.86,1.0,cast_rough);
		cast_color *= mix(vec3(1.0),vec3(.65,.60,.49),contact*.40);
		ALBEDO = mix(ALBEDO,cast_color,strength);
		NORMAL_MAP = mix(NORMAL_MAP,texture(normal_tex,cast_p).rgb,strength);
		NORMAL_MAP = mix(NORMAL_MAP,vec3(.5,.5,1.0),strength*(1.0-resolved)*.75);
		NORMAL_MAP_DEPTH = mix(NORMAL_MAP_DEPTH,.7,strength);
		ROUGHNESS = mix(ROUGHNESS,clamp(.65+cast_rough*.30+contact*.06+pores*.04,.84,.98),strength);
	}
}
