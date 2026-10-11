shader_type sky;
// No TIME, POSITION or LIGHT uniforms: paused skies stay cached. Parameters
// update at a bounded rate from the simulation clock, including after a skip.
uniform sampler2D daylight_panorama : filter_linear_mipmap, repeat_enable;
uniform vec3 sun_direction = vec3(0.7,0.7,0.1);
uniform float daylight = 1.0;
uniform float twilight = 0.0;
uniform float night = 0.0;

float hash31(vec3 p) {
 p=fract(p*vec3(.1031,.11369,.13787));
 p+=dot(p,p.yzx+19.19);
 return fract((p.x+p.y)*p.z);
}
void sky() {
 vec3 direction=normalize(EYEDIR);
 float horizon=pow(1.0-abs(direction.y),4.0);
 vec3 photograph=min(texture(daylight_panorama,SKY_COORDS).rgb,vec3(2.0));
 vec3 night_sky=mix(vec3(.002,.004,.012),vec3(.009,.015,.028),horizon);
 vec3 colour=mix(night_sky,photograph,daylight);
 float toward_sun=pow(max(dot(direction,normalize(vec3(sun_direction.x,.04,sun_direction.z))),0.0),5.0);
 colour+=vec3(.50,.125,.028)*twilight*horizon*(.18+.82*toward_sun);
 float sun_dot=dot(direction,sun_direction);
 float disc=smoothstep(cos(.0050),cos(.0041),sun_dot);
 colour+=vec3(8.0,6.0,3.8)*disc*smoothstep(-.018,.015,sun_direction.y);
 // A restrained representative moon and stable stars. Omit tiny points from
 // the lighting cubemap to avoid specular fireflies; no animated noise.
 if (!AT_CUBEMAP_PASS && night>.001 && direction.y>0.0) {
  vec3 cell=floor(direction*650.0);
  float stars=step(.9988,hash31(cell))*pow(max(0.0,1.0-length(fract(direction*650.0)-.5)*2.0),3.0);
  colour+=vec3(.40,.46,.60)*stars*night*smoothstep(.04,.3,direction.y);
  float moon_dot=dot(direction,-sun_direction);
  float moon=smoothstep(cos(.0060),cos(.0050),moon_dot);
  colour+=vec3(.52,.57,.64)*moon*night*(.65+.35*hash31(floor(direction*3000.0)));
 }
 COLOR=max(colour,vec3(0.0));
}
