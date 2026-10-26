"""Import only game-relevant CC0 models from the user-supplied archive.

No executable or setup scripts from the archive are run. Original paths,
licences and SHA256s are recorded; glTF dependencies stay beside each model.
"""
import argparse
import hashlib
import json
import posixpath
import re
import zipfile
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parents[1]
PACKS = {
    'props': ('Medieval/Fantasy Props MegaKit', '.gltf'),
    'village': ('Medieval/Medieval Village MegaKit', '.gltf'),
    'nature': ('Nature/Ultimate Stylized Nature', '.gltf'),
    'rts': ('Game Kits/Ultimate Fantasy RTS', '.gltf'),
    'weapons': ('Medieval/Medieval Weapons Pack', '.obj'),
    'items': ('Medieval/Ultimate RPG Items Pack', '.obj'),
    'crops': ('Nature/Nature Crops Pack', '.obj'),
    'outfits': ('Characters and Animals/Modular Character Outfits', '.gltf'),
    'people': ('Characters and Animals/Universal Base Characters', '.gltf'),
    'characters': ('Characters and Animals/RPG Characters', '.gltf'),
    'animals': ('Characters and Animals/Ultimate Animated Animals', '.gltf'),
    'camp': ('Miscellaneous/Survival Pack', '.obj'),
    'animations1': ('Animation/Universal Animation Library 1', '.glb'),
    'animations2': ('Animation/Universal Animation Library 2', '.glb'),
    'helmets': ('Characters and Animals/Knight Character Animated', '.obj'),
}

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('archive')
    args = parser.parse_args()
    base = ROOT / 'assets' / 'quaternius'
    base.mkdir(parents=True, exist_ok=True)
    records = []
    repairs = []
    with zipfile.ZipFile(args.archive) as archive:
        names = set(archive.namelist())
        def copy(source, dest):
            if source not in names:
                corrected = source.replace('_png.png', '.png')
                if corrected not in names:
                    raise ValueError('Missing dependency: ' + source)
                repairs.append({'requested':source,'supplied':corrected})
                source = corrected
            if not dest.resolve().is_relative_to(base.resolve()):
                raise ValueError('Unsafe archive path: ' + source)
            dest.parent.mkdir(parents=True, exist_ok=True)
            data = archive.read(source)
            dest.write_bytes(data)
            return data
        copy('License.txt', base / 'LICENSE.txt')
        for category, (prefix, extension) in PACKS.items():
            candidates = sorted(n for n in names if n.startswith(prefix) and n.endswith(extension))
            if category == 'animals':
                candidates = [n for n in candidates if PurePosixPath(n).stem in ['Horse','Donkey','Cow','Bull','Deer','Wolf']]
            if category.startswith('animations'):
                candidates = [n for n in candidates if '/Unreal-Godot/' in n and '_RM.' not in n]
            if category == 'camp':
                candidates = [n for n in candidates if any(s in PurePosixPath(n).stem.lower() for s in ['tent','camp','bonfire','bandages','bag','bed','log','rope','torch','backpack'])]
            if category == 'helmets':
                candidates = [n for n in candidates if PurePosixPath(n).stem.startswith('Helmet')]
            for source in candidates:
                pack = '/'.join(source.split('/')[:2])
                relative = source[len(pack)+1:]
                dest = base / category / relative
                data = copy(source, dest)
                animations = []
                if extension == '.gltf':
                    doc = json.loads(data)
                    animations = [a.get('name', '') for a in doc.get('animations', [])]
                    for obj in doc.get('buffers', []) + doc.get('images', []):
                        uri = obj.get('uri', '')
                        if uri and not uri.startswith('data:'):
                            from urllib.parse import unquote
                            uri = unquote(uri)
                            copy(posixpath.normpath(posixpath.join(posixpath.dirname(source),uri)), dest.parent / uri)
                elif extension == '.obj':
                    for material in re.findall(r'^mtllib (.+)$', data.decode('utf-8', errors='replace'), re.M):
                        material = material.strip()
                        mtl_source = posixpath.join(posixpath.dirname(source),material)
                        mtl = copy(mtl_source, dest.parent / material)
                        for texture in re.findall(r'^map_\w+ (.+)$', mtl.decode('utf-8', errors='replace'), re.M):
                            texture = texture.strip()
                            copy(posixpath.normpath(posixpath.join(posixpath.dirname(mtl_source),texture)),dest.parent / texture)
                licences = sorted(n for n in names if n.startswith(pack+'/') and PurePosixPath(n).name.lower()=='license.txt')
                for i, licence in enumerate(licences):
                    copy(licence, base/category/('LICENSE'+str(i)+'.txt'))
                records.append({'category':category,'name':PurePosixPath(source).stem,'path':'res://'+dest.relative_to(ROOT).as_posix(),'source':source,'sha256':hashlib.sha256(data).hexdigest(),'animations':animations})
    (base/'manifest.json').write_text(json.dumps({'archive':Path(args.archive).name,'licence':'CC0-1.0; included root and pack notices preserved','dependency_repairs':repairs,'models':records},indent=2)+'\n',encoding='utf-8')
    from collections import Counter
    print(json.dumps({'models':len(records),'by_category':dict(Counter(r['category'] for r in records)),'bytes':sum(p.stat().st_size for p in base.rglob('*') if p.is_file())},indent=2))

if __name__ == '__main__':
    main()
