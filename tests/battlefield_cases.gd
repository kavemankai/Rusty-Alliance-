extends RefCounted
const Campaign=preload("res://sim/campaign.gd")
const Layouts=preload("res://sim/battlefields.gd")

static func contact(index: int,garrison: bool=false):
 var c=Campaign.new()
 c.autosave_path="user://battlefield-test-autosave.json"
 var force=c.s.groups[0]
 c.s.groups=[]
 if garrison:
  c.s.sectors[index].owner="company"
  for i in range(4 if index==52 else 3): c.command("levy",{"sector":index})
  c.s.squads.first.sector=1
 else:
  c.command("hire",{"id":"ada"})
  if index==52: c.command("hire",{"id":"bram"})
  c.s.squads.first.sector=index
  c.s.sectors[index].owner="bandits"
 force.sector=index;force.objective=index;force.stationary=true
 c.s.groups=[force]
 c.encounter({} if garrison else c.s.squads.first,index)
 c.command("enter")
 return c

static func connected(field: Dictionary) -> bool:
 var start=field.deployment_zones[0]
 var seen={int(start.y)*int(field.width)+int(start.x):true}
 var queue=seen.keys()
 while not queue.is_empty():
  var at=queue.pop_front()
  var x=int(at)%int(field.width)
  var y=int(at)/int(field.width)
  for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
   var nx=x+d.x;var ny=y+d.y
   if nx<0 or ny<0 or nx>=field.width or ny>=field.height: continue
   var key=ny*int(field.width)+nx
   var cell=field.tiles[key]
   if seen.has(key) or (cell.block and not cell.door): continue
   seen[key]=true;queue.append(key)
 for point in field.enemy_spawns:
  if not seen.has(int(point.y)*int(field.width)+int(point.x)): return false
 return true

