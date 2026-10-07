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

uniform sampler2D tex0 : filter_linear_mipmap_anisotropic, repeat_disable;
uniform float source_values[64];
void fragment() {
 if (!FRONT_FACING) { NORMAL = -NORMAL; }
 vec3 n0 = object_position;
 float n1 = grain((n0)*(source_values[0]),source_values[1],source_values[2],source_values[3]);
 vec4 n2 = mix(vec4(source_values[4],source_values[5],source_values[6],source_values[7]),vec4(source_values[8],source_values[9],source_values[10],source_values[11]),clamp((n1-source_values[12])/source_values[13],source_values[14],source_values[15]));
 vec3 n3 = author_position;
 float n4 = (n3).x;
 float n5 = (n4+source_values[16]);
 float n6 = (n5/source_values[17]);
 float n7 = (n3).y;
 float n8 = (n7+source_values[18]);
 float n9 = (n8/source_values[19]);
 vec3 n10 = vec3(n6,n9,source_values[20]);
 vec4 n11 = texture(tex0,vec2((n10).x,source_values[21]-(n10).y));
 vec3 n12 = author_position;
 float n13 = (n12).z;
 float n14 = mix(source_values[22],source_values[23],smoothstep(source_values[24],source_values[25],clamp(((n13-source_values[26])/(source_values[27]-source_values[28])),source_values[29],source_values[30])));
 float n15 = mix(source_values[31],source_values[32],smoothstep(source_values[33],source_values[34],clamp(((n13-source_values[35])/(source_values[36]-source_values[37])),source_values[38],source_values[39])));
 float n16 = (n14*n15);
 float n17 = (dot(n11.rgb,vec3(source_values[40],source_values[41],source_values[42]))*n16);
 vec4 n18 = mix(n2,vec4(source_values[43],source_values[44],source_values[45],source_values[46]),n17);
 float n19 = mix(source_values[47],source_values[48],clamp(((n1-source_values[49])/(source_values[50]-source_values[51])),source_values[52],source_values[53]));
 float n20 = (n17*source_values[54]);
 float n21 = (n19+n20);
 vec3 n22 = bump_normal(NORMAL,VERTEX,(n1)*(source_values[55]),(source_values[56]));
 ALBEDO = n18.rgb;
 ROUGHNESS = clamp(n21,source_values[57],source_values[58]);
 METALLIC = source_values[59];
 EMISSION = (vec3(source_values[60],source_values[61],source_values[62])*source_values[63]);
 NORMAL = n22;
}
