shader_type spatial;
instance uniform float extreme_detail : instance_index(15) = 0.0;
uniform vec3 extreme_route_origin = vec3(0.0);
uniform sampler2D surface_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D surface_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D surface_rough : hint_roughness_r, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 tint : source_color = vec3(.65,.66,.63);
uniform float metres = 12.0;
uniform bool road_surface = true;
uniform bool paving = false;
uniform bool loose_surface = false;
uniform vec3 route_origin = vec3(0.0);
#include "extreme_surface_detail.gdshaderinc"
varying vec3 world_pos;
varying vec3 extreme_local_position_m;
void vertex() {
 extreme_local_position_m=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 world_pos=(MODEL_MATRIX*vec4(VERTEX,1)).xyz+route_origin; }
void fragment() {
 vec2 p=road_surface ? UV : world_pos.xz;
 vec3 base=texture(surface_albedo,p/metres).rgb;
 float variation=.92+.08*sin(p.x*.081+p.y*.062)*sin(p.y*.19);
 float edge=min(UV2.x,1.0-UV2.x);
 float dust=road_surface ? (1.0-smoothstep(.02,.15,edge))*.23 : .0;
 ALBEDO=mix(base*tint*variation,vec3(.22,.17,.105),dust);
 if(paving) {
  // Brick bond with derivative filtering; bounded phase preserves the pattern
  // across tile rebases even at the far end of this 300 km route.
  vec2 cells=extreme_periodic_position(extreme_local_position_m.xz,extreme_route_origin.xz,vec2(2.5,5.0));
  cells.x+=mod(floor(cells.y),2.0)*.5;
  vec2 edge_m=min(fract(cells),1.0-fract(cells))/vec2(2.5,5.0);
  float aa=max(max(fwidth(extreme_local_position_m.x),fwidth(extreme_local_position_m.z)),.0001);
  float joint=(1.0-smoothstep(.002-aa,.006+aa,min(edge_m.x,edge_m.y)))*extreme_detail_filter(cells);
  ALBEDO*=mix(1.0,mix(.87,1.08,extreme_hash(floor(cells))),extreme_detail_filter(cells));
  ALBEDO*=1.0-joint*.60;
 }
 if(loose_surface) {
  // Worn central tread and softer dusty margins, without adding vertices.
  ALBEDO*=mix(.81,1.04,smoothstep(.0,.25,edge));
 }
 NORMAL_MAP=texture(surface_normal,p/metres).rgb;
 NORMAL_MAP_DEPTH=.45;
 ROUGHNESS=max(.74,texture(surface_rough,p/metres).r);
 SPECULAR=.16;
 if(extreme_detail>0.0) {
  float strength=clamp(extreme_detail,0.0,1.0);
  // R39 road UVs are absolute metre coordinates; UV2 owns the dust mask.
  // Preserve that base finish while using local coordinates for fine detail.
  // Fine cells use rebased positions plus a bounded phase, not absolute p:
  // at the route's far end a 300 km float cannot represent a 3 cm aggregate.
  vec3 aggregate=extreme_noise_gradient(extreme_periodic_position(
   extreme_local_position_m.xz,extreme_route_origin.xz,vec2(12.0)));
  vec3 fines=extreme_noise_gradient(extreme_periodic_position(
   extreme_local_position_m.xz,extreme_route_origin.xz,vec2(31.0))+vec2(7.7,3.1));
  float grain=(aggregate.x-.5)*.12+(fines.x-.5)*.055;
  ALBEDO*=1.0+grain*strength*(1.0-dust);
  vec3 bump=texture(surface_normal,p/metres).rgb*2.0-1.0;
  bump.xy*=mix(.45,.62,strength);
  bump.xy-=(aggregate.yz*.085+fines.yz*.035)*strength;
  // The imported normal is world-projected too, rather than rotating with
  // each road segment's tangent frame. No geometry or road markings change.
  vec3 detailed_normal=extreme_mapped_normal(NORMAL,VERTEX,extreme_local_position_m.xz/metres,normalize(bump));
  NORMAL=mix(NORMAL,detailed_normal,strength);
  NORMAL_MAP=mix(NORMAL_MAP,vec3(.5,.5,1.0),strength);
  float dry_rough=clamp(ROUGHNESS+(aggregate.x-.5)*.12
   +(fines.x-.5)*.055+dust*.12,.76,.98);
  ROUGHNESS=mix(ROUGHNESS,dry_rough,strength);
 }
}
