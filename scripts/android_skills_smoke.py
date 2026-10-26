"""OS-input skill/roster checks on the dedicated emulator; test roster is never shipped."""
import argparse
import json
import time
from pathlib import Path
from android_smoke import Device

p=argparse.ArgumentParser()
p.add_argument('--adb',required=True);p.add_argument('--serial',default='emulator-5554')
p.add_argument('--output',required=True);p.add_argument('--fixture',type=Path,required=True)
a=p.parse_args();d=Device(a.adb,a.serial,a.output)
backups={}
try:
 d.shell('am','force-stop',d.package)
 for name in ['greywake.json','greywake-autosave.json']:
  raw=d.call('exec-out','run-as',d.package,'cat','files/'+name,check=False)
  try: old=json.loads(raw)
  except ValueError: old={}
  fixture=json.loads(a.fixture.read_text(encoding='utf-8'))
  if old.get('recruitment',{}).get('templates')==fixture['recruitment']['templates']:
   # Only this test's own exact synthetic roster is eligible for stale-run cleanup.
   for suffix in ['', '.bak', '.tmp', '.bak.tmp']:
    d.call('shell','run-as',d.package,'rm','-f','files/'+name+suffix,check=False)
 d.call('shell','run-as',d.package,'rm','-f','files/mobile-qa.json',check=False)
 d.shell('am','start','-a','android.intent.action.MAIN','-c','android.intent.category.LAUNCHER','-p',d.package)
 d.wait_button('New campaign')
 s=d.state()
 d.check(any(b['text']=='New Greywake campaign' and not b['disabled'] for b in s['buttons']),'Approved workshop roster enables a separate production Greywake scenario')
 d.click('New campaign');d.click('Company');d.click('● Mara');d.click('Train Stealth')
 m=d.state()['game']['mercs']['mara']
 d.check(len(m['skills'])==7 and m['training_skill']=='stealth','Native touch selects Stealth and the character has seven skills')
 d.click('+1 hour');progress=d.state()['game']['mercs']['mara']['training']
 d.click('Train Fieldcraft');d.check(d.state()['game']['mercs']['mara']['training']==0,'Native skill switching keeps progress separate')
 d.click('Train Athletics');d.click('Train Stealth')
 d.check(d.state()['game']['mercs']['mara']['training']==progress,'Returning to Stealth retains its partial progress')
 d.click('Save');d.click('Load')
 d.check(d.state()['game']['mercs']['mara']['training_skill']=='stealth','Native save/load preserves selected skill')
 d.click('+6 hours');m=d.state()['game']['mercs']['mara']
 d.check(m['skills']['stealth']==41 and m['skills']['melee']==72 and m['experience']==1,'Paid time increases the selected skill without free experience or forced Melee growth')
 d.capture('android-skills-original')
 # Isolated test setup: load a normal validated save using synthetic fixture data.
 # All subsequent recruitment/training operations use actual Android input.
 d.shell('am','force-stop',d.package)
 for name in ['greywake.json','greywake-autosave.json']:
  backups[name]=d.call('shell','run-as',d.package,'ls','files/'+name,check=False)=='files/'+name
  if backups[name]:d.shell('run-as',d.package,'cp','files/'+name,'files/'+name+'.qa-backup')
 d.call('push',str(a.fixture),'/data/local/tmp/greywake-synthetic-fixture.json')
 d.shell('run-as',d.package,'cp','/data/local/tmp/greywake-synthetic-fixture.json','files/greywake.json')
 d.call('shell','run-as',d.package,'rm','-f','files/mobile-qa.json',check=False)
 d.shell('am','start','-a','android.intent.action.MAIN','-c','android.intent.category.LAUNCHER','-p',d.package)
 d.wait_button('Load Greywake campaign');d.click('Load Greywake campaign')
 d.click('Recruit Test cheap0 · 50 crowns');d.click('Recruit Test cheap0 · 50 crowns')
 state=d.state()['game'];ids=[key for key in state['mercs'] if key.startswith('greywake-recruit-')]
 d.check(state['scenario']=='greywake' and state['funds']==2300 and len(ids)==2,'Android repeatable recruitment creates and pays for two independent fighters')
 d.click('Hireling 00000001');d.click('Train Athletics');d.click('+1 hour');d.click('Save')
 saved=json.loads(d.call('exec-out','run-as',d.package,'cat','files/greywake.json'))
 owned=[item['id'] for person in saved['mercs'].values() for item in person['inventory']]
 d.check(len(owned)==len(set(owned)) and saved['recruitment']['next_id']==3,'Saved Android recruits retain unique item ownership and a persistent identity counter')
 d.check(saved['mercs'][ids[0]]['training_skill']=='athletics' and saved['mercs'][ids[1]]['training_skill']=='melee','Generated fighters keep separate skill selections')
 d.click('Load');state=d.state()['game']
 d.check(len([key for key in state['mercs'] if key.startswith('greywake-recruit-')])==2 and state['mercs'][ids[0]]['training_skill']=='athletics','Android reload preserves generated identities and individual progression')
 d.shell('input','keyevent','KEYCODE_HOME');time.sleep(2);d.shell('am','force-stop',d.package)
 d.call('shell','run-as',d.package,'rm','-f','files/mobile-qa.json',check=False)
 d.shell('am','start','-a','android.intent.action.MAIN','-c','android.intent.category.LAUNCHER','-p',d.package)
 d.wait_button('Continue Greywake autosave');d.click('Continue Greywake autosave');state=d.state()['game']
 d.check(state['scenario']=='greywake' and state['mercs'][ids[0]]['training_skill']=='athletics','Greywake has its own native pause/force-stop autosave continuation')
 d.capture('android-skills-synthetic-greywake')
except Exception as error:
 d.check(False,str(error));raise
finally:
 try:d.shell('am','force-stop',d.package)
 except Exception as cleanup_error:d.check(False,'Emulator cleanup: '+str(cleanup_error))
 for name,existed in backups.items():
  try:
   if existed:d.shell('run-as',d.package,'mv','files/'+name+'.qa-backup','files/'+name)
   else:d.call('shell','run-as',d.package,'rm','-f','files/'+name,check=False)
  except Exception as cleanup_error:d.check(False,'Emulator save restoration: '+str(cleanup_error))
 try:report=d.finish('skills')
 except Exception as report_error:
  d.check(False,'Emulator report: '+str(report_error))
  report={'scenario':'skills','passed':sum(c['passed'] for c in d.checks),'failed':sum(not c['passed'] for c in d.checks),'checks':d.checks,'limits':['Emulator connection failed; this run is not accepted.']}
 report['greywake_roster']='Legacy infrastructure test uses an isolated synthetic fixture; production roster is tested separately.'
 (Path(a.output)/'skills-results.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
 print(json.dumps(report),flush=True)
raise SystemExit(1 if report['failed'] else 0)
