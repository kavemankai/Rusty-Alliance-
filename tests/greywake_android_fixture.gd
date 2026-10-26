extends SceneTree
const C=preload("res://sim/campaign.gd")
func _init() -> void:
 DirAccess.make_dir_recursive_absolute("res://builds")
 for blocked in [false,true]:
  var c=C.new();c.autosave_path="user://greywake-android-fixture-auto.json"
  assert(c.configure_fall_of_greywake())
  for i in range(2): assert(c.command("recruit_template",{"template":"militia_spearman"}))
  assert(c.command("embark"))
  if blocked: C.Shipping.set_closure(c,"QA authored blockade")
  assert(c.advance(C.Shipping.FIRST_ARRIVAL-c.s.time))
  assert(c.save_to("res://builds/greywake-"+("offshore" if blocked else "docked")+"-android-fixture.json"))
 print("GREYWAKE_ANDROID_FIXTURES: production profiles, legitimate clock and owned inventories; 0 failures")
 quit()
