"""Translate the pinned Blender material graphs to Godot PBR shaders.

Runs inside background Blender. Images retain source pixels; object coordinates
are carried through consolidation in UV2/CUSTOM0. Shader text is staged for
installation through the Godot MCP (not written into the live editor here).
Cycles' multiple lobes become parameter blends; transmission becomes Fresnel
alpha glass. Noise is filtered real-time value noise, not Cycles Perlin noise.
"""
import hashlib
import json
import re
import bpy
from pathlib import Path

HEADER = '''shader_type spatial;
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
'''

def num(v):
    s = f'{float(v):.9g}'
    return s if '.' in s or 'e' in s else s+'.0'

def literal(v, kind):
    if kind == 'float':
        return num(v if isinstance(v,(int,float)) else sum(v[:3])/3)
    if isinstance(v,(int,float)):
        return f'{kind}({num(v)})'
    return kind+'('+','.join(num(x) for x in v[:int(kind[-1])])+')'

class Compiler:
    def __init__(self, mat, texture_dir):
        self.mat, self.texture_dir = mat, texture_dir
        self.lines, self.uniforms, self.textures, self.cache = [], [], {}, {}

    def inp(self, node, name, kind='float'):
        s=node.inputs[name]
        if s.is_linked:
            link=s.links[0]
            value, sourcekind=self.out(link.from_node,link.from_socket)
            if kind==sourcekind: return value
            if kind=='float': return f'dot({value}.rgb,vec3(0.2126,0.7152,0.0722))' if sourcekind=='vec4' else f'dot({value},vec3(0.333333))'
            if kind=='vec3': return value+'.rgb' if sourcekind=='vec4' else f'vec3({value})'
            return f'vec4({value},1.0)' if sourcekind=='vec3' else f'vec4({value})'
        return literal(s.default_value,kind)

    def out(self,n,s):
        key=(n.name,s.identifier)
        if key in self.cache: return self.cache[key]
        t=n.type; name=s.name; kind='float'; expr=None
        a=lambda k,typ='float': self.inp(n,k,typ)
        if t=='TEX_COORD':
            kind='vec3'
            expr={'Object':'author_position' if n.object else 'object_position','Generated':'generated_position','UV':'vec3(UV.x,1.0-UV.y,0.0)','Normal':'author_normal'}[name]
        elif t=='UVMAP': kind='vec3'; expr='vec3(UV.x,1.0-UV.y,0.0)'
        elif t=='NEW_GEOMETRY':
            kind='vec3'; expr={'Position':'author_position','Normal':'author_normal','True Normal':'author_normal','Incoming':'-VIEW'}[name]
        elif t=='ATTRIBUTE':
            assert n.attribute_name=='SURFV02_Wear', n.attribute_name
            expr='0.0'
        elif t=='TEX_NOISE':
            coord=a('Vector','vec3') if n.inputs['Vector'].is_linked else 'generated_position'
            expr=f'grain(({coord})*({a("Scale")}),{a("Detail")},{a("Roughness")},{a("Lacunarity")})'
            if name=='Color': expr=f'vec4(vec3({expr}),1.0)'; kind='vec4'
        elif t=='SEPXYZ': expr=f'({a("Vector","vec3")}).'+name.lower()
        elif t=='COMBXYZ': kind='vec3'; expr=f'vec3({a("X")},{a("Y")},{a("Z")})'
        elif t=='VECT_MATH':
            x,y=a(0,'vec3'),a(1,'vec3')
            if n.operation=='DOT_PRODUCT': expr=f'dot({x},{y})'
            else:
                kind='vec3'
                expr={'MULTIPLY':f'({x}*{y})','ADD':f'({x}+{y})','SUBTRACT':f'({x}-{y})'}[n.operation]
        elif t=='TEX_CHECKER':
            coord=a('Vector','vec3') if n.inputs['Vector'].is_linked else 'generated_position'
            factor=f'mod(dot(floor(({coord})*({a("Scale")})),vec3(1.0)),2.0)'
            expr=factor
            if name=='Color':
                kind='vec4'; expr=f'mix({a("Color1",kind)},{a("Color2",kind)},{factor})'
        elif t=='MATH':
            x,y,z=(a(i) for i in range(3)); op=n.operation
            expr={'ADD':f'({x}+{y})','SUBTRACT':f'({x}-{y})','MULTIPLY':f'({x}*{y})',
                  'DIVIDE':f'({x}/{y})','MULTIPLY_ADD':f'({x}*{y}+{z})','POWER':f'pow(max({x},0.0),{y})',
                  'MINIMUM':f'min({x},{y})','MAXIMUM':f'max({x},{y})','ABSOLUTE':f'abs({x})',
                  'SINE':f'sin({x})','ARCTAN2':f'atan({x},{y})','GREATER_THAN':f'step({y},{x})',
                  'FRACT':f'fract({x})','FLOOR':f'floor({x})','MODULO':f'mod({x},{y})',
                  'LESS_THAN':f'(1.0-step({y},{x}))',
                  'PINGPONG':f'({y}-abs(mod({x},max(2.0*{y},0.000001))-{y}))'}[op]
            if n.use_clamp: expr=f'clamp({expr},0.0,1.0)'
        elif t=='MAP_RANGE':
            x,lo,hi,ol,oh=(a(k) for k in ('Value','From Min','From Max','To Min','To Max'))
            ratio=f'(({x}-{lo})/({hi}-{lo}))'
            if n.clamp: ratio=f'clamp({ratio},0.0,1.0)'
            if n.interpolation_type=='SMOOTHSTEP': ratio=f'smoothstep(0.0,1.0,{ratio})'
            else: assert n.interpolation_type=='LINEAR', n.interpolation_type
            expr=f'mix({ol},{oh},{ratio})'
        elif t=='CLAMP': expr=f'clamp({a("Value")},{a("Min")},{a("Max")})'
        elif t=='VALTORGB':
            kind='vec4'; els=list(n.color_ramp.elements); expr=literal(els[0].color,kind)
            assert n.color_ramp.interpolation in ('LINEAR','EASE','CONSTANT')
            for prev,e in zip(els,els[1:]):
                f=f'clamp(({a(0)}-{num(prev.position)})/{num(e.position-prev.position)},0.0,1.0)'
                if n.color_ramp.interpolation=='EASE': f=f'smoothstep(0.0,1.0,{f})'
                if n.color_ramp.interpolation=='CONSTANT': f=f'step({num(e.position)},{a(0)})'
                expr=f'mix({expr},{literal(e.color,kind)},{f})'
            if name=='Alpha': expr=f'({expr}).a'; kind='float'
        elif t=='MIX_RGB':
            kind='vec4'; x,y=a(1,kind),a(2,kind)
            if n.blend_type=='MULTIPLY': y=f'({x}*{y})'
            elif n.blend_type=='ADD': y=f'({x}+{y})'
            else: assert n.blend_type=='MIX',n.blend_type
            expr=f'mix({x},{y},{a(0)})'
            if n.use_clamp: expr=f'clamp({expr},vec4(0.0),vec4(1.0))'
        elif t=='TEX_IMAGE':
            # Blender // is blend-relative, not a Windows UNC share.
            im=n.image; fname=im.filepath.replace('\\','/').rsplit('/',1)[-1]
            assert fname, 'Image needs a source filename: '+im.name
            path=self.texture_dir/fname
            if not path.exists():
                pixels = bytes(im.packed_file.data) if im.packed_file else Path(bpy.path.abspath(im.filepath)).read_bytes()
                path.write_bytes(pixels)
            uname='tex'+str(len(self.textures))
            self.textures[uname]=str(path.name)
            hints=('source_color, ' if im.colorspace_settings.name=='sRGB' else '')+'filter_linear_mipmap_anisotropic, repeat_disable'
            self.uniforms.append(f'uniform sampler2D {uname} : {hints};')
            coord=a('Vector','vec3') if n.inputs['Vector'].is_linked else 'vec3(UV.x,1.0-UV.y,0.0)'
            expr=f'texture({uname},vec2(({coord}).x,1.0-({coord}).y))'
            kind='vec4'
            if name=='Alpha': expr+='.a'; kind='float'
        elif t=='VECT_TRANSFORM': kind='vec3'; expr=a('Vector',kind)
        elif t=='TANGENT': kind='vec3'; expr='TANGENT'
        elif t=='BUMP':
            kind='vec3'; normal=a('Normal',kind) if n.inputs['Normal'].is_linked else 'NORMAL'
            expr=f'bump_normal({normal},VERTEX,({a("Height")})*({a("Distance")}),({a("Strength")}))'
        else: raise RuntimeError(f'{self.mat.name}: unsupported {t} / {name}')
        var='n'+str(len(self.lines)); self.lines.append(f' {kind} {var} = {expr};')
        self.cache[key]=(var,kind)
        return var,kind

    def surface(self,node):
        if node.type=='BSDF_TRANSPARENT':
            return dict(color='vec3(1.0)',rough='0.0',metal='0.0',alpha='0.0',emission='vec3(0.0)',normal='NORMAL',transmission='0.0')
        if node.type=='MIX_SHADER':
            x=self.surface(node.inputs[1].links[0].from_node)
            y=self.surface(node.inputs[2].links[0].from_node)
            fac=self.inp(node,0)
            return {k:f'mix({x[k]},{y[k]},{fac})' for k in x}
        assert node.type=='BSDF_PRINCIPLED',node.type
        a=lambda k,typ='float':self.inp(node,k,typ)
        return dict(color=a('Base Color','vec3'),rough=a('Roughness'),metal=a('Metallic'),alpha=a('Alpha'),
                    emission=f'({a("Emission Color","vec3")}*{a("Emission Strength")})',
                    normal=a('Normal','vec3') if node.inputs['Normal'].is_linked else 'NORMAL',transmission=a('Transmission Weight'))

    def compile(self):
        out=next(n for n in self.mat.node_tree.nodes if n.type=='OUTPUT_MATERIAL' and n.is_active_output)
        p=self.surface(out.inputs['Surface'].links[0].from_node)
        glass=any(n.type=='BSDF_PRINCIPLED' and n.inputs['Transmission Weight'].default_value>.1 for n in self.mat.node_tree.nodes)
        transparent=glass or any(n.type=='BSDF_TRANSPARENT' or n.type=='BSDF_PRINCIPLED' and (n.inputs['Alpha'].is_linked or n.inputs['Alpha'].default_value<.999) for n in self.mat.node_tree.nodes)
        body=[' ALBEDO = '+p['color']+';',' ROUGHNESS = clamp('+p['rough']+',0.025,1.0);',' METALLIC = '+p['metal']+';',' EMISSION = '+p['emission']+';',' NORMAL = '+p['normal']+';']
        # These source roles use single Principled lobes; keep their finish.
        principal=next((n for n in self.mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
        if principal and principal.inputs['Coat Weight'].default_value>0:
            body+=[' CLEARCOAT = '+num(principal.inputs['Coat Weight'].default_value)+';',
                   ' CLEARCOAT_ROUGHNESS = '+num(principal.inputs['Coat Roughness'].default_value)+';']
        if principal and principal.inputs['Anisotropic'].default_value>0:
            body+=[' ANISOTROPY = '+num(principal.inputs['Anisotropic'].default_value)+';']
        if glass:
            body+=[' float fresnel=0.04+0.96*pow(1.0-clamp(dot(NORMAL,VIEW),0.0,1.0),5.0);',
                   ' ALPHA = mix('+p['alpha']+',clamp(0.035+fresnel*0.35,0.035,0.38),'+p['transmission']+');',
                   ' METALLIC = 0.0; SPECULAR = 0.5;',
                   ' if (onboard_glass) { ALPHA *= 0.2; SPECULAR = 0.0; }']
        elif transparent: body+=[' ALPHA = '+p['alpha']+';',' ALPHA_SCISSOR_THRESHOLD = 0.01;']
        # Identical graph structures share one compiled shader. Authored values
        # stay in per-material uniforms rather than forcing 109 shader programs.
        values=[]
        def parameter(match):
            values.append(float(match.group()))
            return 'source_values['+str(len(values)-1)+']'
        fragment=re.sub(r'(?<![\w.])(?:\d+\.\d*|\.\d+|\d+)(?:[eE][-+]?\d+)?(?![\w.])',parameter,'\n'.join(self.lines+body))
        header=HEADER.replace('cull_disabled','cull_back') if self.mat.use_backface_culling else HEADER
        facing='' if self.mat.use_backface_culling else ' if (!FRONT_FACING) { NORMAL = -NORMAL; }\n'
        code=header+'\n'+'\n'.join(self.uniforms)+f'\nuniform float source_values[{len(values)}];\nvoid fragment() {{\n'+facing+fragment+'\n}\n'
        return dict(name='wap7_'+self.mat.name,code=code,textures=self.textures,glass=glass,
                    source_values=values, shader='wap7_'+hashlib.sha256(code.encode()).hexdigest()[:12]+'.gdshader')

def export_materials(materials, directory, prefix='wap7'):
    directory.mkdir(parents=True,exist_ok=True)
    output = [Compiler(m,directory).compile() for m in materials]
    for entry in output:
        entry['name'] = prefix + entry['name'][4:]
        entry['shader'] = prefix + entry['shader'][4:]
    return output
