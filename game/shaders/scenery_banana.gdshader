shader_type spatial;
render_mode cull_disabled, diffuse_burley;
varying vec3 local_pos;
void vertex(){
 local_pos=VERTEX;
 vec3 p=(MODEL_MATRIX*vec4(VERTEX,1)).xyz;
 float tip=UV.y*UV.y;
 VERTEX.x+=sin(TIME*1.2+p.x*.4+p.z*.3)*.075*tip;
 VERTEX.z+=cos(TIME*.9+p.x*.3)*.045*tip;
}
void fragment(){
 float side=abs(UV.x-.5)*2.0;
 float rib=1.0-smoothstep(.015,.06,side);
 float phase=UV.y*95.0-side*15.0;
 float veins=pow(.5+.5*sin(phase),12.0);
 float fine=.5+.5*sin(phase*4.1);
 float mottling=sin(UV.y*27.0+UV.x*15.0)*sin(UV.y*13.0-UV.x*22.0);
 vec3 leaf=COLOR.rgb*mix(.83,1.10,side)*(.96+mottling*.035);
 ALBEDO=mix(leaf,vec3(.24,.34,.055),rib*.48)*(1.0-veins*.13-fine*.018);
 ROUGHNESS=.62+veins*.10;
 SPECULAR=.25;
 NORMAL_MAP=vec3(.5+cos(phase)*.025,.5+sin(phase)*.035,1.0);
 NORMAL_MAP_DEPTH=.3;
 BACKLIGHT=ALBEDO*.18;
}
