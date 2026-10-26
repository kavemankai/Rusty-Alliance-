extends SceneTree
const Art=preload("res://ui/asset_visuals.gd")
const Icons=preload("res://ui/asset_icons.gd")
var passed=0
var failures=[]
func _init() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
 if ok: passed+=1
 else: failures.append(message)
func run() -> void:
 var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/quaternius/manifest.json"))
 for row in manifest.models:
  check(ResourceLoader.exists(row.path),"Imported library model remap: "+row.path)
 for key in Art.Catalog.MODELS:
  var model=Art.model(key,Vector3.ONE)
  check(model!=null and Art.bounds(model).size.length()>0,"Nonempty runtime model: "+key)
  check(Icons.get_icon(key)!=null,"Matching readable icon dependency: "+key)
  model.free()
 var game=preload("res://tests/exploration_cases.gd").field()
 var snapshot=game.s.duplicate(true)
 var view=preload("res://ui/battle_view.gd").new();view.battle=game.battle
 root.add_child(view)
 for repeat in range(3): view.redraw()
 check(game.s==snapshot,"Art construction/redraw never mutates authoritative campaign state")
 for child in view.geometry.get_children():
  if child.has_meta("actor_id"):
   check(game.battle.unit(child.get_meta("actor_id"))!=null,"Model references an actual canonical fighter")
 check(Icons.item({"kind":"ammo","ammo_type":"arrows"})==Icons.get_icon("arrows"),"Ammunition icon follows actual ammo type")
 check(Icons.item({"kind":"stone"})==Icons.get_icon("rock"),"Throwing stone reuses rock art")
 check(Icons.item({"kind":"crossbow"})==null,"Missing medieval crossbow art stays explicit instead of using a sci-fi weapon")
 view.queue_free();await process_frame;await process_frame
 var result={"passed":passed,"failed":failures.size(),"failures":failures,"library_models":manifest.models.size(),"runtime_mappings":Art.Catalog.MODELS.size(),"rendered_icons":Icons.TEXTURES.size()}
 var file=FileAccess.open("res://asset-test-results.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));file.close()
 print("ASSET_TESTS: "+JSON.stringify(result))
 quit(0 if failures.is_empty() else 1)
