shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
instance uniform float extreme_detail : instance_index(15) = 0.0;
uniform vec3 extreme_route_origin = vec3(0.0);
// Photographic finishes in real metres, shared across the existing station surfaces.
uniform vec4 base_color : source_color = vec4(.6,.6,.6,1);
uniform sampler2D surface_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D surface_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D surface_rough : hint_roughness_r, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float surface_roughness = .8;
uniform float surface_metallic = .0;
uniform int surface_kind = 0;
uniform float metres = 2.0;
#include "extreme_surface_detail.gdshaderinc"
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
 vec3 surface_position=world_position;
 // Whole finish shares one stable projection, so paver bevels stay aligned
 // with the existing joints. At zero this is the exact legacy position.
 if(extreme_detail>0.0) surface_position+=extreme_route_origin;
 vec3 n=abs(normalize(world_normal));
 vec2 p=surface_position.xy;
 if(n.y>n.x && n.y>n.z) p=surface_position.xz;
 else if(n.x>n.z) p=surface_position.zy;
 // Keep a high-precision rebased projection for added close detail. Do not
 // reconstruct this by subtracting the origin from already-quantized p.
 vec2 local_p=world_position.xy;
 vec2 origin_p=extreme_route_origin.xy;
 if(n.y>n.x && n.y>n.z) { local_p=world_position.xz; origin_p=extreme_route_origin.xz; }
 else if(n.x>n.z) { local_p=world_position.zy; origin_p=extreme_route_origin.zy; }
 vec2 paver_cells=p/.30;
 if(extreme_detail>0.0) paver_cells=extreme_paver_position(local_p,origin_p);
 vec2 uv=p/metres;
 vec3 tex=texture(surface_albedo,uv).rgb;
 float grain=dot(tex,vec3(.299,.587,.114));
 vec3 paint=base_color.rgb;
 float rough=surface_roughness;
 float metal=surface_metallic;
 float age=noise(p*.19)*.65+noise(p*1.7)*.35;
 float damp=(1.0-smoothstep(.08,1.4,surface_position.y))*.28;
 float streak=noise(vec2(p.x*3.4,p.y*.14));
 float wear=0.0;
 float depth=.55;
 if(surface_kind==2) {
  // Sheet overlaps and rain tracks follow the corrugated roof's fall.
  vec2 sheet=vec2(surface_position.x/.96,surface_position.z/3.2);
  float panel=hash(floor(sheet));
  float seam=1.0-smoothstep(.006,.024,min(fract(sheet.x),1.0-fract(sheet.x)));
  if(extreme_detail>0.0) {
   float aa=max(fwidth(sheet.x),.0001);
   float filtered=1.0-smoothstep(.006-aa,.024+aa,min(fract(sheet.x),1.0-fract(sheet.x)));
   seam=mix(seam,filtered*extreme_detail_filter(sheet),clamp(extreme_detail,0.0,1.0));
  }
  float runoff=noise(vec2(surface_position.x*11.0,surface_position.z*.48));
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
  float paver_variation=hash(cell);
  if(extreme_detail>0.0) {
   vec2 detail_edge=min(fract(paver_cells),1.0-fract(paver_cells))*.30;
   float aa=max(max(fwidth(local_p).x,fwidth(local_p).y),.0001);
   float filtered=1.0-smoothstep(.002-aa,.006+aa,min(detail_edge.x,detail_edge.y));
   joint=mix(joint,filtered*extreme_detail_filter(local_p/.30),clamp(extreme_detail,0.0,1.0));
   // The same periodic hash used by detail noise keeps neighbouring tiles
   // continuous when the bounded origin phase crosses its 4096-cell period.
   paver_variation=mix(paver_variation,extreme_hash(floor(paver_cells)),clamp(extreme_detail,0.0,1.0));
  }
  paint*=mix(.62,1.08,grain)*mix(.82,1.05,paver_variation);
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
 vec3 geometric_normal=NORMAL;
 NORMAL=mapped_normal(NORMAL,VERTEX,uv,normalize(bump));
 ROUGHNESS=clamp(rough*.70+texture(surface_rough,uv).r*.30+wear*.12,.15,1.0);
 METALLIC=metal;
 SPECULAR=.32;
 if(extreme_detail>0.0 && surface_kind!=5) {
  float strength=clamp(extreme_detail,0.0,1.0);
  vec3 aggregate=extreme_noise_gradient(extreme_periodic_position(local_p,origin_p,vec2(9.0)));
  vec3 pores=extreme_noise_gradient(extreme_periodic_position(local_p,origin_p,vec2(32.0))+vec2(5.2,8.9));
  float pigment=(aggregate.x-.5)*.075+(pores.x-.5)*.035;
  vec2 slope=aggregate.yz*.060+pores.yz*.028;
  float rough_delta=(aggregate.x-.5)*.09+(pores.x-.5)*.045;
  if(surface_kind==1) {
   // A shallow bevel gives the existing 30 cm paver joints a light-facing
   // edge, not just a painted dark grid. It is filtered before becoming thin.
   vec2 cell=fract(paver_cells);
   vec2 edge=min(cell,1.0-cell)*.30;
   vec2 outward=sign(vec2(.5)-cell);
   vec2 bevel_axis=edge.x<edge.y ? vec2(outward.x,0) : vec2(0,outward.y);
   float bevel=(1.0-smoothstep(.004,.018,min(edge.x,edge.y)))
    *extreme_detail_filter(local_p*55.0);
   slope+=bevel_axis*bevel*.20;
   rough_delta+=bevel*.055;
  } else if(surface_kind==2) {
   // Fine rolled-sheet texture only; the authored roof owns corrugation.
   vec3 rolled=extreme_noise_gradient(extreme_periodic_position(local_p,origin_p,vec2(20.0,2.5)));
   slope=rolled.yz*vec2(.034,.010);
   pigment=(aggregate.x-.5)*.035;
   rough_delta=(rolled.x-.5)*.075;
  } else if(surface_kind==6) {
   // Painted metal is smoother than masonry and never inherits concrete pits.
   slope*=.20; pigment*=.30; rough_delta*=.45;
  } else if(surface_kind==4) {
   slope*=1.25;
  }
  ALBEDO*=1.0+pigment*strength;
  bump.xy-=slope*strength;
  NORMAL=mapped_normal(geometric_normal,VERTEX,local_p/metres,normalize(bump));
  ROUGHNESS=clamp(ROUGHNESS+rough_delta*strength,.18,1.0);
 }
}
