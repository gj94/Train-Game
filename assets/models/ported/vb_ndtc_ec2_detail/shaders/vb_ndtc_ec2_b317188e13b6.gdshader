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


uniform float source_values[67];
void fragment() {
 if (!FRONT_FACING) { NORMAL = -NORMAL; }
 vec3 n0 = object_position;
 float n1 = (n0).y;
 float n2 = (n1*source_values[0]);
 float n3 = fract(n2);
 vec4 n4 = mix(mix(mix(mix(vec4(source_values[1],source_values[2],source_values[3],source_values[4]),vec4(source_values[5],source_values[6],source_values[7],source_values[8]),step(source_values[9],n3)),vec4(source_values[10],source_values[11],source_values[12],source_values[13]),step(source_values[14],n3)),vec4(source_values[15],source_values[16],source_values[17],source_values[18]),step(source_values[19],n3)),vec4(source_values[20],source_values[21],source_values[22],source_values[23]),step(source_values[24],n3));
 float n5 = (n1*source_values[25]);
 float n6 = (n0).z;
 float n7 = (n6*source_values[26]);
 float n8 = (source_values[27]-abs(mod(n7,max(source_values[28]*source_values[29],source_values[30]))-source_values[31]));
 float n9 = (n8*source_values[32]);
 float n10 = (n5+n9);
 float n11 = fract(n10);
 float n12 = (n11-source_values[33]);
 float n13 = abs(n12);
 float n14 = (source_values[34]-step(source_values[35],n13));
 float n15 = (n6*source_values[36]);
 float n16 = fract(n15);
 float n17 = step(source_values[37],n16);
 float n18 = (n14*n17);
 vec4 n19 = mix(vec4(source_values[38],source_values[39],source_values[40],source_values[41]),n4,n18);
 float n20 = (n0).y;
 float n21 = (n20*source_values[42]);
 float n22 = sin(n21);
 float n23 = abs(n22);
 float n24 = pow(max(n23,source_values[43]),source_values[44]);
 float n25 = (n24*source_values[45]);
 float n26 = (n0).x;
 float n27 = (n0).z;
 float n28 = (n26+n27);
 float n29 = (n28*source_values[46]);
 float n30 = sin(n29);
 float n31 = abs(n30);
 float n32 = pow(max(n31,source_values[47]),source_values[48]);
 float n33 = (n32*source_values[49]);
 float n34 = (n25+n33);
 float n35 = (n34*source_values[50]);
 float n36 = grain((n0)*(source_values[51]),source_values[52],source_values[53],source_values[54]);
 float n37 = (n36*source_values[55]);
 float n38 = (n35+n37);
 float n39 = (n38*source_values[56]);
 float n40 = (source_values[57]+n39);
 vec3 n41 = bump_normal(NORMAL,VERTEX,(n38)*(source_values[58]),(source_values[59]));
 ALBEDO = n19.rgb;
 ROUGHNESS = clamp(n40,source_values[60],source_values[61]);
 METALLIC = source_values[62];
 EMISSION = (vec3(source_values[63],source_values[64],source_values[65])*source_values[66]);
 NORMAL = n41;
}
