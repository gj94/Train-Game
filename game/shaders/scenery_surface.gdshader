shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D surface_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D surface_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D surface_roughness : hint_roughness_r, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool textured = false;
uniform float metres = 2.0;
uniform float roughness_value = 0.85;
uniform float metallic_value = 0.0;
uniform float weathering = 0.24;
uniform float normal_strength = 0.35;
uniform float paint_variation = 0.0;
uniform vec3 material_tint : source_color = vec3(1.0);
varying vec3 local_pos;
varying vec3 local_normal;
varying vec3 world_pos;
varying vec4 variation;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
void vertex() {
 local_pos=VERTEX; local_normal=NORMAL;
 world_pos=(MODEL_MATRIX*vec4(VERTEX,1)).xyz;
 variation=INSTANCE_CUSTOM;
}
void fragment() {
 vec3 n=abs(normalize(local_normal));
 vec2 uv=local_pos.xy;
 if(n.y>n.x && n.y>n.z) uv=local_pos.xz;
 else if(n.x>n.z) uv=local_pos.zy;
 uv/=metres;
 vec3 paint=COLOR.rgb*material_tint;
 vec3 tint=vec3(1);
 float style=floor(variation.x*6.0);
 if(style<1.0) tint=vec3(.76,.88,.94);
 else if(style<2.0) tint=vec3(.91,.78,.77);
 else if(style<3.0) tint=vec3(.80,.92,.76);
 else if(style<4.0) tint=vec3(.91,.87,.72);
 else if(style<5.0) tint=vec3(.84,.82,.91);
 paint*=mix(vec3(1),tint,paint_variation);
 float age=noise(world_pos.xz*.09+vec2(world_pos.y*.04))*0.6+noise(world_pos.xz*.7+vec2(world_pos.y*.32))*.4;
 float rising=1.0-smoothstep(.10,1.15,local_pos.y);
 float streak=noise(vec2(world_pos.x+world_pos.z,world_pos.y*.07)*4.0);
 float dirt=weathering*(rising*.65+(1.0-age)*.32+smoothstep(.50,.86,streak)*.32);
 float ledge_runoff=(1.0-smoothstep(.01,.55,mod(3.28-local_pos.y,3.15)))*noise(world_pos.xz*2.1);
 dirt+=paint_variation*ledge_runoff*.20;
 vec3 base=vec3(1.0);
 float rough=roughness_value;
 if(textured) {
  base=texture(surface_albedo,uv).rgb;
  rough=texture(surface_roughness,uv).r*roughness_value;
  NORMAL_MAP=texture(surface_normal,uv).rgb;
  NORMAL_MAP_DEPTH=normal_strength;
 }
 // The custom seed alters brightness subtly without multiplying draw materials.
 float tone=1.0+(variation.x-.5)*.14;
 ALBEDO=paint*base*tone*mix(vec3(1),vec3(.53,.49,.39),clamp(dirt,0.0,.55));
 ROUGHNESS=clamp(rough+dirt*.10,.22,1.0);
 METALLIC=metallic_value;
 SPECULAR=.35;
}