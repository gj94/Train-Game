shader_type spatial;
instance uniform float extreme_detail : instance_index(15) = 0.0;
#include "extreme_surface_detail.gdshaderinc"
// Strip of laterite soil / spilled ballast beside the track. UV.x runs across
// the strip (0..1), UV.y along it in metres. Edges are broken up with noise.

render_mode cull_disabled;

uniform sampler2D soil_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D soil_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D gravel_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D noise_tex : filter_linear, repeat_enable;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float across = abs(UV.x - 0.5) * 2.0;           // 0 at track centre, 1 at strip edge
	float n = texture(noise_tex, wpos.xz / 9.0).r;
	if (across > 0.62 + n * 0.45) {
		discard;
	}
	vec2 p = wpos.xz / 3.0;
	float gravel_w = smoothstep(0.55, 0.35, across + n * 0.2);
	ALBEDO = mix(texture(soil_albedo, p).rgb * vec3(1.0, 0.92, 0.86), texture(gravel_albedo, p).rgb * 0.95, gravel_w);
	NORMAL_MAP = texture(soil_normal, p).rgb;
	ROUGHNESS = 0.95;
	if(extreme_detail>0.0) {
		float strength = clamp(extreme_detail,0.0,1.0);
		// The centre face covers 6.7 m and each outer slope .6 m on ordinary
		// track. Keep the longitudinal metre UV continuous across 64 m chunks.
		// Wider turnout shoulders stretch only this lateral material mapping.
		float lateral = (UV.x-.5)*20.1;
		if(UV.x<1.0/3.0) lateral = -3.95+UV.x*1.8;
		else if(UV.x>2.0/3.0) lateral = 3.35+(UV.x-2.0/3.0)*1.8;
		vec2 metres = vec2(lateral,UV.y);
		vec2 soil_p = metres/3.0;
		vec2 spill_p = metres/6.0;
		float stable_noise = texture(noise_tex,metres/9.0).r;
		float spill = 1.0-smoothstep(.35,.55,across+stable_noise*.2);
		vec3 soil = texture(soil_albedo,soil_p).rgb*vec3(1.0,.92,.86);
		vec3 gravel = texture(gravel_albedo,spill_p).rgb;
		float grey = dot(gravel,vec3(.3,.59,.11));
		// Spilled aggregate is the same mineral and scale as the adjacent
		// ballast, not the old twice-as-bright white apron. No edge/discard,
		// terrain coverage or geometry is changed by this material branch.
		gravel = mix(vec3(grey),gravel,.32)*vec3(.43,.425,.41);
		ALBEDO = mix(ALBEDO,mix(soil,gravel,spill),strength);
		float resolved = extreme_detail_filter(metres*24.0);
		vec3 soil_bump = texture(soil_normal,soil_p).rgb;
		// No gravel normal is bound to this shader. Do not stamp laterite
		// stone relief onto exposed granite or invent a replacement map.
		soil_bump = mix(soil_bump,vec3(.5,.5,1.0),spill*.82+(1.0-spill)*(1.0-resolved)*.8);
		NORMAL_MAP = mix(NORMAL_MAP,soil_bump,strength);
		ROUGHNESS = mix(ROUGHNESS,mix(.96,.89,spill),strength);
	}
}
