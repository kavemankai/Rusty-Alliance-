"""Android OS-input smoke helpers for an isolated emulator; no game commands are injected."""
import argparse,json,pathlib,subprocess,time,sys
sys.stdout.reconfigure(encoding="utf-8");sys.stderr.reconfigure(encoding="utf-8")
class Device:
 def __init__(self,adb,serial,output):
  if not serial.startswith('emulator-'): raise ValueError('This automated scenario requires an isolated emulator')
  self.adb=adb;self.serial=serial;self.output=pathlib.Path(output);self.output.mkdir(parents=True,exist_ok=True);self.package='org.brokenmarches.foundation';self.checks=[]
 def call(self,*args,binary=False,check=True):
  r=subprocess.run([self.adb,'-s',self.serial,*args],capture_output=True,timeout=60)
  if check and r.returncode: raise RuntimeError(r.stderr.decode(errors='replace'))
  return r.stdout if binary else r.stdout.decode(errors='replace').strip()
 def shell(self,*args): return self.call('shell',*args)
 def state(self):
  for retry in range(15):
   try: return json.loads(self.call('exec-out','run-as',self.package,'cat','files/mobile-qa.json'))
   except (ValueError,RuntimeError): time.sleep(1)
  raise RuntimeError('No Android QA telemetry; enable the read-only debug observer first')
 def fresh(self,after_ticks):
  for retry in range(300):
   state=self.state()
   if state['ticks']!=after_ticks: return state
   time.sleep(0.1)
  raise RuntimeError('Android observer did not publish a fresh frame')
 def wait_button(self,label,timeout=30):
  deadline=time.monotonic()+timeout
  while time.monotonic()<deadline:
   state=self.state()
   if any(b['text']==label for b in state['buttons']): return state
   time.sleep(0.25)
  raise RuntimeError('Android launch did not reach button '+label)
 def settled(self):
  time.sleep(1.2);return self.state()
 def tap(self,x,y):
  self.shell('input','tap',str(round(x)),str(round(y)))
  # Wait beyond a frame published after input, including slow first-scene imports.
  first=self.settled();return self.fresh(first['ticks'])
 def swipe(self,x1,y1,x2,y2,duration=400):
  self.shell('input','swipe',*[str(round(n)) for n in [x1,y1,x2,y2,duration]]);return self.settled()
 def click(self,label):
  for attempt in range(32):
   s=self.state();candidates=[b for b in s['buttons'] if b['text']==label] or [b for b in s['buttons'] if b['text'].startswith(label)]
   for b in candidates:
    x,y,w,h=b['rect'];cx,cy,cw,ch=b['clip']
    if not b['disabled'] and cw>20 and ch>=min(35,h*0.8) and cx<=x+w/2<=cx+cw and cy<=y+h/2<=cy+ch:
     # Inertial scrolling can move buttons after the previous telemetry frame.
     latest=self.fresh(s['ticks'])
     same=[item for item in latest['buttons'] if item['text']==b['text']]
     if not same or any(abs(same[0]['rect'][i]-b['rect'][i])>1 for i in range(4)): break
     return self.tap(x+w/2,y+h/2)
   if any(b['clip'][3]>35 for b in candidates): time.sleep(0.2);continue
   if not candidates: raise RuntimeError('Missing button '+label+'; available '+str([b['text'] for b in s['buttons']]))
   if not s['scrolls']: raise RuntimeError('Button outside screen without scroll '+label)
   scroll=s['scrolls'][0];x,y,w,h=scroll['rect'];target=candidates[0]['rect']
   distance=min(h*0.25,abs(target[1]+target[3]/2-(y+h/2)))
   if target[1]<y: self.swipe(x+w/2,y+h*0.4,x+w/2,y+h*0.4+distance,900)
   else: self.swipe(x+w/2,y+h*0.6,x+w/2,y+h*0.6-distance,900)
  raise RuntimeError('Could not scroll to '+label)
 def pinch(self,x=400,y=350,mode="pinch"):
  # Inject real two-pointer MotionEvents through Android's privileged shell test interface.
  output=self.shell('env','CLASSPATH=/data/local/tmp/marches-gesture.jar','app_process','/system/bin','MarchesGesture',str(x),str(y),mode)
  if 'ANDROID TWO-POINTER INPUT COMPLETE' not in output: raise RuntimeError(output)
  return self.settled()
 def check(self,ok,name):
  self.checks.append({'name':name,'passed':bool(ok)});print(('PASS: ' if ok else 'FAIL: ')+name,flush=True)
 def capture(self,name):
  (self.output/(name+'.png')).write_bytes(self.call('exec-out','screencap','-p',binary=True))
 def finish(self,scenario):
  path=self.output/(scenario+'-results.json');report={'scenario':scenario,'serial':self.serial,'android':self.shell('getprop','ro.build.version.release'),'api':self.shell('getprop','ro.build.version.sdk'),'device':self.shell('getprop','ro.product.model'),'passed':sum(c['passed'] for c in self.checks),'failed':sum(not c['passed'] for c in self.checks),'checks':self.checks,'limits':['Emulator evidence does not establish physical-phone touch, thermals, battery or sustained low-end performance.','Optional read-only debug telemetry adds overhead; it does not invoke game commands.']};path.write_text(json.dumps(report,indent=2),encoding='utf-8');return report
