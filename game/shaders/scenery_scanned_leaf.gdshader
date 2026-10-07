shader_type spatial;
render_mode cull_disabled, diffuse_burley, alpha_to_coverage;
uniform sampler2D leaf_albedo : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D leaf_normal : hint_normal, filter_linear_mipmap_anisotropic;
uniform bool use_vertex_tint = false;
varying float canopy_shade;
void vertex() {
 canopy_shade=mix(.70,1.0,smoothstep(2.0,8.0,VERTEX.y));
 vec3 p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 float height=clamp((VERTEX.y-1.4)*.4,0.0,1.0);
 VERTEX.x+=sin(p.x*.85+p.z*.6+TIME*1.1)*height*.025;
 VERTEX.z+=cos(p.x*.65+p.z*.8+TIME*.8)*height*.018;
}
void fragment() {
 vec4 leaf=texture(leaf_albedo,UV);
 ALBEDO=leaf.rgb*(use_vertex_tint ? COLOR.rgb*canopy_shade : vec3(1));
 ALPHA=leaf.a;
 ALPHA_SCISSOR_THRESHOLD=.12;
 ALPHA_ANTIALIASING_EDGE=.08;
 ALPHA_TEXTURE_COORDINATE=UV*vec2(textureSize(leaf_albedo,0));
 NORMAL_MAP=texture(leaf_normal,UV).rgb;
 NORMAL_MAP_DEPTH=.35;
 ROUGHNESS=.88;
 SPECULAR=.18;
 BACKLIGHT=ALBEDO*.26;
}