shader_type spatial;
render_mode cull_disabled;
uniform mat4 author_from_mesh;
uniform sampler3D noise_volume : filter_linear, repeat_enable;
uniform bool onboard_glass = false;
varying vec3 author_position;
varying vec3 author_normal;
varying vec3 object_position;
varying vec3 generated_position;
void vertex() {
 author_position = (author_from_mesh * vec4(VERTEX, 1.0)).xyz;
 author_normal = normalize(mat3(author_from_mesh) * NORMAL);
 object_position = vec3(CUSTOM0.x, 1.0-CUSTOM0.y, CUSTOM0.z);
 generated_position = vec3(UV2.x, 1.0-UV2.y, 1.0-CUSTOM0.w);
}
float noise3(vec3 p) {
 vec3 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return texture(noise_volume,(i+f+vec3(0.5))/64.0).r;
}
float grain(vec3 p, float detail, float rough, float lac) {
 // Fade subpixel grain before it aliases in motion; broad service wear stays.
 float footprint=max(length(dFdx(p)),length(dFdy(p)));
 if(footprint>=2.0) return 0.5;
 float total=0.0, weight=0.0, amplitude=1.0;
 for(int i=0;i<5;i++) { if(float(i)>detail) break;
  total+=(footprint>=2.0 ? 0.5 : mix(noise3(p),0.5,smoothstep(0.5,2.0,footprint)))*amplitude;
  weight+=amplitude; p*=lac; footprint*=lac; amplitude*=rough;
 }
 return total/max(weight,0.0001);
}
vec3 bump_normal(vec3 n, vec3 p, float h, float strength) {
 vec3 px=dFdx(p), py=dFdy(p);
 vec3 r1=cross(py,n), r2=cross(n,px); float det=dot(px,r1);
 vec3 grad=sign(det)*(dFdx(h)*r1+dFdy(h)*r2);
 return normalize(abs(det)*n-strength*grad+vec3(1e-20));
}

uniform sampler2D tex0 : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D tex1 : filter_linear_mipmap_anisotropic, repeat_disable;
uniform float source_values[29];
void fragment() {
 if (!FRONT_FACING) { NORMAL = -NORMAL; }
 vec3 n0 = author_position;
 float n1 = (n0).y;
 float n2 = (n1+source_values[0]);
 float n3 = (n2/source_values[1]);
 float n4 = (n0).z;
 float n5 = (n4+-source_values[2]);
 float n6 = (n5/source_values[3]);
 vec3 n7 = vec3(n3,n6,source_values[4]);
 vec4 n8 = texture(tex0,vec2((n7).x,source_values[5]-(n7).y));
 vec4 n9 = texture(tex1,vec2((n7).x,source_values[6]-(n7).y));
 vec3 n10 = author_position;
 float n11 = grain((n10)*(source_values[7]),source_values[8],source_values[9],source_values[10]);
 vec3 n12 = bump_normal(NORMAL,VERTEX,(n11)*(source_values[11]),(source_values[12]));
 vec3 n13 = author_position;
 float n14 = grain((n13)*(source_values[13]),source_values[14],source_values[15],source_values[16]);
 vec3 n15 = bump_normal(n12,VERTEX,(n14)*(source_values[17]),(source_values[18]));
 ALBEDO = n8.rgb;
 ROUGHNESS = clamp(dot(n9.rgb,vec3(source_values[19],source_values[20],source_values[21])),source_values[22],source_values[23]);
 METALLIC = source_values[24];
 EMISSION = (vec3(source_values[25],source_values[26],source_values[27])*source_values[28]);
 NORMAL = n15;
}
