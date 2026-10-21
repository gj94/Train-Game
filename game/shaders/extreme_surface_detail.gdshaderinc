// Static, metre-scaled detail. The derivatives fade both colour and normal detail
// before its cells become subpixel; no screen-space grain or animated noise.
// Use only integer/binary-fraction frequencies here. The route origin is snapped
// to 1024 m, so its phase is exact without ever adding 300 km to a local point.
// The hash is periodic in 4096 cells; reducing the constant offset, not the
// interpolated position, keeps derivatives continuous at a period boundary.
vec2 extreme_periodic_position(vec2 local_p,vec2 origin,vec2 frequency) {
 return local_p*frequency+mod(origin*frequency,vec2(4096.0));
}

// 30 cm pavers use the rational frequency 10/3. Split the integer origin into
// whole 3 m blocks and a remainder before division: origin/.30 at 300 km would
// otherwise discard the millimetre-wide joints. Colour and bevel share this.
vec2 extreme_paver_position(vec2 local_p,vec2 origin) {
 vec2 blocks=floor(origin/3.0);
 vec2 local_blocks=floor(local_p/3.0);
 vec2 whole_cells=mod(mod(blocks+local_blocks,vec2(4096.0))*10.0,vec2(4096.0));
 vec2 remainder=(origin-blocks*3.0)+(local_p-local_blocks*3.0);
 // This coordinate is used only for periodic cells, never texture gradients.
 // Callers measure the footprint from local_p, not this wrapped coordinate.
 return whole_cells+remainder*(10.0/3.0);
}

float extreme_hash(vec2 cell) {
 vec3 p=fract(vec3(mod(cell,vec2(4096.0)).xyx)*.1031);
 p+=dot(p,p.yzx+33.33);
 return fract((p.x+p.y)*p.z);
}

float extreme_detail_filter(vec2 p) {
 float footprint=max(length(dFdx(p)),length(dFdy(p)));
 return 1.0-smoothstep(.35,1.25,footprint);
}

// Value plus analytic first derivatives. Quintic interpolation keeps the normal
// continuous across cell boundaries, unlike differentiating hard hash grain.
vec3 extreme_noise_gradient(vec2 p) {
 vec2 cell=floor(p),f=fract(p);
 vec2 u=f*f*f*(f*(f*6.0-15.0)+10.0);
 vec2 du=30.0*f*f*(f*(f-2.0)+1.0);
 float a=extreme_hash(cell),b=extreme_hash(cell+vec2(1,0));
 float c=extreme_hash(cell+vec2(0,1)),d=extreme_hash(cell+vec2(1));
 float k=a-b-c+d;
 float value=a+(b-a)*u.x+(c-a)*u.y+k*u.x*u.y;
 vec2 gradient=du*vec2(b-a+k*u.y,c-a+k*u.x);
 float resolved=extreme_detail_filter(p);
 return vec3(mix(.5,value,resolved),gradient*resolved);
}

// A derivative frame keeps world-projected texture normals aligned to albedo
// on rotated roads. It does not change vertex positions, UVs or mesh tangents.
vec3 extreme_mapped_normal(vec3 n,vec3 p,vec2 uv,vec3 bump) {
 vec3 dp1=dFdx(p),dp2=dFdy(p);
 vec2 duv1=dFdx(uv),duv2=dFdy(uv);
 vec3 p2=cross(dp2,n),p1=cross(n,dp1);
 vec3 t=p2*duv1.x+p1*duv2.x,b=p2*duv1.y+p1*duv2.y;
 float scale=inversesqrt(max(max(dot(t,t),dot(b,b)),.00000001));
 return normalize(mat3(t*scale,b*scale,n)*bump);
}
