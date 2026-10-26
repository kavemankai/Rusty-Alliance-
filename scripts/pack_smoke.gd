extends SceneTree
var failures=[]
func _init() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
 if not ok: failures.append(message)
func run() -> void:
 var scene=load("res://main.tscn")
 check(scene!=null,"Packaged main scene")
 var app=scene.instantiate();root.add_child(app)
 await process_frame;await process_frame
 app.game=app.Campaign.new();app.game.autosave_path="user://asset-pack-smoke-autosave.json"
 app.rebuild();app.change_tab("company");app.change_tab("inventory")
 app.game.s.squads.first.sector=34
 app.game.encounter(app.game.s.squads.first,34)
 check(app.game.command("enter"),"Packaged encounter entry")
 app.rebuild()
 await process_frame;await process_frame
 var actors=0
 for child in app.battle_view.geometry.get_children():
  if child.has_meta("actor_id"): actors+=1
 check(actors>=2,"Packaged actor meshes and materials")
 check(load("res://ui/asset_icons.gd").TEXTURES.size()==63,"Packaged thumbnail dependencies")
 check(not ResourceLoader.exists("res://assets/quaternius/characters/glTF/Wizard.gltf"),"Unused library models stay out of player builds")
 check("Quaternius art assets" in FileAccess.get_file_as_string("res://THIRD_PARTY_NOTICES.txt"),"Packaged art credit and CC0 notice")
 print("PACK_SMOKE: "+JSON.stringify({"failed":failures.size(),"failures":failures,"actors":actors}))
 app.queue_free();await process_frame;await process_frame
 quit(0 if failures.is_empty() else 1)
