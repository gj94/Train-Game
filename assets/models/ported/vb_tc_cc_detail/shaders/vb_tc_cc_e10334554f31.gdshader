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


uniform float source_values[28];
void fragment() {
 if (!FRONT_FACING) { NORMAL = -NORMAL; }
 float n0 = grain((generated_position)*(source_values[0]),source_values[1],source_values[2],source_values[3]);
 vec4 n1 = mix(vec4(source_values[4],source_values[5],source_values[6],source_values[7]),vec4(source_values[8],source_values[9],source_values[10],source_values[11]),clamp((n0-source_values[12])/source_values[13],source_values[14],source_values[15]));
 vec3 n2 = bump_normal(NORMAL,VERTEX,(n0)*(source_values[16]),(source_values[17]));
 ALBEDO = n1.rgb;
 ROUGHNESS = clamp(source_values[18],source_values[19],source_values[20]);
 METALLIC = source_values[21];
 EMISSION = (vec3(source_values[22],source_values[23],source_values[24])*source_values[25]);
 NORMAL = n2;
 CLEARCOAT = source_values[26];
 CLEARCOAT_ROUGHNESS = source_values[27];
}
