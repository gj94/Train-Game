shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D concrete_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D concrete_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 local_position;
varying vec3 local_normal;
varying float above_foot;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
void vertex() {
 local_position=VERTEX;local_normal=NORMAL;
 above_foot=VERTEX.y-COLOR.a;
}
void fragment() {
 vec3 n=abs(normalize(local_normal));
 vec2 uv=n.y>n.x && n.y>n.z ? local_position.xz : (n.x>n.z ? local_position.zy : local_position.xy);
 float streak=noise(vec2((local_position.x+local_position.z)*8.0,above_foot*.37));
 float low=1.0-smoothstep(.05,1.15,above_foot);
 float age=noise(local_position.xz*.5)*.30+smoothstep(.44,.84,streak)*.40;
 vec3 concrete=texture(concrete_albedo,uv*.85).rgb;
 vec3 paint=COLOR.rgb*mix(vec3(.78),vec3(1.08),concrete);
 ALBEDO=paint*mix(vec3(1),vec3(.29,.34,.21),clamp(low*.58+age,0.0,.8));
 NORMAL_MAP=texture(concrete_normal,uv*.85).rgb;
 NORMAL_MAP_DEPTH=.30;
 ROUGHNESS=.94;
 SPECULAR=.18;
}
