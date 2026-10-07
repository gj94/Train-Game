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
uniform float source_values[54];
void fragment() {
 if (!FRONT_FACING) { NORMAL = -NORMAL; }
 vec3 n0 = vec3(UV.x,source_values[0]-UV.y,source_values[1]);
 vec4 n1 = texture(tex0,vec2((n0).x,source_values[2]-(n0).y));
 float n2 = mix(source_values[3],source_values[4],clamp(((dot(n1.rgb,vec3(source_values[5],source_values[6],source_values[7]))-source_values[8])/(source_values[9]-source_values[10])),source_values[11],source_values[12]));
 float n3 = (dot(n1.rgb,vec3(source_values[13],source_values[14],source_values[15]))*source_values[16]);
 ALBEDO = mix(vec3(source_values[17],source_values[18],source_values[19]),vec3(source_values[20],source_values[21],source_values[22]),n3);
 ROUGHNESS = clamp(mix(n2,source_values[23],n3),source_values[24],source_values[25]);
 METALLIC = mix(source_values[26],source_values[27],n3);
 EMISSION = mix((vec3(source_values[28],source_values[29],source_values[30])*source_values[31]),(vec3(source_values[32],source_values[33],source_values[34])*source_values[35]),n3);
 NORMAL = mix(NORMAL,NORMAL,n3);
 float fresnel=source_values[36]+source_values[37]*pow(source_values[38]-clamp(dot(NORMAL,VIEW),source_values[39],source_values[40]),source_values[41]);
 ALPHA = mix(mix(source_values[42],source_values[43],n3),clamp(source_values[44]+fresnel*source_values[45],source_values[46],source_values[47]),mix(source_values[48],source_values[49],n3));
 METALLIC = source_values[50]; SPECULAR = source_values[51];
 if (onboard_glass) { ALPHA *= source_values[52]; SPECULAR = source_values[53]; }
}
