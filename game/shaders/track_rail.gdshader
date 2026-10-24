shader_type spatial;
global uniform float extreme_detail;
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
	if(extreme_detail>0.0) {
		float strength = clamp(extreme_detail,0.0,1.0);
		// Only the authored white running-surface mask is polished. Webs,
		// feet, joint caps and pointwork retain their authored distinctions.
		float stable_mottle = texture(rough_tex,UV*vec2(4.0,.5)).r;
		float oxide = clamp((stable_mottle-.38)*4.0,0.0,1.0);
		vec3 oxide_color = mix(vec3(.105,.068,.045),vec3(.24,.15,.085),oxide);
		// Roughly 2.4 mm longitudinal grinding marks. Fade their contrast
		// before the wavelength becomes less than two pixels.
		float phase = UV.x*2600.0;
		float resolved = 1.0-smoothstep(.6,3.0,fwidth(phase));
		float has_uv = step(.000001,length(dFdx(UV))+length(dFdy(UV)));
		resolved *= has_uv;
		float brushed = .5+.5*sin(phase)*resolved;
		float crown = (1.0-smoothstep(.018,.036,abs(UV.x)))*has_uv;
		vec3 steel = vec3(.48,.5,.51)*mix(.94,1.0,brushed);
		vec3 finish = mix(oxide_color,steel,wear*(.82+.18*crown));
		ALBEDO = mix(ALBEDO,finish,strength);
		ROUGHNESS = mix(ROUGHNESS,mix(.89,.25+.08*stable_mottle+.085*(1.0-crown),wear),strength);
		METALLIC = mix(METALLIC,mix(.12,.92,wear),strength);
		// No new normal-map shader feature on rail: even a neutral normal map
		// could change the legacy rendering permutation at zero detail.
	}
}
