shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D grass_albedo : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D soil_albedo : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
varying vec3 world_pos;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){
 vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1)).xyz;}
void fragment(){
 // Absolute route UVs survive rebasing and cross 512 m streaming boundaries.
 vec2 p=UV*3.5;
 vec2 cell=floor(p/vec2(64,96));vec2 q=mod(p,vec2(64,96));
 float stage=COLOR.a;float axis=mix(p.x,p.y,step(.5,hash(cell+17.0)));
 float edge=min(min(q.x,64.0-q.x),min(q.y,96.0-q.y));
 float near_rows=1.0-smoothstep(80.0,320.0,distance(world_pos,CAMERA_POSITION_WORLD));
 float phase=axis*14.0;
 float row_aa=1.0-smoothstep(.8,3.14,fwidth(phase));
 float rows=.5+.5*sin(phase);float texture_grass=texture(grass_albedo,p/1.2).g;
 float patch=noise(p*.19)*.6+noise(p*.63)*.4;
 vec3 soil=texture(soil_albedo,p/3.5).rgb*vec3(.40,.37,.25);
 vec3 crop=mix(vec3(.065,.155,.018),vec3(.18,.27,.048),patch*.55+texture_grass*.45);
 if(stage>.70)crop=mix(vec3(.19,.20,.048),vec3(.34,.30,.09),patch*.6+texture_grass*.4);
 if(stage<.19)crop=mix(vec3(.09,.13,.09),vec3(.20,.28,.08),smoothstep(.76,.94,rows));
 if(stage>.92)crop=mix(soil,vec3(.32,.28,.12),texture_grass*.65);
 crop*=mix(.92,1.06,rows*near_rows*row_aa+.5*(1.0-near_rows*row_aa));
 float bund=1.0-smoothstep(.30,.95,edge);
 ALBEDO=mix(crop,soil*1.3,bund);
 ROUGHNESS=mix(stage<.19?.56:.92,.96,bund);
 SPECULAR=stage<.19?.25:.12;
}
