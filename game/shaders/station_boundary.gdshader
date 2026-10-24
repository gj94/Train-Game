shader_type spatial;
render_mode diffuse_burley;
global uniform float extreme_detail;
#include "extreme_surface_detail.gdshaderinc"
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
 if(extreme_detail>0.0) {
  float strength=clamp(extreme_detail,0.0,1.0);
  // The batched fence's local metre coordinates survive floating-origin
  // rebases. Its mesh UV tangents do not match this dominant-axis projection,
  // so align the photographed concrete normal to the projection explicitly.
  vec2 photographed_xy=texture(concrete_normal,uv*.85).rg*2.0-1.0;
  float photographed_z=sqrt(max(1.0-dot(photographed_xy,photographed_xy),.0));
  vec3 pores=extreme_noise_gradient(uv*32.0);
  vec3 finish=normalize(vec3(photographed_xy*.38+pores.yz*.035,
   max(photographed_z,.25)));
  vec3 mapped=extreme_mapped_normal(normalize(NORMAL),VERTEX,uv*.85,finish);
  NORMAL=normalize(mix(NORMAL,mapped,strength));
  NORMAL_MAP=vec3(.5,.5,1.0);
  NORMAL_MAP_DEPTH=0.0;
  // Dry painted concrete, not glossy plastic: fine pigment variation and
  // slightly less chalk-flat highlights, without changing the painted scheme.
  ALBEDO*=mix(1.0,.96+pores.x*.08,strength);
  ROUGHNESS=mix(ROUGHNESS,clamp(.84+age*.10+low*.05,.84,.97),strength);
  SPECULAR=mix(SPECULAR,.32,strength);
 }
}
