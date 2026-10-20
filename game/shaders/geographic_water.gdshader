shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
instance uniform float extreme_detail : instance_index(15) = 0.0;
uniform vec3 route_origin=vec3(0.0);
#include "extreme_surface_detail.gdshaderinc"
varying vec3 position_m;
void vertex(){position_m=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz+route_origin;}
float wave(vec2 p, vec2 direction,float frequency,float speed){
	float phase=dot(p,direction)*frequency+TIME*speed;
	float footprint=max(length(dFdx(p)),length(dFdy(p)))*frequency;
	return sin(phase)*(1.0-smoothstep(.4,2.5,footprint));
}
void fragment(){
	vec2 p=position_m.xz;
	float large=wave(p,normalize(vec2(1.0,.37)),.43,.48);
	float crosswave=wave(p,normalize(vec2(-.24,1.0)),.71,.67);
	float ripple=wave(p,normalize(vec2(.75,-.43)),2.1,.83);
	float patch=.5+.5*sin(p.x*.018+sin(p.y*.027));
	ALBEDO=mix(vec3(.028,.063,.049),vec3(.050,.077,.058),patch);
	NORMAL_MAP=normalize(vec3(large*.075+ripple*.024,crosswave*.065+ripple*.018,1.0))*.5+.5;
	NORMAL_MAP_DEPTH=.65;
	ROUGHNESS=.26+patch*.05;
	METALLIC=0.0;
	SPECULAR=.5;
	if(extreme_detail>0.0) {
		float strength=clamp(extreme_detail,0.0,1.0);
		// Recombine the existing waves, preserving their phase, speed and clock.
		// Product harmonics need their own stricter pixel-footprint filter.
		float resolved=extreme_detail_filter(p*4.2);
		vec2 capillary=vec2(ripple*crosswave,ripple*large)*.023*resolved;
		vec2 slope=vec2(large*.11+ripple*.035,crosswave*.095+ripple*.027)+capillary;
		vec3 detailed=normalize(vec3(slope,1.0))*.5+.5;
		NORMAL_MAP=mix(NORMAL_MAP,detailed,strength);
		NORMAL_MAP_DEPTH=mix(NORMAL_MAP_DEPTH,.80,strength);
		// Spatially varied, dielectric highlights, with unresolved normal
		// variance returned as roughness instead of sparkling at the horizon.
		float variance=(1.0-resolved)*.055;
		float water_rough=.19+patch*.055+(1.0-ripple*ripple)*.018+variance;
		ROUGHNESS=mix(ROUGHNESS,water_rough,strength);
	}
}
