import argparse,json,time,pathlib
from android_smoke import Device
p=argparse.ArgumentParser();p.add_argument('--adb',required=True);p.add_argument('--serial',default='emulator-5554');p.add_argument('--output',required=True);p.add_argument('--fixture',required=True);a=p.parse_args();d=Device(a.adb,a.serial,a.output)
extra={}
try:
 d.wait_button('Load campaign')
 d.call('push',a.fixture,'/data/local/tmp/marches-android-scale.json')
 d.shell('run-as',d.package,'cp','/data/local/tmp/marches-android-scale.json','files/campaign.json')
 begin=time.monotonic();d.click('Load campaign');d.wait_button('End turn',60)
 state=d.state();extra['tap_to_observed_load_ms']=(time.monotonic()-begin)*1000
 d.check(state['game']['phase']=='combat','Android loads validated synthetic 160 by 160 combat fixture through Load')
 d.click('Save')
 for retry in range(60):
  state=d.state()
  if state['game']['message']=='Campaign saved': break
  d.fresh(state['ticks'])
 raw=d.call('exec-out','run-as',d.package,'cat','files/campaign.json');saved=json.loads(raw)
 d.check(saved['battle']['width']==160 and saved['battle']['height']==160 and len(saved['battle']['tiles'])==25600,'Android writes and validates all 25600 battlefield cells')
 time.sleep(6);state=d.state();d.capture('android-160-grid')
 extra.update({'fixture':'Synthetic partially surveyed logical grid, not an authored gameplay encounter','debug_observer_frame_ms':state['observed_frame_ms'],'save_bytes':len(raw.encode()),'memory':d.shell('dumpsys','meminfo',d.package)})
except Exception as error:
 d.check(False,str(error));raise
finally:
 report=d.finish('scale');report.update(extra)
 (pathlib.Path(a.output)/'scale-results.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
 print(json.dumps({k:v for k,v in report.items() if k not in ['checks','memory']}),flush=True)
raise SystemExit(1 if report['failed'] else 0)
