shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D grass_albedo : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D grass_normal : hint_normal,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D soil_albedo : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D soil_normal : hint_normal,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D macro_noise : filter_linear,repeat_enable;
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
}
