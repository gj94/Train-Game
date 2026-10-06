shader_type spatial;
uniform sampler2D surface_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D surface_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D surface_rough : hint_roughness_r, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 tint : source_color = vec3(.65,.66,.63);
uniform float metres = 12.0;
uniform bool road_surface = true;
varying vec3 world_pos;
void vertex() { world_pos=(MODEL_MATRIX*vec4(VERTEX,1)).xyz; }
void fragment() {
 vec2 p=world_pos.xz;
 vec3 base=texture(surface_albedo,p/metres).rgb;
 float variation=.92+.08*sin(p.x*.081+p.y*.062)*sin(p.y*.19);
 float edge=min(UV.x,1.0-UV.x);
 float dust=road_surface ? (1.0-smoothstep(.02,.15,edge))*.23 : .0;
 ALBEDO=mix(base*tint*variation,vec3(.22,.17,.105),dust);
 NORMAL_MAP=texture(surface_normal,p/metres).rgb;
 NORMAL_MAP_DEPTH=.45;
 ROUGHNESS=max(.74,texture(surface_rough,p/metres).r);
 SPECULAR=.16;
}