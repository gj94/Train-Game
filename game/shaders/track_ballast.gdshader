shader_type spatial;
global uniform float extreme_detail;
#include "extreme_surface_detail.gdshaderinc"
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_tex : hint_roughness_r, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 world_pos;
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
	vec2 p = UV / 6.0; // captured aggregate resolves to roughly 30–60 mm stones
	vec3 gravel = texture(albedo_tex,p).rgb;
	float macro = sin(world_pos.x*.075+sin(world_pos.z*.33))*sin(world_pos.z*.11+world_pos.x*.024);
	if(extreme_detail>0.0) {
		// Track UVs are lateral/longitudinal metres, retained across chunks and
		// floating-origin shifts. Do not move the photographed aggregate scale.
		macro = sin(UV.x*.075+sin(UV.y*.33))*sin(UV.y*.11+UV.x*.024);
	}
	float grey = dot(gravel,vec3(.3,.59,.11));
	gravel = mix(vec3(grey),gravel,.32)*vec3(.43,.425,.41);
	float rust = exp(-pow((abs(UV.x)-.874)/.24,2.0));
	float oil = exp(-pow(UV.x/.46,2.0))*(.6+.4*sin(UV.y*.15));
	ALBEDO = mix(gravel,gravel*vec3(.76,.58,.44),rust*.26)*(1.0-oil*.16)*(1.0+macro*.13);
	NORMAL_MAP = texture(normal_tex,p).rgb;
	NORMAL_MAP_DEPTH = 1.2;
	ROUGHNESS = max(.88,texture(rough_tex,p).r);
	SPECULAR = .18;
	if(extreme_detail>0.0) {
		float strength = clamp(extreme_detail,0.0,1.0);
		float resolved = extreme_detail_filter(UV*20.0);
		// The dark interstices come from the same photograph as the stone
		// faces, not an unrelated noise layer or fabricated sleeper shadows.
		float interstice = (1.0-smoothstep(.14,.34,grey))*resolved;
		ALBEDO *= 1.0-interstice*.09*strength;
		// The old max(.88, rough) flattened this asset's entire roughness map.
		// Recover a restrained dry-granite range without making gravel wet.
		float stone_roughness = clamp(.72+texture(rough_tex,p).r*.32,.82,.94);
		ROUGHNESS = mix(ROUGHNESS,mix(stone_roughness,.96,interstice),strength);
		// Resolve individual 30–60 mm facets nearby, then flatten their normal
		// energy before they become subpixel. Texture mipmaps remain enabled.
		NORMAL_MAP = mix(NORMAL_MAP,vec3(.5,.5,1.0),strength*(1.0-resolved)*.85);
	}
}
