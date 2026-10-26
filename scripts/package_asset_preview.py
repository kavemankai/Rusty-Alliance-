"""Package the verified asset-preview PC folder and debug APK without overwriting older releases."""
import hashlib
import json
import zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT.parent
folder=OUT/'broken-marches-0.12.0-windows'
for name in ['ASSET_COVERAGE.md','ASSET_QA.md']:
 (folder/name).write_bytes((ROOT/name).read_bytes())
(folder/'START HERE.txt').write_text('The Broken Marches - 0.12.0 asset preview\n\nOpen The Broken Marches.exe. Keep the adjacent .pck file with it.\nUse New campaign, or load your existing save. Company and Inventory show the new thumbnails; tactical fields use imported models.\nDrag to pan, use the wheel or +/- buttons to zoom, and scout to reveal unexplored terrain.\nASSET_COVERAGE.md lists the art that is supplied and the work still needed. This preview is not the complete game.\n',encoding='utf-8')
artifacts=[]
windows=OUT/'broken-marches-0.12.0-windows.zip'
with zipfile.ZipFile(windows,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
 for path in sorted(folder.iterdir()):
  if path.is_file():archive.write(path,path.name)
artifacts.append(windows)
apk=OUT/'broken-marches-0.12.0-debug.apk'
apk.write_bytes((ROOT/'builds'/apk.name).read_bytes())
artifacts.append(apk)
apk_zip=OUT/'broken-marches-0.12.0-apk.zip'
with zipfile.ZipFile(apk_zip,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as archive:archive.write(apk,apk.name)
artifacts.append(apk_zip)
records=[{'name':p.name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in artifacts]
(OUT/'release-assets-0.12.0.json').write_text(json.dumps({'version':'0.12.0-quaternius-assets','artifacts':records,'source_models':735,'runtime_models':32,'runtime_mappings':35,'rendered_icons':63,'limits':['Art integration is partial; see ASSET_COVERAGE.md.','Android art-build device/emulator acceptance is not yet repeated.']},indent=2)+'\n',encoding='utf-8')
(OUT/'SHA256SUMS-assets-0.12.0.txt').write_text(''.join(r['sha256']+'  '+r['name']+'\n' for r in records),encoding='utf-8')
print(json.dumps(records,indent=2))