static func run(test) -> void:
 var geometries={}
 for spec in [[17,"settlement"],[34,"farm"],[36,"mine"],[52,"camp"]]:
  var index=spec[0];var kind=spec[1]
  var c=contact(index)
  var b=c.battle
  var field=b.field_state()
  test.check(b.t.layout==kind and field.layout_version==1 and Layouts.valid_metadata(field),"Sector chooses authored "+kind+" layout and metadata")
  test.check(JSON.stringify(Layouts.create(c.s.sectors[index]))==JSON.stringify(Layouts.create(c.s.sectors[index])),"Layout generation is deterministic for "+kind)
  geometries[JSON.stringify(field.tiles)]=true
  test.check(connected(field),"Every authored spawn is reachable from entry with openable doors: "+kind)
  var legal=true
  for u in b.t.units:
   if u.team=="company": legal=legal and u.deployed and b.deployment_error(u.id,u.x,u.y)==""
   else: legal=legal and {"x":u.x,"y":u.y} in field.enemy_spawns and not b.tile(u.x,u.y).block
  test.check(legal,"Friendly formation and hostile spawn cells are legal on "+kind)
  test.check(c.save_to("user://map-formation.json"),"Unconfirmed authored formation saves: "+kind)
  var loaded=Campaign.new()
  loaded.autosave_path=c.autosave_path
  test.check(loaded.load_from("user://map-formation.json") and loaded.battle.t.phase=="deployment" and loaded.battle.field_state()==field,"Authored geometry/zones/spawns survive deployment reload: "+kind)
  test.check(c.command("confirm_deployment"),"Company formation confirms on "+kind)
  test.play_battle(c)
  test.check(b.outcome()=="victory" and c.command("resolve") and c.s.sectors[index].owner=="company","Legal-action company battle captures "+kind)
  c=contact(index,true);b=c.battle
  test.check(b.t.squads.is_empty() and b.unit("mara")==null and c.command("confirm_deployment"),"Home-only garrison deployment confirms on "+kind)
  test.play_battle(c)
  test.check(b.outcome()=="victory" and c.command("resolve") and c.s.sectors[index].owner=="company","Legal-action garrison defence wins on "+kind)
  # A controlled adjacency fixture isolates actual door commands from combat.
  c=contact(index);b=c.battle;c.command("confirm_deployment")
  var door={}
  for cell in b.t.tiles:
   if cell.door: door=cell;break
  var actor=b.unit("mara")
  var adjacent={}
  for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
   var cell=b.tile(door.x+d.x,door.y+d.y)
   if not cell.is_empty() and not cell.block and b.at(cell.x,cell.y)==null: adjacent=cell;break
  actor.x=adjacent.x;actor.y=adjacent.y;actor.ap=26
  test.check(b.action(actor.id,"door",{"x":door.x,"y":door.y}) and door.open and not door.block,"Actual door command opens authored geometry: "+kind)
  var loot=c.s.stash.pop_back()
  b.t.ground.append({"x":adjacent.x,"y":adjacent.y,"item":loot})
  var metadata={}
  for key in Layouts.META: metadata[key]=b.t[key].duplicate(true) if b.t[key] is Array else b.t[key]
  test.check(c.command("retreat") and c.save_to("user://map-retreat.json") and loaded.load_from("user://map-retreat.json"),"Retreat and campaign reload preserve authored field: "+kind)
  c=loaded
  c.s.sectors[index].facility="" # Ownership/facility changes cannot reroll visited maps.
  c.command("route",{"sector":index});c.command("advance",{"minutes":600});c.command("enter")
  b=c.battle
  var retained=b!=null and b.t.layout==kind and b.tile(door.x,door.y).open and not b.tile(door.x,door.y).block
  if b!=null:
   for key in Layouts.META: retained=retained and b.t[key]==metadata[key]
  test.check(retained,"Re-entry retains doors and authored metadata despite changed facility: "+kind)
  test.check(b.t.ground.size()==1 and b.t.ground[0].item.id==loot.id,"Uncollected unique ground item survives retreat/save/re-entry: "+kind)
  c=contact(index)
  c.command("retreat")
  var reinforcement=Campaign.new().s.groups[1]
  reinforcement.sector=index;reinforcement.stationary=true
  var occupied_spawn=c.s.sectors[index].battlefield.enemy_spawns[2]
  var veteran=c.s.groups[0].fighters[0].id
  c.s.groups[0].positions[veteran]=occupied_spawn.duplicate()
  c.s.groups.append(reinforcement)
  c.command("route",{"sector":index});c.command("advance",{"minutes":600});c.command("enter")
  b=c.battle
  var safe=b.unit(veteran).x==occupied_spawn.x and b.unit(veteran).y==occupied_spawn.y
  var used={}
  for u in b.t.units:
   if u.team!="enemy": continue
   var point={"x":u.x,"y":u.y}
   safe=safe and point in b.t.enemy_spawns and not used.has(str(point))
   used[str(point)]=true
  test.check(safe and used.size()==5,"Reinforcements use free authored spawns without moving veterans or falling into entry zone: "+kind)
 test.check(geometries.size()==4,"Settlement, farm, mine and camp have distinct tactical geometry")
 var c=contact(36)
 test.check(not c.battle.deployment_tile(c.battle.t,5,0) and c.battle.deployment_tile(c.battle.t,4,0),"Mine uses its authored five-column entry instead of legacy strip")
 c=contact(52)
 test.check(not c.battle.deployment_tile(c.battle.t,0,7) and c.battle.deployment_tile(c.battle.t,0,8),"Camp uses two separated authored approach zones")
 var invalid=c.s.duplicate(true)
 invalid.sectors[52].battlefield.deployment_zones[0].w=999
 test.check(not c.valid_save(invalid),"Out-of-bounds authored deployment zone is rejected")
 invalid=c.s.duplicate(true)
 invalid.sectors[52].battlefield.enemy_spawns[0].x=0.5
 test.check(not c.valid_save(invalid),"Fractional authored spawn coordinate is rejected")
 invalid=c.s.duplicate(true)
 invalid.battle.layout="mine"
 test.check(not c.valid_save(invalid),"Active battlefield metadata must match its owning sector")
 invalid=c.s.duplicate(true)
 invalid.sectors[52].battlefield.erase("layout")
 test.check(not c.valid_save(invalid),"Partial map metadata cannot masquerade as a legacy field")
 var loaded=Campaign.new()
 test.check(loaded.load_from("res://tests/fixtures/schema2-tactical.json") and not loaded.battle.t.has("layout"),"Actual older save retains its original unlabelled battlefield")
 var before=loaded.battle.t.tiles.duplicate(true)
 test.check(loaded.save_to("user://map-legacy.json") and loaded.load_from("user://map-legacy.json") and loaded.battle.t.tiles==before and not loaded.battle.t.has("deployment_zones"),"Legacy geometry roundtrips without regeneration or invented authored zones")
 for terrain in ["road","forest","hills","marsh","grass"]:
  var sector={"id":90,"facility":"","terrain":terrain}
  var field=Layouts.create(sector)
  test.check(Layouts.valid_metadata(field) and connected(field),"Wilderness fallback has usable spawn/entry connectivity for "+terrain)
