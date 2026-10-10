shader_type spatial;
render_mode cull_disabled, diffuse_burley, alpha_to_coverage;
uniform sampler2D colour_atlas : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D normal_atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform float centre_y = 5.0;
uniform float palettes = 1.0;
varying flat float view_index;
varying flat float palette_index;
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
 view_index=mod(floor(angle/(2.0*PI)*8.0+.5)+8.0,8.0);
 palette_index=min(palettes-1.0,floor(INSTANCE_CUSTOM.x*palettes));
 object_scale=vec3(scale_x,scale_y,scale_z);
 object_rotation=mat3(normalize(MODEL_MATRIX[0].xyz),normalize(MODEL_MATRIX[1].xyz),normalize(MODEL_MATRIX[2].xyz));
 MODELVIEW_MATRIX=VIEW_MATRIX*mat4(vec4(right*horizontal_scale,0),vec4(0,scale_y,0,0),vec4(to_camera*horizontal_scale,0),vec4(origin,1));
 VERTEX.y+=centre_y;
}
void fragment() {
 vec2 tile=vec2(mod(view_index,4.0),1.0-floor(view_index/4.0));
 tile.y+=palette_index*2.0;
 vec2 uv=(clamp(UV,vec2(.0015),vec2(.9985))+tile)/vec2(4,2.0*palettes);
 vec4 colour=texture(colour_atlas,uv);
 ALBEDO=colour.rgb;
 ALPHA=colour.a;
 ALPHA_SCISSOR_THRESHOLD=.24;
 ALPHA_ANTIALIASING_EDGE=.18;
 ALPHA_TEXTURE_COORDINATE=uv*vec2(textureSize(colour_atlas,0));
 vec3 local_normal=texture(normal_atlas,uv).rgb*2.0-1.0;
 NORMAL=normalize((VIEW_MATRIX*vec4(object_rotation*normalize(local_normal/object_scale),0)).xyz);
 ROUGHNESS=.88;
 SPECULAR=.18;
 BACKLIGHT=colour.rgb*.18;
}
