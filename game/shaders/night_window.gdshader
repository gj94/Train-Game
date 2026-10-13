shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;
uniform vec4 glass_colour : source_color = vec4(.12,.18,.20,.6);
uniform sampler2D glass_texture : source_color, filter_linear_mipmap_anisotropic;
uniform bool has_glass_texture = false;
uniform float glass_roughness = .22;
uniform float glass_metallic = .15;
uniform float glass_specular = .45;
uniform vec3 uv_scale = vec3(1.0);
uniform vec3 uv_offset = vec3(0.0);
uniform sampler2D glass_normal : hint_normal, filter_linear_mipmap_anisotropic;
uniform bool has_normal = false;
uniform float normal_depth = 1.0;
uniform sampler2D glass_roughness_texture : hint_default_white, filter_linear_mipmap_anisotropic;
uniform sampler2D glass_metallic_texture : hint_default_white, filter_linear_mipmap_anisotropic;
uniform bool has_roughness_texture = false;
uniform bool has_metallic_texture = false;
uniform vec4 roughness_channel = vec4(1,0,0,0);
uniform vec4 metallic_channel = vec4(1,0,0,0);
uniform float window_night = 0.0;
uniform float window_occupancy = .7;
uniform bool shuttered = false;
varying flat float home_seed;
varying vec3 pane_position;
varying vec3 pane_normal;
void vertex() { home_seed=INSTANCE_CUSTOM.x; pane_position=VERTEX; pane_normal=NORMAL; }
void fragment() {
 vec4 glass=glass_colour;
 vec2 uv=UV*uv_scale.xy+uv_offset.xy;
 if(has_glass_texture) glass*=texture(glass_texture,uv);
 float inhabited=smoothstep(home_seed-.055,home_seed+.055,window_occupancy);
 float lit=window_night*inhabited;
 vec3 warmth=mix(vec3(1.0,.64,.30),vec3(.68,.83,1.0),step(.83,fract(home_seed*5.71)));
 ALBEDO=glass.rgb;
 ROUGHNESS=glass_roughness; METALLIC=glass_metallic; SPECULAR=glass_specular;
 if(has_normal) { NORMAL_MAP=texture(glass_normal,uv).rgb; NORMAL_MAP_DEPTH=normal_depth; }
 if(has_roughness_texture) ROUGHNESS*=dot(texture(glass_roughness_texture,uv),roughness_channel);
 if(has_metallic_texture) METALLIC*=dot(texture(glass_metallic_texture,uv),metallic_channel);
 ALPHA=mix(glass.a,.98,lit);
 float slits=1.0;
 if(shuttered) {
  float seam=abs(fract(pane_position.y*11.5)-.5);
  slits=(1.0-smoothstep(.025,.07,seam))*(1.0-smoothstep(.2,.5,abs(pane_normal.y)));
 }
 EMISSION=warmth*lit*slits*2.8;
}
