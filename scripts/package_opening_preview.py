"""Package the verified 0.15 Greywake opening without overwriting earlier artifacts."""
import argparse,hashlib,json,zipfile,subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--evidence',type=Path,required=True);a=p.parse_args()
root=Path(__file__).resolve().parents[1];out=root.parent
version='0.15.0-greywake-opening';folder=out/'broken-marches-0.15.0-windows'
digest=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
source_commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
reports=[]
for name in ['basic','gestures','tactical','lifecycle','cutout','skills','greywake','opening']:
 report=json.loads((a.evidence/(name+'-results.json')).read_text(encoding='utf-8-sig'))
 if report['failed'] or report['passed']<1:raise RuntimeError('Native scenario not accepted: '+name)
 reports.append(report)
source=[]
for name in ['test-results.json','extended-results.json','skills-test-results.json','asset-test-results.json','greywake-test-results.json','greywake-ui-results.json','ui-test-results.json','skills-ui-results.json','opening-flow-results.json','island-test-results.json','dockside-test-results.json','opening-ui-results.json']:
 report=json.loads((root/name).read_text(encoding='utf-8-sig'))
 if report['failed']:raise RuntimeError('Source suite not accepted: '+name)
 source.append({'report':name,'passed':report.get('passed'),'failed':report['failed']})
apk=root/'builds/broken-marches-0.15.0-opening-debug.apk'
with zipfile.ZipFile(apk) as z:
 if z.testzip() is not None:raise RuntimeError('APK CRC failure')
 files=z.namelist()
 roster=json.loads(z.read('assets/data/greywake_roster.json'))
 scenario=json.loads(z.read('assets/data/greywake_scenario.json'))
 for data in ['greywake_opening','greywake_island','greywake_dockside']: json.loads(z.read('assets/data/'+data+'.json'))
 if len(roster['templates'])!=12 or scenario['id']!='fall_of_greywake':raise RuntimeError('Packaged scenario data missing')
 if any('/tests/' in name or '/scripts/' in name or name.endswith(('.keystore','.md')) for name in files):raise RuntimeError('Development material in player APK')
summary={'version':version,'source_commit':source_commit,'apk_sha256':digest(apk),'passed':sum(r['passed'] for r in reports),'failed':sum(r['failed'] for r in reports),'scenarios':reports,'source_suites':source,'finalized_workshop_roster_supplied':True,'acceptance':'Playable opening, authored island, Dockside Trouble and bounded paid recovery; full campaign content remains open.','limits':['Opening art and role portraits are temporary; production archive and audio are missing.','Fortress content, political consequences and three endings remain unfinished.','Emulator tests do not establish physical-phone acceptance, thermals or battery.'],'verification_retry':'One earlier final-candidate basic run read stale observer output during startup; prepare_android_qa.ps1 clears telemetry before launch and android_smoke.py waits for a fresh post-input frame. Only complete passing final runs are aggregated.'}
(root/'opening-android-results.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf8')
for name in ['GREYWAKE_OPENING_STATUS.md','GREYWAKE_OPENING_EXPERIENCE_SPEC.md','GREYWAKE_RECRUITMENT_SHIPPING_SPEC.md','THIRD_PARTY_NOTICES.txt']:(folder/name).write_bytes((root/name).read_bytes())
(folder/'START HERE.txt').write_text('The Broken Marches - Greywake opening 0.15.0\n\nOpen The Broken Marches.exe with its .pck beside it.\nNew Game opens Greywake: employer briefing, paid tavern company (two to six), crossing, island and Dockside Trouble. New campaign preserves the original world.\nRead GREYWAKE_OPENING_STATUS.md for controls, exact scope, tests and unfinished content. Art is temporary; this is not the full island campaign.\n',encoding='utf8')
artifacts=[]
pc=out/'broken-marches-0.15.0-windows.zip'
with zipfile.ZipFile(pc,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
 for path in sorted(folder.iterdir()):
  if path.is_file():z.write(path,path.name)
artifacts.append(pc)
copy=out/apk.name;copy.write_bytes(apk.read_bytes());artifacts.append(copy)
apkzip=out/'broken-marches-0.15.0-greywake-apk.zip'
with zipfile.ZipFile(apkzip,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:z.write(copy,copy.name)
artifacts.append(apkzip)
for archive in [pc,apkzip]:
 with zipfile.ZipFile(archive) as z:
  if z.testzip() is not None:raise RuntimeError('Release ZIP CRC failed')
records=[{'name':path.name,'bytes':path.stat().st_size,'sha256':digest(path)} for path in artifacts]
(out/'release-greywake-0.15.0.json').write_text(json.dumps({'version':version,'source_commit':source_commit,'artifacts':records,'production_greywake_complete':False,'opening_island_dockside_implemented':True,'android_checks':summary['passed'],'android_failed':summary['failed'],'source_suites':source,'limits':summary['limits']},indent=2)+'\n',encoding='utf8')
(out/'SHA256SUMS-greywake-0.15.0.txt').write_text(''.join(r['sha256']+'  '+r['name']+'\n' for r in records),encoding='utf8')
print(json.dumps({'artifacts':records,'android_passed':summary['passed'],'failed':summary['failed']},indent=2))
