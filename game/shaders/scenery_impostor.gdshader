shader_type spatial;
render_mode cull_disabled, diffuse_burley, alpha_to_coverage;
uniform sampler2D colour_atlas : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D normal_atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform float centre_y = 5.0;
uniform float palettes = 1.0;
uniform bool blend_views = false;
uniform float view_count = 8.0;
uniform float atlas_columns = 4.0;
uniform sampler2D window_mask : source_color, filter_linear_mipmap, repeat_disable;
uniform bool has_window_mask = false;
uniform float window_night = 0.0;
uniform float window_occupancy = .7;
varying flat float view_index;
varying flat float next_view;
varying flat float view_blend;
varying flat float palette_index;
varying flat float home_seed;
varying mat3 object_rotation;
varying vec3 object_scale;
void vertex() {
 vec3 origin=MODEL_MATRIX[3].xyz;
 vec3 to_camera=normalize(vec3(CAMERA_POSITION_WORLD.x-origin.x,0.0,CAMERA_POSITION_WORLD.z-origin.z));
 vec3 right=normalize(cross(vec3(0,1,0),to_camera));
 float scale_x=length(MODEL_MATRIX[0].xyz);
 float scale_y=length(MODEL_MATRIX[1].xyz);
 float scale_z=length(MODEL_MATRIX[2].xyz);
 float object_yaw=atan(MODEL_MATRIX[2].x,MODEL_MATRIX[2].z);
 float angle=atan(to_camera.x,to_camera.z)-object_yaw;
 float horizontal_scale=length(vec2(scale_x*cos(angle),scale_z*sin(angle)));
 angle=atan(scale_z*sin(angle),scale_x*cos(angle));
 float frame=mod(angle/(2.0*PI)*view_count+view_count,view_count);
 view_index=blend_views ? floor(frame) : mod(floor(frame+.5),view_count);
 next_view=mod(view_index+1.0,view_count);
 view_blend=blend_views ? smoothstep(0.0,1.0,fract(frame)) : 0.0;
 palette_index=min(palettes-1.0,floor(INSTANCE_CUSTOM.x*palettes));
 home_seed=INSTANCE_CUSTOM.x;
 object_scale=vec3(scale_x,scale_y,scale_z);
 object_rotation=mat3(normalize(MODEL_MATRIX[0].xyz),normalize(MODEL_MATRIX[1].xyz),normalize(MODEL_MATRIX[2].xyz));
 MODELVIEW_MATRIX=VIEW_MATRIX*mat4(vec4(right*horizontal_scale,0),vec4(0,scale_y,0,0),vec4(to_camera*horizontal_scale,0),vec4(origin,1));
 VERTEX.y+=centre_y;
}
vec2 atlas_uv(float index,vec2 coordinates,float palette,float count) {
 float rows=ceil(view_count/atlas_columns);
 vec2 tile=vec2(mod(index,atlas_columns),rows-1.0-floor(index/atlas_columns));
 tile.y+=palette*rows;
 return (clamp(coordinates,vec2(.0015),vec2(.9985))+tile)/vec2(atlas_columns,rows*count);
}
void fragment() {
 vec2 uv=atlas_uv(view_index,UV,palette_index,palettes);
 vec4 first=texture(colour_atlas,uv);
 vec2 uv_next=atlas_uv(next_view,UV,palette_index,palettes);
 vec4 second=vec4(0.0);
 vec4 colour=first;
 if(blend_views) {
  second=texture(colour_atlas,uv_next);
  // Premultiplied blending prevents dark borders around differently shaped
  // crowns. Alpha-to-coverage softens the silhouette through each turn.
  float alpha=mix(first.a,second.a,view_blend);
  colour=vec4(mix(first.rgb*first.a,second.rgb*second.a,view_blend)/max(alpha,.0001),alpha);
 }
 // Empty atlas background needs neither lighting nor normal/window samples.
 // Preserve partially covered pixels for alpha-to-coverage at leaf edges.
 if(colour.a<.0001) discard;
 vec3 normal_first=texture(normal_atlas,uv).rgb*2.0-1.0;
 vec3 local_normal=normal_first;
 if(blend_views) {
  vec3 normal_second=texture(normal_atlas,uv_next).rgb*2.0-1.0;
  local_normal=mix(normal_first*first.a,normal_second*second.a,view_blend);
 }
 ALBEDO=colour.rgb;
 if(has_window_mask && window_night>0.0) {
  vec2 window_uv=atlas_uv(view_index,UV,0.0,1.0);
  float mask=texture(window_mask,window_uv).r;
  if(blend_views) mask=mix(mask,texture(window_mask,atlas_uv(next_view,UV,0.0,1.0)).r,view_blend);
  float lit=window_night*smoothstep(home_seed-.055,home_seed+.055,window_occupancy);
  vec3 warmth=mix(vec3(1.0,.64,.30),vec3(.68,.83,1.0),step(.83,fract(home_seed*5.71)));
  EMISSION=warmth*lit*2.8*mask;
 }
 ALPHA=colour.a;
 ALPHA_SCISSOR_THRESHOLD=.24;
 ALPHA_ANTIALIASING_EDGE=.18;
 ALPHA_TEXTURE_COORDINATE=uv*vec2(textureSize(colour_atlas,0));
 NORMAL=normalize((VIEW_MATRIX*vec4(object_rotation*normalize(local_normal/object_scale+vec3(.000001)),0)).xyz);
 ROUGHNESS=.88;
 SPECULAR=.18;
 BACKLIGHT=colour.rgb*.18;
}
