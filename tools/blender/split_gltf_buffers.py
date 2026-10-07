"""Losslessly externalize large GLB buffer views into Git-sized dependencies.

glTF permits a GLB JSON chunk with URI-backed buffers. No mesh, normals, UVs,
indices or source image pixels change. Every buffer view remains byte-identical.
"""
import hashlib
import json
import struct
from pathlib import Path

def split_glb(source, destination, limit=48*1024*1024):
    data=Path(source).read_bytes()
    magic,version,length=struct.unpack_from('<III',data)
    assert magic==0x46546c67 and version==2 and length==len(data)
    json_len,json_kind=struct.unpack_from('<II',data,12)
    assert json_kind==0x4e4f534a
    doc=json.loads(data[20:20+json_len])
    start=20+json_len
    bin_len,bin_kind=struct.unpack_from('<II',data,start)
    assert bin_kind==0x004e4942
    binary=data[start+8:start+8+bin_len]
    buffers=[bytearray()]
    for view in doc['bufferViews']:
        assert view['buffer']==0
        chunk=binary[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']]
        assert len(chunk)<=limit, 'Single view too large to split without reindexing'
        if len(buffers[-1])+len(chunk)>limit: buffers.append(bytearray())
        part=buffers[-1]
        part.extend(b'\0'*(-len(part)%4))
        view['buffer']=len(buffers)-1
        view['byteOffset']=len(part)
        part.extend(chunk)
    dependencies=[]
    for i,part in enumerate(buffers):
        path=Path(destination).parent/(Path(destination).stem+'_detail')/f'geometry_{i}.bin'
        path.parent.mkdir(parents=True,exist_ok=True)
        path.write_bytes(part)
        dependencies.append(dict(uri=path.relative_to(Path(destination).parent).as_posix(),byteLength=len(part),sha256=hashlib.sha256(part).hexdigest()))
    doc['buffers']=[{k:d[k] for k in ('uri','byteLength')} for d in dependencies]
    encoded=json.dumps(doc,separators=(',',':')).encode()
    encoded+=b' '*(-len(encoded)%4)
    result=struct.pack('<III',magic,2,20+len(encoded))+struct.pack('<II',len(encoded),json_kind)+encoded
    Path(destination).write_bytes(result)
    return dependencies
