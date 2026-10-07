shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec3 route_origin=vec3(0.0);
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
}