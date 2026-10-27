"""Package the desktop-only scene preview after accepted source and isolated-pack checks."""
from pathlib import Path
import json,hashlib,zipfile,shutil
root=Path(__file__).resolve().parents[1];folder=root.parent/'broken-marches-0.15.2-windows'
r=json.loads((root/'scene-art-results.json').read_text())
if r['failed'] or r['source_passed']!=849 or r['png_integrity']['passed']!=66:raise RuntimeError('UI art acceptance incomplete')
for name in ['GREYWAKE_SCENE_ART_STATUS.md','THIRD_PARTY_NOTICES.txt','scene-art-results.json']:shutil.copy2(root/name,folder/name)
shutil.copy2(root/'assets/greywake/PROVENANCE.txt',folder/'GREYWAKE_ART_PROVENANCE.txt')
(folder/'START HERE.txt').write_text('The Broken Marches 0.15.2 - scene art preview\n\nRun The Broken Marches.exe with its .pck beside it. New Game opens Greywake; New campaign preserves the original campaign.\nSeven supplied scene plates and eight UI textures are used. Portraits and the painted map/combat image remain references. This is provisional art, not the complete Greywake game. See GREYWAKE_SCENE_ART_STATUS.md.\n')
for image in root.glob('scene-art-*-preview.png'):shutil.copy2(image,folder/image.name)
archive=root.parent/'broken-marches-0.15.2-windows.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
 for p in sorted(folder.iterdir()):
  if p.is_file():z.write(p,p.name)
with zipfile.ZipFile(archive) as z:
 if z.testzip():raise RuntimeError('ZIP CRC failed')
result={'artifact':archive.name,'bytes':archive.stat().st_size,'sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'windows_pack_sha256':hashlib.sha256((folder/'The Broken Marches.pck').read_bytes()).hexdigest(),'android_art_acceptance':False,'results':r}
(root.parent/'release-scene-art-0.15.2.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({k:v for k,v in result.items() if k!='results'},indent=2))
