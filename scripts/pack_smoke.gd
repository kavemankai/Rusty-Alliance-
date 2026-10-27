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
 check(app.game.s.mercs.mara.has_all(app.Data.Skills.ALL),"Packaged character has all seven skills")
 var roster=JSON.parse_string(FileAccess.get_file_as_string("res://data/greywake_roster.json"))
 check(roster is Dictionary and roster.get("templates") is Array,"Packaged Greywake roster status/data file exists")
 var grey=app.Campaign.new()
 check(grey.configure_fall_of_greywake() and grey.s.funds==2400 and grey.s.squads.first.members.is_empty(),"Packaged authoritative roster/scenario and shipping script")
 check(grey.s.shipping.next_arrival_at==4680 and grey.valid_save(grey.s),"Packaged calendar and save validation")
 check(not ResourceLoader.exists("res://assets/quaternius/characters/glTF/Wizard.gltf"),"Unused library models stay out of player builds")
 check("Quaternius art assets" in FileAccess.get_file_as_string("res://THIRD_PARTY_NOTICES.txt"),"Packaged art credit and CC0 notice")
 check(ResourceLoader.exists("res://assets/greywake/production_ui/button_normal.png"),"Packaged supplied UI texture")
 check(not ResourceLoader.exists("res://art_reference/greywake_v02/preview/portrait_overview.png"),"Reference boards and unmapped faces excluded from player pack")
 check(not ResourceLoader.exists("res://art_reference/greywake_v02/assets/maps/greywake_isle_full.png"),"Mismatched baked-label map is reference-only")
 var opening=app.Campaign.new();opening.autosave_path="user://opening-pack-smoke-auto.json"
 check(opening.configure_greywake_opening() and opening.valid_save(opening.s),"Packaged opening/dialogue/island data loads")
 opening.command("opening_skip")
 for repeat in range(2): opening.command("recruit_template",{"template":"militia_spearman"})
 opening.command("opening_confirm");opening.command("opening_depart");opening.command("opening_skip");opening.command("opening_next");opening.command("opening_next")
 check(opening.command("dockside_start") and opening.command("confirm_deployment"),"Packaged opening reaches real dockside combat")
 check(opening.battle.t.tiles.any(func(tile):return tile.kind=="water" and tile.block),"Packaged authored dockside collision")
 app.game=opening;app.tab="sector";app.selected="";app.rebuild()
 await process_frame;await process_frame
 check(ResourceLoader.exists("res://assets/greywake/scenes/03_tavern_recruitment_1920x1080.png") and ResourceLoader.exists("res://assets/greywake/island.svg"),"Packaged actual opening illustrations")
 check(app.battle_view.geometry.get_children().any(func(node):return node.get_meta("asset_key","")=="barrel"),"Packaged additional CC0 barrel mesh and materials")
 print("PACK_SMOKE: "+JSON.stringify({"failed":failures.size(),"failures":failures,"actors":actors}))
 app.queue_free();await process_frame;await process_frame
 quit(0 if failures.is_empty() else 1)
