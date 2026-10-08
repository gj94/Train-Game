shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform float simulation_time = 0.0;
uniform bool seated = false;
uniform bool skirt = false;
varying vec3 rest_position;
varying vec4 person_data;
vec3 turn_x(vec3 p, vec3 pivot, float angle) {
 p-=pivot; float c=cos(angle),s=sin(angle);
 return pivot+vec3(p.x,c*p.y-s*p.z,s*p.y+c*p.z);
}
void vertex() {
 rest_position=VERTEX;
 person_data=INSTANCE_CUSTOM;
 float phase=simulation_time*7.5+INSTANCE_CUSTOM.r*6.283185;
 float walk=INSTANCE_CUSTOM.g;
 float side=sign(VERTEX.x);
 if (!seated) {
  if (VERTEX.y<0.91) {
   if (skirt) { VERTEX.z+=sin(phase+VERTEX.x*7.0)*0.065*walk*(1.0-smoothstep(.18,.88,VERTEX.y)); }
   else {
    float swing=sin(phase+side*1.5708)*.37*walk;
    vec3 pivot=vec3(side*.095,.88,0);
    VERTEX=turn_x(VERTEX,pivot,swing);
    NORMAL=turn_x(NORMAL,vec3(0),swing);
   }
  } else if (abs(VERTEX.x)>.185 && VERTEX.y<1.35) {
   float swing=-sin(phase+side*1.5708)*.26*walk;
   VERTEX=turn_x(VERTEX,vec3(side*.19,1.29,0),swing);
   NORMAL=turn_x(NORMAL,vec3(0),swing);
  }
  VERTEX.y+=abs(sin(phase))*.018*walk;
 }
 // Small breathing motion follows simulation time, so pause freezes it too.
 VERTEX.z+=sin(simulation_time*1.7+INSTANCE_CUSTOM.r*12.0)*.003*smoothstep(.85,1.35,VERTEX.y);
}
void fragment() {
 vec3 paint=COLOR.rgb;
 float cloth=smoothstep(.10,.18,max(paint.r,max(paint.g,paint.b)));
 if(fract(sin(dot(FRAGCOORD.xy,vec2(12.9898,78.233)))*43758.5453)>person_data.a) { discard; }
 paint*=mix(vec3(.86+person_data.b*.24),vec3(.78+person_data.r*.34,.88+person_data.b*.15,.88+person_data.r*.17),cloth);
 float weave=sin(rest_position.x*650.0)*sin(rest_position.y*750.0)*.018;
 ALBEDO=paint*(1.0+weave);ROUGHNESS=.87;SPECULAR=.22;
}
