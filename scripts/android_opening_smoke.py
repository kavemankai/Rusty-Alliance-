"""Real Android-input opening, dockside withdrawal and paid recovery compatibility checks."""
import argparse,json,time
from android_smoke import Device
p=argparse.ArgumentParser();p.add_argument('--adb',required=True);p.add_argument('--serial',default='emulator-5554');p.add_argument('--output',required=True);a=p.parse_args();d=Device(a.adb,a.serial,a.output);backups={}
def save():
 d.click('Save');return json.loads(d.call('exec-out','run-as',d.package,'cat','files/greywake.json'))
try:
 d.shell('am','force-stop',d.package)
 for name in ['greywake.json','greywake-autosave.json']:
  for suffix in ['', '.bak', '.tmp', '.bak.tmp']:
   key=name+suffix;backups[key]=d.call('shell','run-as',d.package,'ls','files/'+key,check=False)=='files/'+key
   if backups[key]:d.shell('run-as',d.package,'cp','files/'+key,'files/'+key+'.opening-qa-backup')
 d.call('shell','run-as',d.package,'rm','-f','files/mobile-qa.json',check=False)
 d.shell('am','start','-a','android.intent.action.MAIN','-c','android.intent.category.LAUNCHER','-p',d.package)
 d.wait_button('New Game');d.click('New Game');d.click('Continue briefing');d.click('Save')
 initial=json.loads(d.call('exec-out','run-as',d.package,'cat','files/greywake.json'))
 d.check(initial['opening_flow']['stage']=='EMPLOYER_BRIEFING' and initial['opening_flow']['dialogue_index']==1,'Native briefing advances and saves without asking to accept another contract')
 d.click('Enter tavern');d.click('Recruit Militia Spearman');d.click('Recruit Militia Spearman');d.click('Set Sail')
 confirmed=save();d.click('Load')
 d.check(confirmed['opening_flow']['stage']=='COMPANY_CONFIRMATION' and confirmed['funds']==2160,'Native company confirmation saves exact two-person company and fees')
 d.click('Confirm departure');d.click('Skip crossing');d.click('Step ashore');d.click('Open island map');state=d.state()['game']
 d.check(state['time']==480 and state['squad_sector']==17 and '84' in state['map']['sectors'],'Native crossing arrives on the actual island with Harth and farm positions')
 d.capture('android-opening-island')
 d.click('Deal with Dockside Trouble');d.check(d.state()['game']['phase']=='deployment','Native opening enters actual authored dockside deployment')
 d.click('Begin combat');state=d.state()['game'];actor=next(u for u in state['units'] if u['team']=='company');d.tap(*actor['screen'])
 d.check(d.state()['game']['selected']==actor['id'],'Native tactical click selects the actual recruited individual')
 d.click('Next tip');d.capture('android-opening-tutorial');d.click('Hide tutorial');combat=save();d.click('Load')
 d.check(combat['opening_flow']['tutorial_dismissed'] and combat['battle']['phase']=='combat','Dismissed tutorial and real battle survive Android save/load')
 d.check(any(t['kind']=='water' and t['block'] for t in combat['battle']['tiles']) and any(t['kind']=='crate' and t['cover']>0 for t in combat['battle']['tiles']),'Native battlefield contains authoritative water boundaries and cargo cover')
 d.click('Retreat');d.wait_button('Cancel');d.click('OK');state=d.state()['game'];withdrawn=save()
 d.check(state['phase']=='strategic' and withdrawn['opening_flow']['outcome']=='retreat' and withdrawn['sectors'][17]['owner']=='bandits','Native withdrawal returns persistent survivors to island and closes occupied port')
 d.check(not any(row['reason']=='Contract: Dockside Trouble' for row in withdrawn['ledger']),'Withdrawal grants no victory reward')
 state=d.state()['game'];d.tap(*state['map']['sectors']['84']);d.click('Travel to Harth Village');d.click('+6 hours')
 d.check(d.state()['game']['squad_sector']==84,'Native company follows actual land route to Harth')
 d.click('Contracts');d.click('Accept Harth farm-road rounds');d.click('Map');state=d.state()['game'];d.tap(*state['map']['sectors']['100']);d.click('Travel to Harth Farmland');d.click('+6 hours')
 d.check(d.state()['game']['squad_sector']==100,'Native paid recovery visits real farmland waypoint')
 state=d.state()['game'];d.tap(*state['map']['sectors']['84']);d.click('Travel to Harth Village');d.click('+6 hours');earned=save()
 work=[row for row in earned['ledger'] if row['reason']=='Contract: Harth farm-road rounds']
 d.check(len(work)==1 and work[0]['amount']==120,'Native recovery earns one actual 120-crown contract payment')
 d.check(earned['opening_flow']['outcome']=='retreat' and len(earned['squads']['first']['members'])==2,'Paid recovery preserves failed tutorial outcome and surviving identities')
 d.capture('android-opening-recovery')
except Exception as error:
 d.check(False,str(error));raise
finally:
 d.shell('am','force-stop',d.package)
 for key,existed in backups.items():
  if existed:d.shell('run-as',d.package,'mv','files/'+key+'.opening-qa-backup','files/'+key)
  else:d.call('shell','run-as',d.package,'rm','-f','files/'+key,check=False)
 report=d.finish('opening');print(json.dumps(report),flush=True)
raise SystemExit(1 if report['failed'] else 0)
