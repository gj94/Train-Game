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


uniform float source_values[43];
void fragment() {
 if (!FRONT_FACING) { NORMAL = -NORMAL; }
 vec3 n0 = object_position;
 float n1 = (n0).y;
 float n2 = (n1*source_values[0]);
 float n3 = fract(n2);
 float n4 = (n3-source_values[1]);
 float n5 = (n4*n4);
 float n6 = (n0).x;
 float n7 = (n0).z;
 float n8 = (n6+n7);
 float n9 = (n8*source_values[2]);
 float n10 = fract(n9);
 float n11 = (n10-source_values[3]);
 float n12 = (n11*n11);
 float n13 = (n5+n12);
 float n14 = (source_values[4]-step(source_values[5],n13));
 float n15 = (n14*source_values[6]);
 vec4 n16 = mix(vec4(source_values[7],source_values[8],source_values[9],source_values[10]),vec4(source_values[11],source_values[12],source_values[13],source_values[14]),n15);
 float n17 = (n1*source_values[15]);
 float n18 = sin(n17);
 float n19 = abs(n18);
 float n20 = pow(max(n19,source_values[16]),source_values[17]);
 float n21 = (n20*source_values[18]);
 float n22 = (n8*source_values[19]);
 float n23 = sin(n22);
 float n24 = abs(n23);
 float n25 = pow(max(n24,source_values[20]),source_values[21]);
 float n26 = (n25*source_values[22]);
 float n27 = (n21+n26);
 float n28 = (n27*source_values[23]);
 float n29 = grain((n0)*(source_values[24]),source_values[25],source_values[26],source_values[27]);
 float n30 = (n29*source_values[28]);
 float n31 = (n28+n30);
 float n32 = (n31*source_values[29]);
 float n33 = (source_values[30]+n32);
 vec4 n34 = mix(n16,(n16*vec4(n33)),source_values[31]);
 float n35 = (n31*source_values[32]);
 float n36 = (source_values[33]+n35);
 vec3 n37 = bump_normal(NORMAL,VERTEX,(n31)*(source_values[34]),(source_values[35]));
 ALBEDO = n34.rgb;
 ROUGHNESS = clamp(n36,source_values[36],source_values[37]);
 METALLIC = source_values[38];
 EMISSION = (vec3(source_values[39],source_values[40],source_values[41])*source_values[42]);
 NORMAL = n37;
}