if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('--adb',required=True);parser.add_argument('--serial',default='emulator-5554');parser.add_argument('--output',type=pathlib.Path,required=True);parser.add_argument('--scenario',choices=['basic','gestures','lifecycle'],default='basic');a=parser.parse_args();d=Device(a.adb,a.serial,a.output)
 try:
  if a.scenario=='basic':
   d.wait_button('New campaign');d.click('New campaign');s=d.state();d.check(s['game']['funds']==1200,'Android native touch starts original campaign')
   d.click('Save');baseline=d.state()['game'];d.click('Company');d.click('Ada');d.click('Hire');s=d.state();d.check(s['game']['mercs']['ada']['hired'] and s['game']['funds']==1100,'Touch scrolling, character selection and hiring change canonical funds/membership')
   d.click('Inventory');d.click('Mara');d.click('Take Sword');d.click('Sword \u00b7 100% condition');d.click('Give to Ada');d.click('Ada');d.click('Sword \u00b7 100% condition');d.click('Equip carried item')
   d.check(d.state()['game']['mercs']['ada']['weapon']=='sword','Android stockpile transfer, person handover and equipment controls change actual loadout')
   d.click('Load');s=d.state();d.check(s['game']['funds']==1200 and not s['game']['mercs']['ada']['hired'],'Touch Load restores saved state after hiring')
   d.click('Map');s=d.state();m=s['game']['map'];d.tap(*m['sectors']['34']);s=d.state();d.check(s['game']['selected_sector']==34,'Android touch selects intended strategic sector once')
   x,y,w,h=s['game']['map']['rect'];old=s['game']['map']['offset'];d.swipe(x+w*0.55,y+h*0.6,x+w*0.55+80,y+h*0.6+30);s=d.state();d.check(s['game']['map']['offset']!=old and s['game']['selected_sector']==34,'Android strategic drag pans without changing selected sector')
   old=s['game']['map']['zoom'];d.click('+');d.check(d.state()['game']['map']['zoom']>old,'On-screen zoom works without a keyboard')
   d.click('Contracts');d.click('Accept Clear Redbank');s=d.state();d.check(s['game']['jobs'][0]['status']=='active','Android contract board accepts a real contract')
   d.click('Map');s=d.state();d.tap(*s['game']['map']['sectors']['34']);d.click('Plot route to selected sector');d.check(bool(d.state()['game']['route']),'Touch confirmation plots actual strategic route')
   d.click('+6 hours');s=d.state();d.check(s['game']['time']>baseline['time'],'Android clock advances real travel/events')
   d.capture('android-strategic');d.click('Save')
  elif a.scenario=='gestures':
   before=d.state()['game'];after=d.pinch(mode='pan')['game']
   d.check(after['map']['offset']!=before['map']['offset'] and after['selected_sector']==before['selected_sector'],'Android two-pointer pan changes map offset without selection')
   before=after;after=d.pinch()['game']
   d.check(after['map']['zoom']>before['map']['zoom'] and after['selected_sector']==before['selected_sector'],'Android two-pointer pinch changes map zoom without selection')
   d.capture('android-pinch')
  else:
   s=d.state();before=s['game'];d.check(before is not None,'Lifecycle fixture has an active campaign')
   d.shell('input','keyevent','KEYCODE_HOME');time.sleep(3)
   raw=d.call('exec-out','run-as',d.package,'cat','files/autosave.json');saved=json.loads(raw)
   d.check(saved['time']==before['time'] and saved['funds']==before['funds'],'Android Home notification writes current campaign autosave')
   d.shell('am','force-stop',d.package);d.shell('am','start','-a','android.intent.action.MAIN','-c','android.intent.category.LAUNCHER','-p',d.package);d.wait_button('Continue autosave');d.click('Continue autosave');d.wait_button('End turn' if before['phase']=='combat' else '+1 hour');after=d.state()['game']
   d.check(after['time']==before['time'] and after['funds']==before['funds'] and after['phase']==before['phase'],'Android process recreation restores phase, clock and funds')
   if saved.get('battle'):
    d.click('Save');restored=json.loads(d.call('exec-out','run-as',d.package,'cat','files/campaign.json'))
    d.check(saved['rng']==restored['rng'] and saved['battle']['units']==restored['battle']['units'],'Android process recreation preserves exact combat profiles, AP, wounds and PRNG')
   d.click('Settings');d.click('Main menu');d.wait_button('Cancel');d.click('Cancel');d.click('Return to map / battle')
   d.check(d.state()['game']['phase']==before['phase'],'Android confirmation Cancel returns to the existing game without leaving')
   d.capture('android-resumed')
 except Exception as error:
  d.check(False,str(error));raise
 finally:
  report=d.finish(a.scenario);print(json.dumps(report),flush=True)
 raise SystemExit(1 if report['failed'] else 0)
