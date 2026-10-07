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


uniform float source_values[64];
void fragment() {
 if (!FRONT_FACING) { NORMAL = -NORMAL; }
 vec3 n0 = object_position;
 float n1 = grain((n0)*(source_values[0]),source_values[1],source_values[2],source_values[3]);
 float n2 = mix(source_values[4],source_values[5],clamp(((n1-source_values[6])/(source_values[7]-source_values[8])),source_values[9],source_values[10]));
 vec3 n3 = bump_normal(NORMAL,VERTEX,(n1)*(source_values[11]),(source_values[12]));
 vec3 n4 = author_normal;
 vec3 n5 = n4;
 float n6 = (n5).z;
 float n7 = mix(source_values[13],source_values[14],smoothstep(source_values[15],source_values[16],clamp(((n6-source_values[17])/(source_values[18]-source_values[19])),source_values[20],source_values[21])));
 float n8 = grain((n0)*(source_values[22]),source_values[23],source_values[24],source_values[25]);
 float n9 = mix(source_values[26],source_values[27],clamp(((n8-source_values[28])/(source_values[29]-source_values[30])),source_values[31],source_values[32]));
 float n10 = (n7*n9);
 float n11 = source_values[33];
 float n12 = clamp(n11,source_values[34],source_values[35]);
 ALBEDO = mix(mix(vec3(source_values[36],source_values[37],source_values[38]),vec3(source_values[39],source_values[40],source_values[41]),n10),vec3(source_values[42],source_values[43],source_values[44]),n12);
 ROUGHNESS = clamp(mix(mix(n2,source_values[45],n10),source_values[46],n12),source_values[47],source_values[48]);
 METALLIC = mix(mix(source_values[49],source_values[50],n10),source_values[51],n12);
 EMISSION = mix(mix((vec3(source_values[52],source_values[53],source_values[54])*source_values[55]),(vec3(source_values[56],source_values[57],source_values[58])*source_values[59]),n10),(vec3(source_values[60],source_values[61],source_values[62])*source_values[63]),n12);
 NORMAL = mix(mix(n3,n3,n10),n3,n12);
}
