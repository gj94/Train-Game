shader_type spatial;
render_mode diffuse_burley;
global uniform float extreme_detail;
uniform sampler2D grass_albedo : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D grass_normal : hint_normal,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D soil_albedo : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D soil_normal : hint_normal,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D macro_noise : filter_linear,repeat_enable;
#include "extreme_surface_detail.gdshaderinc"
void fragment(){
 vec2 uv=UV;
 // UV is absolute route metres / 3.5: no seams or swimming on origin rebases.
 float broad=texture(macro_noise,uv/82.0).r;
 float patches=texture(macro_noise,uv/13.0+vec2(.31,.72)).r;
 float detail=texture(macro_noise,uv/2.7).r;
 vec3 grass=mix(texture(grass_albedo,uv).rgb,texture(grass_albedo,uv*.237+vec2(.43,.18)).rgb,.32);
 vec3 soil=texture(soil_albedo,uv*.7).rgb;
 float bare=clamp(COLOR.a+smoothstep(.54,.76,patches*.78+detail*.22)*.52,0.0,1.0);
 vec3 vegetation=grass*COLOR.rgb*mix(.66,1.19,broad);
 vegetation*=mix(vec3(.69,.93,.69),vec3(1.10,.97,.69),smoothstep(.28,.76,patches));
 ALBEDO=mix(vegetation,soil*vec3(.39,.35,.27),bare);
 NORMAL_MAP=mix(texture(grass_normal,uv).rgb,texture(soil_normal,uv*.7).rgb,bare);
 NORMAL_MAP_DEPTH=.65;
 ROUGHNESS=mix(.94,.84,bare);
 SPECULAR=.15;
 if(extreme_detail>0.0) {
  float strength=clamp(extreme_detail,0.0,1.0);
  // Reuse the licensed mipmapped finishes at a second, close-range scale.
  // All coordinates still derive from absolute route UV, never world origin.
  float resolved=extreme_detail_filter(uv*3.5*8.0);
  vec2 grass_uv=uv*3.73+vec2(.37,.61);
  vec2 soil_uv=uv*2.91+vec2(.79,.23);
  vec3 close_albedo=mix(texture(grass_albedo,grass_uv).rgb,
   texture(soil_albedo,soil_uv).rgb,bare);
  float grain=dot(close_albedo,vec3(.299,.587,.114));
  float breakup=texture(macro_noise,uv*.83+vec2(.11,.59)).r;
  ALBEDO*=1.0+(grain-.5)*.15*strength*resolved;
  vec3 base_bump=NORMAL_MAP*2.0-1.0;
  vec3 fine_bump=mix(texture(grass_normal,grass_uv).rgb,
   texture(soil_normal,soil_uv).rgb,bare)*2.0-1.0;
  base_bump.xy+=fine_bump.xy*.24*strength*resolved;
  NORMAL_MAP=normalize(base_bump)*.5+.5;
  NORMAL_MAP_DEPTH+=.16*strength*resolved;
  // Dry laterite remains rough; this is aggregate/leaf variation, not wetness.
  float dry_rough=clamp(mix(.95,.87,bare)+(breakup-.5)*.08
   +(grain-.5)*.10*resolved,.79,.99);
  ROUGHNESS=mix(ROUGHNESS,dry_rough,strength);
 }
}
