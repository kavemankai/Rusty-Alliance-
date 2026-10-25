"""Continue the basic Android scenario through real tactical UI actions."""
import argparse,json,time,pathlib
from android_smoke import Device
p=argparse.ArgumentParser();p.add_argument('--adb',required=True);p.add_argument('--serial',default='emulator-5554');p.add_argument('--output',required=True);p.add_argument('--resume',action='store_true');a=p.parse_args();d=Device(a.adb,a.serial,a.output)
def current(): return d.settled()['game']
def unit(state,id): return next(u for u in state['units'] if u['id']==id)
def wait_game(predicate):
 for retry in range(15):
  state=d.state()
  if state['game'] and predicate(state['game']): return state['game']
  d.fresh(state['ticks'])
 raise RuntimeError('Expected Android gameplay state did not arrive')
def saved():
 d.click('Save');return json.loads(d.call('exec-out','run-as',d.package,'cat','files/campaign.json'))
try:
 if a.resume:
  prior=json.loads((pathlib.Path(a.output)/'tactical-results.json').read_text())
  d.checks=prior['checks'][:4]
  state=current();moved=unit(state,'mara')
  if len(d.checks)!=4 or not all(c['passed'] for c in d.checks) or state['phase']!='combat' or (moved['x'],moved['y'],moved['ap'])!=(2,4,16): raise RuntimeError('Resume checkpoint does not match the four already verified actions')
 else:
  if current()['phase']=='strategic': d.click('Deploy company')
  state=wait_game(lambda s:s['phase']=='deployment')
  d.check(state['phase']=='deployment','Actual strategic contact opens Android deployment')
  d.tap(*unit(state,'oswin')['screen']);state=wait_game(lambda s:s['selected']=='oswin')
  d.check(state['selected']=='oswin','Native Android tactical tap selects intended fighter')
  d.tap(*unit(state,'mara')['screen']);wait_game(lambda s:s['selected']=='mara')
  d.click('Begin combat');state=wait_game(lambda s:s['phase']=='combat')
  d.check(state['round']==1,'Android deployment confirmation starts real combat')
  actor=unit(state,'mara');other=unit(state,'oswin')
  destination=[(actor['screen'][i]+other['screen'][i])/2 for i in [0,1]]
  d.tap(*destination);d.click('Confirm movement');after=current();moved=unit(after,'mara')
  print('Movement status: '+after['message'],flush=True)
  d.check((moved['x'],moved['y'])==(2,4) and moved['ap']==actor['ap']-2,'Touch route confirmation executes the expected two-AP step')
 before=moved['ap'];d.click('Defence brace');data=saved();actor=next(u for u in data['battle']['units'] if u['id']=='mara')
 d.check(actor['defence_mode']=='brace' and actor['ap']==before-2,'Android brace spends two AP and changes defence mode')
 d.click('Guard / disengagement reaction');data=saved();actor=next(u for u in data['battle']['units'] if u['id']=='mara')
 d.check(actor['guard'],'Android guard control reserves real reaction state')
 state=current();d.tap(*unit(state,'oswin')['screen']);state=wait_game(lambda s:s['selected']=='oswin')
 enemies=[u for u in state['units'] if u['team']=='enemy' and u['hp']>10]
 d.check(bool(enemies),'Android visibility exposes real opponents for targeting')
 if enemies:
  old=saved();ammo=sum(i['quantity'] for i in old['mercs']['oswin']['inventory'] if i['kind']=='ammo');before=unit(current(),'oswin')['ap']
  d.tap(*enemies[0]['screen']);d.click('Confirm attack');data=saved();new_ammo=sum(i['quantity'] for i in data['mercs']['oswin']['inventory'] if i['kind']=='ammo')
  actor=next(u for u in data['battle']['units'] if u['id']=='oswin')
  d.check(actor['ap']==before-5 and new_ammo==ammo-1 and not data['mercs']['oswin']['loaded'],'Android ranged attack spends five AP and one owned arrow')
  before=actor['ap'];d.click('Reload');print('Reload status: '+current()['message'],flush=True);data=saved();actor=next(u for u in data['battle']['units'] if u['id']=='oswin')
  d.check(data['mercs']['oswin']['loaded'] and actor['ap']==before-2,'Android reload loads the bow and spends two AP')
 state=current();zoom=state['board']['zoom'];selected=state['selected'];after=d.pinch()['game']
 d.check(after['board']['zoom']<zoom and after['selected']==selected,'Android tactical pinch zooms without changing selected fighter')
 position=after['board']['position'];after=d.pinch(mode='pan')['game']
 d.check(after['board']['position']!=position,'Android two-finger pan changes tactical camera')
 x,y,w,h=after['board']['rect'];position=after['board']['position'];d.swipe(x+w*.55,y+h*.65,x+w*.55+50,y+h*.65+25);after=current()
 d.check(after['board']['position']!=position,'Android single-finger drag pans tactical camera')
 before=saved();d.click('Load');after=saved()
 d.check(before['rng']==after['rng'] and before['battle']['units']==after['battle']['units'],'Android active-combat Save/Load preserves AP, wounds, positions and PRNG')
 old_round=after['battle']['round'];d.click('End turn');state=wait_game(lambda s:s.get('round',0)>old_round)
 d.check(state['round']==old_round+1 and state['turn']=='company','Android End turn runs enemy AI and returns control')
 d.capture('android-combat');d.click('Save')
except Exception as error:
 d.check(False,str(error));raise
finally:
 report=d.finish('tactical');print(json.dumps(report),flush=True)
raise SystemExit(1 if report['failed'] else 0)
