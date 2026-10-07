shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// Material category lives in vertex alpha; every building stays one draw surface.
uniform sampler2D wall_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D wall_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D wall_rough : hint_roughness_r, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roof_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roof_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roof_rough : hint_roughness_r, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D aged_wall : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D aged_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 local_pos;
varying vec3 local_normal;
varying vec3 world_pos;
varying vec4 variation;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
vec3 mapped_normal(vec3 n,vec3 p,vec2 uv,vec3 bump) {
 vec3 p2=cross(dFdy(p),n),p1=cross(n,dFdx(p));
 vec2 a=dFdx(uv),b=dFdy(uv);
 vec3 t=p2*a.x+p1*b.x,bt=p2*a.y+p1*b.y;
 float scale=inversesqrt(max(max(dot(t,t),dot(bt,bt)),.00000001));
 return normalize(mat3(t*scale,bt*scale,n)*bump);
}
void vertex() {
 local_pos=VERTEX; local_normal=NORMAL;
 world_pos=(MODEL_MATRIX*vec4(VERTEX,1)).xyz;
 variation=INSTANCE_CUSTOM;
}
void fragment() {
 int category=int(floor(COLOR.a*15.0+.5));
 vec3 n=abs(normalize(local_normal));
 vec2 uv=local_pos.xy;
 if(n.y>n.x && n.y>n.z) uv=local_pos.xz;
 else if(n.x>n.z) uv=local_pos.zy;
 vec3 paint=COLOR.rgb;
 float rough=.85,metal=0.0,weather=.16;
 vec3 normal=vec3(.5,.5,1);
 float normal_depth=.35;
 if(category==1) {
  float style=floor(variation.x*6.0);
  vec3 tint=vec3(1);
  if(style<1.0) tint=vec3(.74,.87,.96);
  else if(style<2.0) tint=vec3(.94,.74,.74);
  else if(style<3.0) tint=vec3(.77,.93,.72);
  else if(style<4.0) tint=vec3(.92,.86,.69);
  else if(style<5.0) tint=vec3(.82,.79,.93);
  vec3 texture_colour=texture(wall_albedo,uv/2.0).rgb;
  float exposed=smoothstep(.42,.66,noise(uv*.45+variation.x*19.0));
  exposed*=smoothstep(.42,.78,variation.x)*(1.0-smoothstep(2.0,5.0,local_pos.y));
  texture_colour=mix(texture_colour,texture(aged_wall,uv/3.4).rgb,exposed*.83);
  paint*=texture_colour*tint*.85;
  normal=mix(texture(wall_normal,uv/2.0).rgb,texture(aged_normal,uv/3.4).rgb,exposed);
  normal_depth=.8;
  rough=texture(wall_rough,uv/2.0).r*.9;
  weather=.65;
 } else if(category==2) {
  paint*=texture(roof_albedo,uv/1.15).rgb;
  normal=texture(roof_normal,uv/1.15).rgb;
  rough=texture(roof_rough,uv/1.15).r;
  weather=.20;
 } else if(category==3) {
  metal=.36; rough=.55; weather=.35;
  paint*=mix(.68,1.02,noise(uv*vec2(3.1,.2)));
 } else if(category==4) {
  metal=.16; rough=.20; weather=.04;
  float room=hash(floor(vec2(uv.x/1.6,local_pos.y/3.15)));
  paint*=mix(.15,.57,room);
  // Dark backing and uneven blinds give windows depth, without transparent sorting.
  float blind=step(.58,room)*smoothstep(.38,.5,fract(local_pos.y/3.15));
  paint=mix(paint,vec3(.21,.18,.12)*(.75+.25*sin(uv.x*68.0)),blind*.66);
 } else if(category==8) {
  rough=.66; weather=.10;
 } else if(category==9) {
  paint*=mix(.72,1.12,noise(uv*vec2(24,.6)));
  rough=.89; weather=.23;
 }
 float age=noise(world_pos.xz*.09+vec2(world_pos.y*.04))*.6+noise(world_pos.xz*.7+vec2(world_pos.y*.32))*.4;
 float rising=1.0-smoothstep(.10,1.15,local_pos.y);
 float streak=noise(vec2(world_pos.x+world_pos.z,world_pos.y*.07)*4.0);
 float dirt=weather*(rising*.65+(1.0-age)*.32+smoothstep(.50,.86,streak)*.32);
 if(category==1) dirt+=(1.0-smoothstep(.01,.55,mod(3.28-local_pos.y,3.15)))*noise(world_pos.xz*2.1)*.20;
 ALBEDO=paint*(.93+variation.x*.14)*mix(vec3(1),vec3(.53,.49,.39),clamp(dirt,0.0,.55));
 vec3 bump=normal*2.0-1.0; bump.xy*=normal_depth;
 NORMAL=mapped_normal(NORMAL,VERTEX,uv,normalize(bump));
 ROUGHNESS=clamp(rough+dirt*.10,.18,1.0);
 METALLIC=metal;
 SPECULAR=.35;
 CLEARCOAT=category==3 ? .18 : (category==4 ? .55 : .0);
 CLEARCOAT_ROUGHNESS=.35;
}