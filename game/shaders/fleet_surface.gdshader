shader_type spatial;
uniform vec4 paint_color : source_color = vec4(.5);
uniform float base_roughness = .45;
uniform float base_metallic = .0;
uniform int finish = 0; // enamel, roof, running gear, exposed metal
uniform float wear_amount = .8;
uniform bool gear_part = false;
uniform bool wheel_part = false;
uniform mat4 vehicle_from_mesh;
varying vec3 rest_pos;
varying vec3 vehicle_pos;
varying vec3 vehicle_normal;
float hash3(vec3 p) { p=fract(p*.1031); p+=dot(p,p.yzx+33.33); return fract((p.x+p.y)*p.z); }
float noise3(vec3 p) {
	vec3 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(mix(hash3(i),hash3(i+vec3(1,0,0)),f.x),mix(hash3(i+vec3(0,1,0)),hash3(i+vec3(1,1,0)),f.x),f.y),
		mix(mix(hash3(i+vec3(0,0,1)),hash3(i+vec3(1,0,1)),f.x),mix(hash3(i+vec3(0,1,1)),hash3(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void vertex() {
	rest_pos=VERTEX;
	vehicle_pos=(vehicle_from_mesh*vec4(VERTEX,1.0)).xyz;
	vehicle_normal=normalize((vehicle_from_mesh*vec4(NORMAL,0.0)).xyz);
}
void fragment() {
	vec3 p=rest_pos;
	float patches=noise3(p*2.2)*.62+noise3(p*8.3)*.25+noise3(p*26.0)*.13;
	float streaks=noise3(vec3(p.x*12.0,p.y*.6,p.z*12.0));
	float fine=noise3(p*180.0);
	float lower=1.0-smoothstep(.45,2.5,vehicle_pos.y);
	float up=max(vehicle_normal.y,0.0);
	float dirt=wear_amount*(lower*.45+smoothstep(.52,.86,streaks)*.25)*mix(.5,1.4,patches);
	vec3 color=paint_color.rgb;
	float rough=base_roughness;
	float metal=base_metallic;
	if(finish==0) {
		// Modest rain streaks, road film on the lower bodyside and enamel sheen.
		color*=mix(.76,1.0,patches);
		color=mix(color,vec3(.095,.075,.053),clamp(dirt,0.0,.42));
		rough+=dirt*.4+(patches-.5)*.11;
		CLEARCOAT=.22*(1.0-dirt);
		CLEARCOAT_ROUGHNESS=.36;
	} else if(finish==1) {
		float roof_dirt=wear_amount*(.23+up*.19+patches*.25);
		color=mix(color,vec3(.055,.050,.043),roof_dirt);
		rough=max(.65,rough+roof_dirt*.2);
		metal*=.65;
		AO=mix(.58,.85,patches);
		AO_LIGHT_AFFECT=.2;
	} else if(finish==2) {
		// Cast steel stays dark, with irregular brake dust on exposed surfaces.
		color*=.62;
		color=mix(color,vec3(.115,.075,.042),wear_amount*patches*.29);
		rough=max(.65,rough)+fine*.12;
		metal*=.65;
		AO=mix(.58,.85,patches);
		AO_LIGHT_AFFECT=.2;
	} else {
		color*=.78+patches*.18;
		rough=clamp(rough+(patches-.5)*.12,.32,.58);
		metal=max(metal,.7);
		if(gear_part) {
			// A wheel's side is oxidised; only its rolling circumference is burnished.
			float tread=wheel_part ? 1.0-smoothstep(.35,.70,abs(vehicle_normal.x)) : 0.0;
			color*=mix(.18,.68,tread);
			rough=mix(.78,rough,tread);
			metal=mix(.4,.9,tread);
			AO=.65+.3*tread;
			AO_LIGHT_AFFECT=.2;
		}
	}
	ALBEDO=color;
	ROUGHNESS=clamp(rough,.2,.96);
	METALLIC=metal;
	// Filter microscopic finish at distance to avoid sparkling paint.
	float micro=(fine-.5)*.0015*(1.0-smoothstep(.005,.025,length(fwidth(p))));
	NORMAL=normalize(NORMAL-vec3(dFdx(micro),dFdy(micro),0.0));
}
