shader_type spatial;
render_mode cull_disabled, diffuse_burley;
uniform float wind_strength = 0.13;
uniform float height_scale = 10.0;
uniform float translucency = 0.30;
varying vec3 position_local;
float grain(vec3 p) { return fract(sin(dot(p,vec3(12.9898,78.233,39.425)))*43758.5453); }
void vertex() {
 position_local=VERTEX;
 vec3 p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 float weight=pow(clamp(VERTEX.y/height_scale,0.0,1.0),1.5);
 VERTEX.x+=sin(TIME*1.15+p.x*.33+p.z*.27)*wind_strength*weight;
 VERTEX.z+=cos(TIME*.87+p.x*.41-p.z*.19)*wind_strength*.68*weight;
}
void fragment() {
 float detail=grain(floor(position_local*170.0));
 ALBEDO=COLOR.rgb*mix(.91,1.07,detail);
 ROUGHNESS=.85;
 SPECULAR=.18;
 BACKLIGHT=COLOR.rgb*translucency;
}