"""Package the bounded 0.13 preview; never present synthetic roster data as finalized."""
import hashlib
import json
import zipfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT.parent
version='0.13.0-skills-preview'
folder=OUT/'broken-marches-0.13.0-skills-windows'
reports=[]
for name in ['basic','gestures','tactical','lifecycle','cutout','skills']:
 report=json.loads((OUT/'greywake-android-qa-0.13.0'/(name+'-results.json')).read_text(encoding='utf-8'))
 if report['failed']:raise RuntimeError('Unaccepted Android scenario: '+name)
 reports.append(report)
for name in ['test-results.json','extended-results.json','skills-test-results.json','ui-test-results.json','skills-ui-results.json','asset-test-results.json']:
 if json.loads((ROOT/name).read_text(encoding='utf-8'))['failed']:raise RuntimeError('Unaccepted source suite: '+name)
source_apk=ROOT/'builds/broken-marches-0.13.0-skills-debug.apk'
digest=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
summary={'version':version,'apk_sha256':digest(source_apk),'passed':sum(r['passed'] for r in reports),'failed':sum(r['failed'] for r in reports),'scenarios':reports,'finalized_workshop_roster_supplied':False,'acceptance':'Shared mechanics verified; full Greywake remains blocked on the finalized workshop roster.','limits':['Synthetic recruitment fixture is test-only and excluded from player packages.','Emulator controls are not physical-phone or performance/thermal acceptance.']}
(ROOT/'greywake-android-results.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
for name in ['GREYWAKE_SKILLS.md','GREYWAKE_QA.md','THIRD_PARTY_NOTICES.txt']:
 (folder/name).write_bytes((ROOT/name).read_bytes())
(folder/'START HERE.txt').write_text('The Broken Marches - Seven-skill preview 0.13.0\n\nOpen The Broken Marches.exe. Keep its .pck beside it.\nThe original campaign is playable. Company shows seven skills and Train <skill> controls.\nThe finalized twelve-template workshop roster has not been supplied. New Greywake creation stays disabled; no invented production roster is included.\nGREYWAKE_SKILLS.md describes implemented mechanics and the remaining input. GREYWAKE_QA.md records verification and limits.\n',encoding='utf-8')
artifacts=[]
pc=OUT/'broken-marches-0.13.0-skills-windows.zip'
with zipfile.ZipFile(pc,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
 for path in sorted(folder.iterdir()):
  if path.is_file():archive.write(path,path.name)
artifacts.append(pc)
apk=OUT/source_apk.name;apk.write_bytes(source_apk.read_bytes());artifacts.append(apk)
apk_zip=OUT/'broken-marches-0.13.0-skills-apk.zip'
with zipfile.ZipFile(apk_zip,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as archive:archive.write(apk,apk.name)
artifacts.append(apk_zip)
records=[{'name':p.name,'bytes':p.stat().st_size,'sha256':digest(p)} for p in artifacts]
(OUT/'release-skills-0.13.0.json').write_text(json.dumps({'version':version,'artifacts':records,'production_greywake_complete':False,'missing_input':'Finalized twelve-template workshop roster','android_checks':summary['passed'],'android_failed':summary['failed']},indent=2)+'\n',encoding='utf-8')
(OUT/'SHA256SUMS-skills-0.13.0.txt').write_text(''.join(r['sha256']+'  '+r['name']+'\n' for r in records),encoding='utf-8')
print(json.dumps(records,indent=2))
