shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// Photographic finishes in real metres, shared across the existing station surfaces.
uniform vec4 base_color : source_color = vec4(.6,.6,.6,1);
uniform sampler2D surface_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D surface_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D surface_rough : hint_roughness_r, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float surface_roughness = .8;
uniform float surface_metallic = .0;
uniform int surface_kind = 0;
uniform float metres = 2.0;
varying vec3 world_position;
varying vec3 world_normal;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
vec3 mapped_normal(vec3 n,vec3 p,vec2 uv,vec3 bump) {
 vec3 dp1=dFdx(p),dp2=dFdy(p);
 vec2 duv1=dFdx(uv),duv2=dFdy(uv);
 vec3 p2=cross(dp2,n),p1=cross(n,dp1);
 vec3 t=p2*duv1.x+p1*duv2.x,b=p2*duv1.y+p1*duv2.y;
 float scale=inversesqrt(max(max(dot(t,t),dot(b,b)),.00000001));
 return normalize(mat3(t*scale,b*scale,n)*bump);
}
void vertex() {
 world_position=(MODEL_MATRIX*vec4(VERTEX,1)).xyz;
 world_normal=MODEL_NORMAL_MATRIX*NORMAL;
}
void fragment() {
 vec3 n=abs(normalize(world_normal));
 vec2 p=world_position.xy;
 if(n.y>n.x && n.y>n.z) p=world_position.xz;
 else if(n.x>n.z) p=world_position.zy;
 vec2 uv=p/metres;
 vec3 tex=texture(surface_albedo,uv).rgb;
 float grain=dot(tex,vec3(.299,.587,.114));
 vec3 paint=base_color.rgb;
 float rough=surface_roughness;
 float metal=surface_metallic;
 float age=noise(p*.19)*.65+noise(p*1.7)*.35;
 float damp=(1.0-smoothstep(.08,1.4,world_position.y))*.28;
 float streak=noise(vec2(p.x*3.4,p.y*.14));
 float wear=0.0;
 float depth=.55;
 if(surface_kind==2) {
  // Sheet overlaps and rain tracks follow the corrugated roof's fall.
  vec2 sheet=vec2(world_position.x/.96,world_position.z/3.2);
  float panel=hash(floor(sheet));
  float seam=1.0-smoothstep(.006,.024,min(fract(sheet.x),1.0-fract(sheet.x)));
  float runoff=noise(vec2(world_position.x*11.0,world_position.z*.48));
  float rust=smoothstep(.62,.82,noise(p*2.0)+seam*.23)*(.15+panel*.38);
  paint*=mix(.61,1.02,panel)*mix(.73,1.04,runoff);
  paint=mix(paint,vec3(.115,.051,.022),rust);
  paint*=1.0-seam*.27;
  rough=clamp(.53+rust*.40+(1.0-runoff)*.15,.4,.96);
  metal=mix(.32,.03,rust); depth=.18;
 } else if(surface_kind==1) {
  vec2 cell=floor(p/.30);
  vec2 edge=min(fract(p/.30),1.0-fract(p/.30))*.30;
  float joint=1.0-smoothstep(.002,.006,min(edge.x,edge.y));
  paint*=mix(.62,1.08,grain)*mix(.82,1.05,hash(cell));
  paint=mix(paint,vec3(.064,.057,.043),joint*.64);
  wear=(1.0-age)*.19; depth=.75;
 } else if(surface_kind==4) {
  paint=tex*.55; depth=.65; rough=.94;
 } else if(surface_kind==5) {
  paint*=.70; rough=.18; metal=.30; depth=.0;
 } else {
  paint*=mix(.65,1.12,grain);
  wear=damp+(1.0-age)*.14+smoothstep(.53,.82,streak)*.13;
  if(surface_kind==6) { wear*=.42; depth=.12; }
 }
 ALBEDO=paint*mix(vec3(1),vec3(.37,.34,.26),clamp(wear,0.0,.6));
 vec3 bump=texture(surface_normal,uv).rgb*2.0-1.0;
 bump.xy*=depth;
 NORMAL=mapped_normal(NORMAL,VERTEX,uv,normalize(bump));
 ROUGHNESS=clamp(rough*.70+texture(surface_rough,uv).r*.30+wear*.12,.15,1.0);
 METALLIC=metal;
 SPECULAR=.32;
}