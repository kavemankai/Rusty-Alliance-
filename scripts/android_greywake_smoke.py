"""Native Android controls for the approved Greywake opening and persistent vessel offers."""
import argparse,json,time
from pathlib import Path
from android_smoke import Device
p=argparse.ArgumentParser();p.add_argument('--adb',required=True);p.add_argument('--serial',default='emulator-5554');p.add_argument('--output',required=True);p.add_argument('--fixtures',type=Path,required=True)
a=p.parse_args();d=Device(a.adb,a.serial,a.output);backups={}
def launch():
 d.shell('am','force-stop',d.package)
 d.call('shell','run-as',d.package,'rm','-f','files/mobile-qa.json',check=False)
 d.shell('am','start','-a','android.intent.action.MAIN','-c','android.intent.category.LAUNCHER','-p',d.package)
 d.wait_button('New Greywake campaign')
def saved():return json.loads(d.call('exec-out','run-as',d.package,'cat','files/greywake.json'))
def load_fixture(name):
 d.shell('am','force-stop',d.package)
 d.call('push',str(a.fixtures/('greywake-'+name+'-android-fixture.json')),'/data/local/tmp/greywake-production-fixture.json')
 d.shell('run-as',d.package,'cp','/data/local/tmp/greywake-production-fixture.json','files/greywake.json')
 launch();d.click('Load Greywake campaign');d.click('Dock Town')
try:
 d.shell('am','force-stop',d.package)
 for name in ['greywake.json','greywake-autosave.json']:
  for suffix in ['', '.bak', '.tmp', '.bak.tmp']:
   key=name+suffix
   backups[key]=d.call('shell','run-as',d.package,'ls','files/'+key,check=False)=='files/'+key
   if backups[key]:d.shell('run-as',d.package,'cp','files/'+key,'files/'+key+'.shipping-qa-backup')
 launch();d.click('New Greywake campaign')
 s=d.state()
 d.check(s['game']['scenario']=='fall_of_greywake' and s['game']['funds']==2400,'Native production opening uses separate scenario and exact purse')
 d.check(any(b['text']=='Depart for Dock Town' and b['disabled'] for b in s['buttons']),'Empty opening party cannot depart')
 d.check(all(any(b['text']=='Hire '+name and b['disabled'] for b in s['buttons']) for name in ['Roderic','Ysra']),'Both Elite hires are visible and unaffordable')
 d.click('Hire Militia Spearman');s=d.state()
 d.check(any(b['text']=='Depart for Dock Town' and b['disabled'] for b in s['buttons']),'One recruit still cannot depart')
 d.click('Hire Militia Spearman');d.click('Hire Mara');d.click('Save selection');before=saved()
 d.check(before['funds']==1810 and len(before['squads']['first']['members'])==3,'Native opening charges every exact fee')
 d.check(len({item['id'] for m in before['mercs'].values() for item in m['inventory']})==sum(len(m['inventory']) for m in before['mercs'].values()),'Opening recruits have unique actual owned equipment')
 d.click('Hire Oswin');d.click('Load selection')
 d.check(d.state()['game']['funds']==1810,'Opening selection load restores funds without duplicate hires')
 d.shell('input','keyevent','KEYCODE_HOME');time.sleep(2);launch();d.click('Continue Greywake autosave')
 d.check(any(b['text']=='Depart for Dock Town' for b in d.state()['buttons']),'Android lifecycle resumes the saved pre-voyage phase')
 d.capture('android-greywake-opening');d.click('Depart for Dock Town');d.click('Dock Town');d.click('Save');landed=saved()
 d.check(landed['opening_voyage']['phase']=='arrived' and landed['squads']['first']['sector']==landed['greywake']['dock_sector'] and landed['funds']==1810,'Paid chosen company arrives together at authored Dock Town')
 d.click('Company');d.check(not any(b['text'].startswith('Recruit ') or b['text'].startswith('Hire ·') for b in d.state()['buttons']),'Post-departure UI exposes no unrestricted recruitment shortcut')
 load_fixture('docked');d.click('Save');before=saved();v=before['shipping']['vessels'][0];offer=v['offers'][0]
 d.check(v['status']=='docked' and v['arrival_at']==4680,'Native harbour displays Day 4 06:00 docked vessel')
 d.click('Hire passenger '+offer['name']);d.click('Save');after=saved();hired=after['shipping']['vessels'][0]['offers'][0]
 d.check(after['funds']==before['funds']-offer['fee'] and hired['status']=='hired' and hired['person_id']==offer['candidate_id'],'Native vessel purchase charges once and binds reserved identity')
 d.click('Load');d.click('Save');reloaded=saved()
 d.check(reloaded['shipping']==after['shipping'] and reloaded['mercs']==after['mercs'],'Android save/load retains identical manifest and character inventories')
 d.click('Pause');paused=d.state()['game']['time'];time.sleep(2)
 d.check(d.state()['game']['time']==paused,'Paused Android UI does not consume the recruitment window')
 d.capture('android-greywake-harbour')
 load_fixture('offshore');d.click('Save');blocked=saved();v=blocked['shipping']['vessels'][0]
 d.check(v['status']=='offshore' and not any(b['text'].startswith('Hire passenger') for b in d.state()['buttons']),'Blockaded ship hides passenger offers and prevents native hiring')
 for _ in range(4):d.click('+6 hours')
 d.click('Save');lost=saved()
 d.check(lost['shipping']['vessels'][0]['status']=='turned_back' and lost['shipping']['next_arrival_at']==10440,'Native clock expires offshore vessel exactly at 24 hours without shifting Day 8')
 d.capture('android-greywake-offshore')
except Exception as error:
 d.check(False,str(error));raise
finally:
 d.shell('am','force-stop',d.package)
 for key,existed in backups.items():
  if existed:d.shell('run-as',d.package,'mv','files/'+key+'.shipping-qa-backup','files/'+key)
  else:d.call('shell','run-as',d.package,'rm','-f','files/'+key,check=False)
 report=d.finish('greywake');print(json.dumps(report),flush=True)
raise SystemExit(1 if report['failed'] else 0)
