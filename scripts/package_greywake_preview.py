"""Package the verified 0.14 Greywake staging preview without overwriting 0.13 artifacts."""
import argparse,hashlib,json,zipfile
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--evidence',type=Path,required=True);a=p.parse_args()
root=Path(__file__).resolve().parents[1];out=root.parent
version='0.14.0-greywake-recruitment';folder=out/'broken-marches-0.14.0-windows'
digest=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
reports=[]
for name in ['basic','gestures','tactical','lifecycle','cutout','skills','greywake']:
 report=json.loads((a.evidence/(name+'-results.json')).read_text(encoding='utf-8-sig'))
 if report['failed'] or report['passed']<1:raise RuntimeError('Native scenario not accepted: '+name)
 reports.append(report)
source=[]
for name in ['test-results.json','extended-results.json','skills-test-results.json','asset-test-results.json','greywake-test-results.json','greywake-ui-results.json','ui-test-results.json','skills-ui-results.json']:
 report=json.loads((root/name).read_text(encoding='utf-8-sig'))
 if report['failed']:raise RuntimeError('Source suite not accepted: '+name)
 source.append({'report':name,'passed':report.get('passed'),'failed':report['failed']})
apk=root/'builds/broken-marches-0.14.0-greywake-debug.apk'
with zipfile.ZipFile(apk) as z:
 if z.testzip() is not None:raise RuntimeError('APK CRC failure')
 files=z.namelist()
 roster=json.loads(z.read('assets/data/greywake_roster.json'))
 scenario=json.loads(z.read('assets/data/greywake_scenario.json'))
 if len(roster['templates'])!=12 or scenario['id']!='fall_of_greywake':raise RuntimeError('Packaged scenario data missing')
 if any('/tests/' in name or '/scripts/' in name or name.endswith(('.keystore','.md')) for name in files):raise RuntimeError('Development material in player APK')
summary={'version':version,'apk_sha256':digest(apk),'passed':sum(r['passed'] for r in reports),'failed':sum(r['failed'] for r in reports),'scenarios':reports,'source_suites':source,'finalized_workshop_roster_supplied':True,'acceptance':'Roster/opening/shipping staging preview; full island and economic recovery acceptance remain open.','limits':['Dock Town staging UI uses existing internal sector backing; completed 10x10 island/map marker is upstream.','No authored Greywake paid work/travel recovery loop yet; existing economy is unchanged.','Emulator tests do not establish physical-phone acceptance, thermals or battery.'],'verification_retry':'One earlier final-candidate basic run read stale observer output during startup; prepare_android_qa.ps1 now clears telemetry before launch. Only complete passing final runs are aggregated.'}
(root/'greywake-android-results.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf8')
for name in ['GREYWAKE_RECRUITMENT_STATUS.md','GREYWAKE_RECRUITMENT_SHIPPING_SPEC.md','THIRD_PARTY_NOTICES.txt']:(folder/name).write_bytes((root/name).read_bytes())
(folder/'START HERE.txt').write_text('The Broken Marches - Greywake recruitment preview 0.14.0\n\nOpen The Broken Marches.exe with its .pck beside it.\nNew campaign preserves the original world. New Greywake campaign opens the mainland tavern: hire two to six paid mercenaries, then depart for Dock Town.\nThe Recruitment harbour shows the fixed Day 4/8/12 ship calendar and persistent offers.\nGreywake is currently a port staging preview: the authored island, paid-work recovery economy and endings are unfinished. Read GREYWAKE_RECRUITMENT_STATUS.md for exact scope and tests.\n',encoding='utf8')
artifacts=[]
pc=out/'broken-marches-0.14.0-windows.zip'
with zipfile.ZipFile(pc,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
 for path in sorted(folder.iterdir()):
  if path.is_file():z.write(path,path.name)
artifacts.append(pc)
copy=out/apk.name;copy.write_bytes(apk.read_bytes());artifacts.append(copy)
apkzip=out/'broken-marches-0.14.0-greywake-apk.zip'
with zipfile.ZipFile(apkzip,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:z.write(copy,copy.name)
artifacts.append(apkzip)
for archive in [pc,apkzip]:
 with zipfile.ZipFile(archive) as z:
  if z.testzip() is not None:raise RuntimeError('Release ZIP CRC failed')
records=[{'name':path.name,'bytes':path.stat().st_size,'sha256':digest(path)} for path in artifacts]
(out/'release-greywake-0.14.0.json').write_text(json.dumps({'version':version,'artifacts':records,'production_greywake_complete':False,'roster_opening_shipping_implemented':True,'android_checks':summary['passed'],'android_failed':summary['failed'],'source_suites':source,'limits':summary['limits']},indent=2)+'\n',encoding='utf8')
(out/'SHA256SUMS-greywake-0.14.0.txt').write_text(''.join(r['sha256']+'  '+r['name']+'\n' for r in records),encoding='utf8')
print(json.dumps({'artifacts':records,'android_passed':summary['passed'],'failed':summary['failed']},indent=2))
