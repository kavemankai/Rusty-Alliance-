"""Verify imported source integrity and inventory the available animation clips."""
import hashlib
import json
import struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
manifest=json.loads((ROOT/'assets/quaternius/manifest.json').read_text(encoding='utf-8'))
failures=[]
animations={}
for row in manifest['models']:
 path=ROOT/row['path'].removeprefix('res://')
 data=path.read_bytes()
 if hashlib.sha256(data).hexdigest()!=row['sha256']:failures.append('Source changed: '+row['path'])
 if path.suffix=='.glb':
  length,kind=struct.unpack_from('<II',data,12)
  doc=json.loads(data[20:20+length])
  animations[row['path']]=[a.get('name','') for a in doc.get('animations',[])]
 elif row['animations']:animations[row['path']]=row['animations']
notices=list((ROOT/'assets/quaternius').rglob('*LICENSE*.txt'))
for path in notices:
 if 'CC0' not in path.read_text(errors='replace'):failures.append('Unidentified licence: '+str(path))
icons=list((ROOT/'assets/ui/icons').glob('*.png'))
for path in icons:
 data=path.read_bytes()
 if data[:8]!=b'\x89PNG\r\n\x1a\n' or struct.unpack_from('>II',data,16)!=(192,192):failures.append('Invalid thumbnail: '+str(path))
report={'source_models':len(manifest['models']),'verified_model_hashes':len(manifest['models'])-len([f for f in failures if f.startswith('Source changed:')]),'cc0_notices':len(notices),'rendered_icons':len(icons),'animation_sources':animations,'failed':len(failures),'failures':failures,'limits':['Imported clips are available sources, not proof of retargeting or gameplay animation coverage.','Source model hashes do not validate artistic suitability or fitted equipment.']}
(ROOT/'asset-source-results.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('ASSET_SOURCE_AUDIT: %d model hashes, %d CC0 notices, %d icons, %d failed'%(report['verified_model_hashes'],len(notices),len(icons),len(failures)))
raise SystemExit(1 if failures else 0)
