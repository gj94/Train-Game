shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
instance uniform float extreme_detail : instance_index(15) = 0.0;
uniform vec3 route_origin=vec3(0.0);
#include "extreme_surface_detail.gdshaderinc"
varying vec3 position_m;
varying vec3 extreme_local_position_m;
void vertex(){
	position_m=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz+route_origin;
	if(extreme_detail>0.0) {
		extreme_local_position_m=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	}
}
float wave(vec2 p, vec2 direction,float frequency,float speed){
	float phase=dot(p,direction)*frequency+TIME*speed;
	float footprint=max(length(dFdx(p)),length(dFdy(p)))*frequency;
	return sin(phase)*(1.0-smoothstep(.4,2.5,footprint));
}
// Analytic height derivatives, in world XZ. Binary-rational cycles/m keep the
// snapped route origin exact; never add the large origin to local coordinates.
// The third component carries unresolved slope variance, not height.
vec3 extreme_water_wave(vec2 local_p,vec2 cycles,float speed,float offset,float amplitude){
	float spatial_cycles=dot(local_p,cycles);
	float origin_cycles=fract(dot(route_origin.xz,cycles));
	float phase=6.28318530718*fract(fract(spatial_cycles)+origin_cycles+fract(TIME*speed)+offset);
	// Differentiate the unwrapped local phase. Fract derivatives would invent
	// large footprints at every wave boundary and make a visible moving grid.
	float footprint=abs(dFdx(spatial_cycles))+abs(dFdy(spatial_cycles));
	float resolved=1.0-smoothstep(.18,.45,footprint);
	vec2 slope=normalize(cycles)*cos(phase)*amplitude*resolved;
	float variance=.5*amplitude*amplitude*(1.0-resolved*resolved);
	return vec3(slope,variance);
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
		vec2 local_p=extreme_local_position_m.xz;
		// A gentle wind spectrum, from 7 m swell to 18 cm ripples. The amplitudes
		// are slopes, so smaller waves do not get unrealistically steep.
		// Speeds are integral cycles over the default 3600 s TIME rollover.
		vec3 spectrum=extreme_water_wave(local_p,vec2(.125,.0625),.5,.17,.045);
		spectrum+=extreme_water_wave(local_p,vec2(.375,.25),.875,.61,.060);
		spectrum+=extreme_water_wave(local_p,vec2(.875,.375),1.25,.43,.065);
		spectrum+=extreme_water_wave(local_p,vec2(2.0,1.25),1.875,.83,.042);
		spectrum+=extreme_water_wave(local_p,vec2(4.75,2.75),2.875,.29,.028);
		spectrum+=extreme_water_wave(local_p,vec2(-.375,.75),1.125,.73,.018);
		vec3 detailed_normal=normalize((VIEW_MATRIX*vec4(-spectrum.x,1.0,-spectrum.y,0.0)).xyz);
		// Reconstruct the original map only for fractional detail blending.
		// Use an explicit world frame: stream UV tangents can differ from ponds.
		vec3 legacy_bump=vec3(NORMAL_MAP.xy*2.0-1.0,0.0);
		legacy_bump.z=sqrt(max(0.0,1.0-dot(legacy_bump.xy,legacy_bump.xy)));
		vec3 legacy_normal=normalize(mix(NORMAL,TANGENT*legacy_bump.x+BINORMAL*legacy_bump.y+NORMAL*legacy_bump.z,NORMAL_MAP_DEPTH));
		NORMAL=normalize(mix(legacy_normal,detailed_normal,strength));
		NORMAL_MAP=vec3(.5,.5,1.0);
		NORMAL_MAP_DEPTH=0.0;
		// Fold unresolved slope energy into the GGX roughness rather than
		// letting subpixel ripples sparkle. Water stays opaque and dielectric.
		float base_roughness=.17+patch*.025;
		float water_rough=pow(pow(base_roughness,4.0)+spectrum.z,.25);
		ROUGHNESS=mix(ROUGHNESS,water_rough,strength);
	}
}
