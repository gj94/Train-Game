shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;
// Source linear albedo and roughness, baked into vertex colour without new UVs.
void fragment() {
 ALBEDO=COLOR.rgb;
 ROUGHNESS=COLOR.a;
 METALLIC=0.0;
 SPECULAR=.5;
}
