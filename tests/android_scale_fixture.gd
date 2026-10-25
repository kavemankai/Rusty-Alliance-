extends SceneTree
func _init() -> void:
 var c=preload("res://tests/exploration_cases.gd").field()
 c.command("confirm_deployment")
 var b=c.battle;b.build_map(160,160)
 b.t.fog={"company":{},"enemy":{}};b.t.knowledge={"company":{},"enemy":{}}
 b.fog_signature=-1;b.fog_observers={};b.light_signature=-1
 var index=0
 for u in b.t.units:
  u.x=1 if u.team=="company" else 157;u.y=2+index*2;index+=1
 b.refresh_knowledge()
 if not c.save_to("res://builds/android-scale.json"):
  push_error(c.error);quit(1);return
 print("ANDROID SCALE FIXTURE: validated 25600 tiles and canonical profiles");quit()
