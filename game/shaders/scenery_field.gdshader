shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D soil_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D crop_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform int stage = 0;
varying vec3 world_pos;
varying vec4 plot;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
void vertex() { world_pos=(MODEL_MATRIX*vec4(VERTEX,1)).xyz; plot=INSTANCE_CUSTOM; }
void fragment() {
 vec2 p=world_pos.xz;
 float axis=mix(p.x,p.y,step(.5,plot.y));
 float detail=texture(crop_albedo,p/2.2).g;
 float patch=noise(p*.045);
 float furrow=.5+.5*sin(axis*16.0);
 float visibility=1.0-smoothstep(65.0,300.0,distance(world_pos,CAMERA_POSITION_WORLD));
 vec3 soil=texture(soil_albedo,p/3.1).rgb*vec3(.48,.45,.34);
 vec3 crop=mix(vec3(.12,.20,.035),vec3(.24,.28,.065),patch);
 float rough=.92;
 if(stage==0) {
  crop=soil*mix(.70,1.05,furrow*visibility+.5*(1.0-visibility));
 } else if(stage==1) {
  float seedlings=smoothstep(.57,.85,furrow)*(.38+.22*detail);
  crop=mix(vec3(.043,.065,.034),vec3(.095,.18,.024),seedlings);
  rough=mix(.24,.86,seedlings);
 } else if(stage==2) {
  crop*=mix(.60,1.25,detail)*mix(.79,1.0,furrow*visibility+.5*(1.0-visibility));
 } else if(stage==3) {
  crop=mix(vec3(.24,.25,.055),vec3(.40,.34,.11),patch)*mix(.72,1.08,detail);
 } else {
  crop=mix(soil,vec3(.30,.25,.105)*mix(.7,1.1,detail),.65);
  crop*=mix(.80,1.02,furrow*visibility+.5*(1.0-visibility));
 }
 float near_plants=1.0-smoothstep(22.0,65.0,distance(world_pos,CAMERA_POSITION_WORLD));
 if(stage==2 || stage==3) crop=mix(crop,soil*vec3(.70,.78,.83),near_plants*.82);
 ALBEDO=crop*mix(.89,1.10,plot.x);
 ROUGHNESS=rough;
 SPECULAR=stage==1 ? .7 : .2;
 if(stage==1) {
  NORMAL_MAP=vec3(.5+sin(p.x*2.1+p.y*1.4+TIME*.35)*.014,.5+cos(p.y*2.8-TIME*.42)*.013,1);
  NORMAL_MAP_DEPTH=.2;
 }
}