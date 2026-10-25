extends RefCounted
const Campaign=preload("res://sim/campaign.gd")
const Data=preload("res://sim/catalog.gd")
const Items=preload("res://sim/inventory.gd")

static func first_kind(entries: Array,kind: String) -> Dictionary:
 for entry in entries:
  if entry.kind==kind: return entry
 return {}

static func run(test) -> void:
 var c=Campaign.new()
 c.autosave_path="user://continuity-autosave.json"
 var mara=c.s.mercs.mara
 var oswin=c.s.mercs.oswin
 test.check(Items.ownership_error(c.s)=="","Every starting item has one valid owner and a unique ID")
 var sword=first_kind(c.s.stash,"sword")
 var old_sword=Data.equipped(mara,"weapon")
 test.check(sword.id!=old_sword.id,"Two swords are distinct persistent items")
 sword.condition=37
 test.check(c.command("transfer",{"from":"stash","to":"mara","item":sword.id}) and Items.find(mara.inventory,sword.id)==sword and Items.find(c.s.stash,sword.id).is_empty(),"Taking a stockpile item moves its actual identity")
 test.check(c.command("equip",{"id":"mara","item":sword.id}) and Data.condition(mara)==37 and Items.find(mara.inventory,old_sword.id)==old_sword,"Switching swords retains each item's own condition and displaced weapon")
 var before=JSON.stringify(c.s)
 test.check(not c.command("transfer",{"from":"mara","to":"oswin","item":sword.id}) and JSON.stringify(c.s)==before,"Equipped-item transfer is rejected atomically")
 test.check(c.command("unequip",{"id":"mara","slot":"weapon"}) and Data.weapon(mara)=="unarmed","Unequipping changes combat loadout without deleting the item")
 test.check(c.command("transfer",{"from":"mara","to":"oswin","item":sword.id}) and Items.find(oswin.inventory,sword.id).condition==37,"Character transfer preserves item ID and condition")
 test.check(c.command("equip",{"id":"oswin","item":sword.id}) and Data.weapon(oswin)=="sword" and first_kind(oswin.inventory,"bow").id=="oswin:weapon","Recipient equips transferred gear and keeps previous weapon")
 var weight=Data.weight(oswin)
 test.check(weight>Data.WEAPONS.sword.weight+Data.ARMOUR.padded.weight,"Backpack weapons contribute to encumbrance")
 c.command("split",{"id":"oswin"})
 c.s.squads.squad_oswin.sector=18
 before=JSON.stringify(c.s)
 test.check(not c.command("transfer",{"from":"oswin","to":"mara","item":"oswin:weapon"}) and JSON.stringify(c.s)==before,"Remote squad transfers cannot teleport equipment")
 var spare=first_kind(c.s.stash,"spear")
 test.check(not c.command("equip",{"id":"oswin","item":spare.id}) and Items.find(c.s.stash,spare.id)==spare,"Base stockpile cannot be equipped remotely")
 var invalid=c.s.duplicate(true)
 invalid.stash.append(mara.inventory[0].duplicate(true))
 test.check(not c.valid_save(invalid),"Save validation rejects duplicate ownership across containers")
 invalid=c.s.duplicate(true)
 invalid.mercs.mara.equipment.weapon="missing_item"
 test.check(not c.valid_save(invalid),"Save validation rejects equipment not owned by its wearer")
 invalid=c.s.duplicate(true)
 invalid.next_item=1
 test.check(not c.valid_save(invalid),"Save validation prevents the item allocator from reusing existing IDs")
 # Combat transfers use the same ownership operation, with proximity and real AP.
 c=Campaign.new()
 c.autosave_path="user://continuity-autosave.json"
 spare=first_kind(c.s.stash,"spear")
 c.command("transfer",{"from":"stash","to":"mara","item":spare.id})
 c.command("route",{"sector":34})
 c.command("advance",{"minutes":600})
 c.command("enter")
 var b=c.battle
 var a=b.unit("mara")
 var friend=b.unit("oswin")
 var ap=a.ap
 test.check(not c.command("transfer",{"from":"mara","to":"oswin","item":spare.id}) and a.ap==ap,"Combat transfer requires adjacency and rejected transfer spends no AP")
 friend.x=a.x;friend.y=a.y+1
 test.check(c.command("transfer",{"from":"mara","to":"oswin","item":spare.id}) and a.ap==ap-3,"Adjacent combat handover consumes exactly three AP")
 ap=friend.ap
 test.check(c.command("equip",{"id":"oswin","item":spare.id}) and friend.ap==ap-3 and Data.weapon(friend.person)=="spear","Combat equip uses the transferred item and charges AP")
 test.check(Items.ownership_error(c.s)=="","Combat transfer and equipment change preserve unique ownership")
 # Actual killed enemy equipment becomes persistent ground items, not fresh loot.
 c=test.fixture(1)
 b=c.battle
 a=b.unit("mara")
 var dead=test.enemy(b)
 a.x=8;a.y=6;a.ap=26;a.person.melee=100
 dead.x=9;dead.y=6;dead.ap=0;dead.person.hp=1
 b.tile(7,6).open=true;b.tile(7,6).block=false
 var dead_ids=[]
 for entry in dead.person.inventory: dead_ids.append(entry.id)
 b.refresh_knowledge()
 test.check(b.attack(a,dead) and dead.person.hp==0,"Continuity fixture kills an enemy through a legal attack")
 test.check(dead.person.inventory.is_empty() and dead.person.equipment.is_empty() and b.t.ground.size()==dead_ids.size(),"Death transfers all actual equipment and ammunition to ground once")
 var ground_id=b.t.ground[0].item.id
 a.ap=26
 test.check(b.action(a.id,"loot") and not Items.find(a.person.inventory,ground_id).is_empty() and b.t.ground.size()==dead_ids.size()-1,"Looting transfers an existing ground item into the looter backpack")
 var survivor=null
 for u in b.t.units:
  if u.team=="enemy" and u.person.hp>0: survivor=u
 survivor.person.hp=37
 survivor.person.bleeding=2
 survivor.person.loaded=false
 Data.equipped(survivor.person,"weapon").condition=61
 first_kind(survivor.person.inventory,"ammo").quantity=7
 survivor.x=12;survivor.y=6
 var survivor_id=survivor.id
 var dead_id=dead.id
 var left_on_ground=b.t.ground.size()
 test.check(c.retreat_options()[0]==33,"Withdrawal prefers the actual adjacent arrival sector")
 test.check(c.command("retreat") and c.s.squads.first.sector==33,"Retreat withdraws to an adjacent safe sector rather than Ashford")
 test.check(c.force_strength(c.s.groups[0])==1,"Strategic force strength reflects casualties after retreat")
 test.check(c.s.factions.bandits.losses==1,"Tactical casualty updates faction loss accounting on retreat")
 test.check(Items.ownership_error(c.s)=="","Retreat and looting retain exactly one owner for every item")
 test.check(c.save_to("user://retreat-continuity.json"),"Retreat campaign saves persistent battlefield and hostile roster")
 var loaded=Campaign.new()
 loaded.autosave_path="user://continuity-autosave.json"
 test.check(loaded.load_from("user://retreat-continuity.json"),"Retreat campaign reloads")
 loaded.command("route",{"sector":34})
 loaded.command("advance",{"minutes":120})
 loaded.command("enter")
 var returning=loaded.battle
 test.check(returning!=null and returning.unit(dead_id)==null,"Dead enemies do not respawn when the sector is re-entered")
 if returning!=null:
  var same=returning.unit(survivor_id)
  test.check(same!=null and same.person.hp==37 and same.person.bleeding==2 and Data.ammo(same.person)==7 and not same.person.loaded and Data.condition(same.person)==61,"Enemy wounds ammo reload state and item condition survive retreat save and re-entry")
  test.check(same.x==12 and same.y==6,"Surviving enemies retain their local battlefield position")
  test.check(returning.tile(7,6).open and not returning.tile(7,6).block,"Door state persists across retreat and re-entry")
  test.check(returning.t.ground.size()==left_on_ground,"Uncollected loot remains on the same battlefield")
  same.person.hp=29
  test.check(loaded.s.groups[0].fighters[1].hp==29,"Re-entered enemies reference the authoritative strategic roster")
  loaded.save_to("user://active-continuity.json")
  var rebound=Campaign.new()
  test.check(rebound.load_from("user://active-continuity.json"),"Active persistent battle reloads")
  rebound.battle.unit(survivor_id).person.hp=23
  test.check(rebound.s.groups[0].fighters[1].hp==23,"Loaded enemies rebind to the authoritative strategic roster")
  var corrupt=JSON.parse_string(JSON.stringify(rebound.s))
  corrupt.battle.units[0].person.hp-=1
  test.check(not rebound.valid_save(corrupt),"Save validation rejects tactical profiles that disagree with their authoritative owner")
  corrupt=JSON.parse_string(JSON.stringify(rebound.s))
  corrupt.battle.tiles[0].cost="invalid"
  test.check(not rebound.valid_save(corrupt),"Save validation rejects malformed tactical terrain before it reaches pathfinding")
 # Blocked retreat must leave the active battle and strategic location unchanged.
 c=test.fixture()
 for index in c.neighbors(34): c.s.sectors[index].owner="bandits"
 before=JSON.stringify(c.s)
 test.check(not c.command("retreat") and JSON.stringify(c.s)==before and c.battle!=null,"Surrounded company cannot teleport out through an invalid retreat")
 # Queue all contacts generated by one strategic tick; don't drop later groups.
 c=Campaign.new()
 c.command("split",{"id":"oswin"})
 c.s.squads.squad_oswin.sector=36
 c.encounter(c.s.squads.first,17)
 c.encounter(c.s.squads.squad_oswin,36)
 c.encounter(c.s.squads.squad_oswin,36)
 test.check(c.s.pending_encounters.size()==1,"Simultaneous contacts queue once instead of overwriting or duplicating")
 c.next_encounter()
 test.check(c.s.encounter.squad=="squad_oswin","Pending valid contact becomes the next active encounter")
 c=Campaign.new()
 c.command("split",{"id":"oswin"})
 c.s.squads.squad_oswin.sector=36
 c.s.sectors[33].owner="bandits"
 c.s.sectors[35].owner="bandits"
 c.s.groups=[{"id":"west_contact","faction":"bandits","sector":33,"strength":1,"objective":17},{"id":"east_contact","faction":"bandits","sector":35,"strength":1,"objective":36}]
 c.faction_tick()
 test.check(c.s.groups[0].sector==17 and c.s.groups[1].sector==36 and c.s.pending_encounters.size()==1,"One faction tick processes all armies and preserves simultaneous contacts")
 c.s.groups[1].fighters[0].hp=0
 c.next_encounter()
 test.check(c.s.encounter.is_empty() and c.s.pending_encounters.is_empty(),"Pending encounter is discarded when its enemy force no longer exists")
 # Obsolete arrival callbacks cannot consume another route leg.
 c=Campaign.new()
 c.command("route",{"sector":34})
 var token=c.s.squads.first.route_token
 var route=c.s.squads.first.route.duplicate()
 c.arrive("first",token-1)
 test.check(c.s.squads.first.sector==17 and c.s.squads.first.route==route,"Stale travel callback cannot advance a different route")
 # Real schema-1 files generated with the previous committed game, not mock data.
 var path="res://tests/fixtures/legacy-strategic.json"
 var hash_before=FileAccess.get_sha256(path)
 c=Campaign.new()
 test.check(c.load_from(path) and c.s.version==2 and Data.weapon(c.s.mercs.mara)=="sword" and c.s.stash.size()==5,"Previous-release strategic save migrates to item instances")
 test.check(FileAccess.get_sha256(path)==hash_before,"Loading a legacy save leaves the original file unchanged")
 test.check(Items.ownership_error(c.s)=="","Migrated strategic save has valid unique item ownership")
 test.check(c.load_from("res://tests/fixtures/legacy-tactical.json") and c.battle!=null,"Previous-release active battle migrates and resumes")
 test.check(c.battle.unit("mara").x==4 and c.battle.unit("mara").y==3 and Data.condition(c.s.mercs.mara)==63,"Migration preserves legacy position and weapon condition")
 c.battle.unit("hostile_0").person.hp=31
 test.check(c.s.groups[0].fighters[0].hp==31,"Migrated hostile profile is shared with its strategic group")
 test.check(c.save_to("user://migrated-v2.json"),"Migrated legacy battle can be saved in schema 2")
 loaded=Campaign.new()
 test.check(loaded.load_from("user://migrated-v2.json") and JSON.stringify(loaded.s)==JSON.stringify(c.s),"Migrated schema-2 state roundtrips without creating new item identities")
 test.check(c.load_from("res://tests/fixtures/legacy-corpse.json") and Items.ownership_error(c.s)=="","Legacy corpse inventory and old ground loot migrate without duplicate ownership")
 var corpse=c.battle.unit("hostile_0")
 var corpse_weapon=c.battle.t.ground[0].item
 test.check(corpse.person.hp==0 and Items.find(corpse.person.inventory,corpse_weapon.id).is_empty() and not corpse.person.equipment.has("weapon"),"Legacy corpse weapon becomes the same unique ground item with no ghost equipment")
 c=Campaign.new()
 c.group_losses(c.s.groups[0],1)
 c.record_group_losses(c.s.groups[0])
 c.group_losses(c.s.groups[0],1)
 c.record_group_losses(c.s.groups[0])
 test.check(c.s.factions.bandits.losses==2,"Repeated force resolution counts each casualty once")
