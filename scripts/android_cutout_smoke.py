import argparse,json,time,re
from android_smoke import Device
p=argparse.ArgumentParser();p.add_argument('--adb',required=True);p.add_argument('--serial',default='emulator-5554');p.add_argument('--output',required=True);a=p.parse_args();d=Device(a.adb,a.serial,a.output)
overlay='com.android.internal.display.cutout.emulation.tall'
def launcher():
 time.sleep(3)
 d.shell('am','force-stop',d.package)
 d.shell('am','start','-a','android.intent.action.MAIN','-c','android.intent.category.LAUNCHER','-p',d.package)
 d.wait_button('New campaign')
try:
 d.shell('input','keyevent','KEYCODE_HOME');time.sleep(3)
 d.shell('cmd','overlay','enable','--user','0',overlay);launcher();state=d.state()
 left,top,width,height=[int(x) for x in re.findall(r'-?\d+',state['safe_area'])]
 x,y,w,h=state['ui_rect']
 d.check(left==72 and x>=left and x+w<=left+width,'Simulated Android display cutout is excluded from menu layout')
 d.click('New campaign');state=d.state()
 controls=[b for b in state['buttons'] if b['text'] in ['Map','Settings','Save','+1 hour']]
 d.check(len(controls)==4 and all(b['rect'][0]>=left and b['rect'][0]+b['rect'][2]<=left+width for b in controls),'Core navigation and Save controls remain inside Android cutout safe area')
 d.click('Save')
 for retry in range(15):
  state=d.state()
  if state['game']['message']=='Campaign saved': break
  d.fresh(state['ticks'])
 d.check(state['game']['message']=='Campaign saved','Android touch Save works with a cutout inset')
 d.capture('android-cutout')
 d.shell('cmd','overlay','disable','--user','0',overlay);launcher();state=d.state()
 d.check(state['ui_rect'][0]==0 and state['screen'][0]>state['screen'][1],'Removing simulated cutout restores full landscape layout')
except Exception as error:
 d.check(False,str(error));raise
finally:
 # Always leave the dedicated emulator with its ordinary display configuration.
 d.shell('cmd','overlay','disable','--user','0',overlay)
 report=d.finish('cutout');print(json.dumps(report),flush=True)
raise SystemExit(1 if report['failed'] else 0)
