extends RefCounted
const Data = preload("res://sim/catalog.gd")
const Battle = preload("res://sim/tactical.gd")
var s: Dictionary
var battle = null
var error = ""
var autosave_path="user://autosave.json"

func _init(seed_value: int = 731) -> void:
 s = {"version":1,"seed":seed_value,"rng":seed_value,"time":480,"funds":1200,"food":60,"medicine":12,"tools":12,
 "mercs":{},"squads":{},"sectors":[],"jobs":[],"events":[],"ledger":[],"groups":[],"factions":{},
 "stash":["sword","bow","spear","shield","mail"],"log":[],"next_event":1,"encounter":{},"battle":{},"result":{}}
 for y in range(16):
  for x in range(16):
   var terrain = ["grass","forest","hills","marsh"][(x * 7 + y * 11) % 4]
   if x == 1 or y == 2: terrain = "road"
   s.sectors.append({"id":y*16+x,"x":x,"y":y,"terrain":terrain,"owner":"free","known":false,
    "facility":"","loyalty":70,"order":80,"garrison":0,"training":0,"name":"March %d:%d" % [x+1,y+1],"cleared":false})
 s.sectors[17].merge({"name":"Ashford market","owner":"company","facility":"market","known":true},true)
 s.sectors[34].merge({"name":"Redbank farm","owner":"bandits","facility":"farm","known":true},true)
 s.sectors[36].merge({"name":"Iron Hollow","owner":"bandits","facility":"mine","known":true},true)
 s.sectors[49].merge({"name":"Willow workshop","owner":"free","facility":"workshop","known":true},true)
 s.sectors[65].merge({"name":"Greywatch","owner":"nobles","facility":"garrison","known":true},true)
 s.sectors[81].merge({"name":"Old drill yard","owner":"free","facility":"training","known":true},true)
 for f in ["company","bandits","nobles","free"]:
  s.factions[f] = {"id":f,"resources":100,"losses":0}
 s.groups = [{"id":"raiders","faction":"bandits","sector":34,"strength":2,"objective":17},
 {"id":"mine_guard","faction":"bandits","sector":36,"strength":3,"objective":36},
 {"id":"grey_patrol","faction":"nobles","sector":65,"strength":3,"objective":34}]
 var profiles = [["mara","Mara","soldier","sword"],["oswin","Oswin","hunter","bow"],
 ["ada","Ada","physician","spear"],["bram","Bram","smith","mace"],["elin","Elin","knight","sword"],["tom","Tom","farmer","crossbow"]]
 for entry in profiles:
  var p = Data.person(entry[0],entry[1],entry[2],entry[3])
  s.mercs[p.id] = p
 for id in ["mara","oswin"]:
  s.mercs[id].hired = true
  s.mercs[id].expires = s.time + 7*1440
 s.mercs.mara.shield = true
 s.mercs.mara.inventory.append("shield")
 s.squads["first"] = {"id":"first","name":"First company","members":["mara","oswin"],"leader":"mara","sector":17,"route":[],"due":0,"assignment":"rest"}
 for entry in [["redbank","Clear Redbank",34,450],["iron","Take Iron Hollow",36,650]]:
  s.jobs.append({"id":entry[0],"name":entry[1],"sector":entry[2],"reward":entry[3],"deadline":s.time+5*1440,"status":"available","type":"capture"})
 schedule(540,"hour",{})
 for id in ["mara","oswin"]: schedule(s.mercs[id].expires,"employment",{"id":id})
 for j in s.jobs: schedule(j.deadline,"deadline",{"id":j.id})
 record(0,"Company charter")
 note("Hire, equip and accept Redbank. Select sector 3:3, plot route, then advance time.")

func note(message: String) -> void:
 s.log.append(message)
 if s.log.size() > 60: s.log.pop_front()

func record(amount: int, reason: String) -> void:
 s.funds += amount
 s.ledger.append({"time":s.time,"amount":amount,"reason":reason,"balance":s.funds})

func schedule(at: int, kind: String, payload: Dictionary) -> void:
 s.events.append({"id":s.next_event,"at":at,"kind":kind,"payload":payload})
 s.next_event += 1
 s.events.sort_custom(func(a,b): return a.at < b.at or (a.at == b.at and a.id < b.id))

func roll(limit: int) -> int:
 s.rng = (int(s.rng)*48271) % 2147483647
 return int(s.rng) % limit

func reject(message: String) -> bool:
 error = message
 return false

func command(kind: String, p: Dictionary = {}) -> bool:
 error = ""
 match kind:
  "hire":
   if battle != null: return reject("Resolve battle first")
   if not s.mercs.has(p.get("id","")): return reject("Unknown recruit")
   var m = s.mercs[p.id]
   var q = s.squads.get(p.get("squad","first"),{})
   if m.hired or m.dead or s.funds < m.fee or q.is_empty() or q.sector != 17 or not q.route.is_empty(): return reject("Recruit at Ashford with sufficient funds")
   record(-m.fee,"Hire " + m.name)
   m.hired = true
   m.expires = s.time + 7*1440
   schedule(m.expires,"employment",{"id":m.id})
   q.members.append(m.id)
   note(m.name + " hired for seven days")
  "dismiss":
   if battle != null: return reject("Cannot dismiss during combat")
   if not s.mercs.has(p.id) or not s.mercs[p.id].hired: return reject("Not employed")
   remove_member(p.id)
  "accept":
   for j in s.jobs:
    if j.id == p.id and j.status == "available" and j.deadline > s.time:
     j.status = "active"
     note("Accepted: " + j.name)
     return true
   return reject("Job unavailable")
  "buy":
   if battle != null: return reject("Market inaccessible in battle")
   var q = s.squads.get(p.get("squad","first"),{})
   if q.is_empty() or s.sectors[q.sector].facility != "market" or not q.route.is_empty(): return reject("Visit a market")
   var item = p.item
   var price = 0
   if Data.WEAPONS.has(item): price = Data.WEAPONS[item].price
   elif Data.ARMOUR.has(item): price = Data.ARMOUR[item].price
   elif item in ["food","medicine","tools","ammo","shield","helmet"]: price = {"food":20,"medicine":30,"tools":25,"ammo":15,"shield":65,"helmet":45}[item]
   else: return reject("Unknown item")
   if s.funds < price: return reject("Insufficient funds")
   record(-price,"Purchase " + item)
   if item == "food": s.food += 20
   elif item == "medicine": s.medicine += 5
   elif item == "tools": s.tools += 5
   elif item == "ammo": s.stash.append("ammo")
   else: s.stash.append(item)
  "equip":
   if not s.mercs.has(p.id) or not s.mercs[p.id].hired or not s.stash.has(p.item): return reject("Item unavailable")
   var m = s.mercs[p.id]
   var u = null if battle == null else battle.unit(p.id)
   if battle != null and (u == null or not battle.can_act(u) or u.ap < 3): return reject("Need 3 AP to change equipment")
   var item = p.item
   if Data.WEAPONS.has(item):
    if item in ["greatsword","polearm","bow","crossbow"] and m.shield: return reject("Remove shield before two handed weapon")
    s.stash.append(m.weapon)
    m.inventory.erase(m.weapon)
    m.weapon = item
    m.loaded = false
   elif Data.ARMOUR.has(item):
    if battle != null: return reject("Change armour outside battle")
    s.stash.append(m.armour)
    m.inventory.erase(m.armour)
    m.armour = item
   elif item == "shield":
    if m.shield or m.weapon in ["greatsword","polearm","bow","crossbow"]: return reject("Shield incompatible")
    m.shield = true
   elif item == "helmet":
    if m.helmet: return reject("Helmet already equipped")
    m.helmet = true
   elif item == "ammo": m.ammo += 16
   else: return reject("Cannot equip this item")
   s.stash.erase(item)
   if item != "ammo": m.inventory.append(item)
   if u != null: u.ap -= 3
  "assignment":
   if battle != null: return reject("Resolve battle first")
   if not p.value in ["rest","medical","training","repair","guard","scout","garrison"]: return reject("Unknown assignment")
   if not s.mercs.has(p.id) or not s.mercs[p.id].hired: return reject("Not employed")
   s.mercs[p.id].assignment = p.value
  "renew":
   if battle != null: return reject("Resolve battle first")
   var m=s.mercs.get(p.get("id",""),{})
   if m.is_empty() or not m.hired or s.funds<m.wage*7: return reject("Need an employed fighter and seven days wages")
   record(-m.wage*7,"Renew "+m.name)
   m.expires=maxi(m.expires,s.time)+7*1440
   schedule(m.expires,"employment",{"id":m.id})
  "unequip_shield":
   var m=s.mercs.get(p.get("id",""),{})
   if m.is_empty() or not m.hired or not m.shield: return reject("No shield equipped")
   if battle != null: return reject("Remove shield outside combat")
   m.shield=false
   m.inventory.erase("shield")
   s.stash.append("shield")
  "split":
   if battle != null: return reject("Resolve battle first")
   var q = s.squads.get(p.get("squad","first"),{})
   if q.is_empty() or q.members.size() < 2 or not p.id in q.members or not q.route.is_empty(): return reject("Split a stationary squad with two members")
   var id = "squad_" + p.id
   if s.squads.has(id): return reject("Squad already exists")
   q.members.erase(p.id)
   if q.leader == p.id: q.leader = q.members[0]
   s.squads[id] = {"id":id,"name":s.mercs[p.id].name+" squad","members":[p.id],"leader":p.id,"sector":q.sector,"route":[],"due":0,"assignment":"rest"}
  "merge":
   if battle != null: return reject("Resolve battle first")
   var a = s.squads.get(p.get("from",""),{})
   var b = s.squads.get(p.get("to","first"),{})
   if a.is_empty() or b.is_empty() or a.id == b.id or a.sector != b.sector or not a.route.is_empty() or not b.route.is_empty(): return reject("Merge stationary squads in same sector")
   b.members.append_array(a.members)
   s.squads.erase(a.id)
  "route":
   if battle != null or not s.encounter.is_empty(): return reject("Resolve encounter first")
   var q = s.squads.get(p.get("squad","first"),{})
   if q.is_empty() or q.members.is_empty() or not q.route.is_empty(): return reject("Squad unavailable")
   if p.sector < 0 or p.sector >= 256: return reject("Invalid destination")
   var route = strategic_path(q.sector,p.sector,q)
   if route.is_empty(): return reject("Already there or no route")
   q.route = route
   q.due = s.time + travel_cost(q,route[0])
   schedule(q.due,"arrival",{"squad":q.id})
   note("Route plotted: %d sectors" % route.size())
  "advance": return advance(p.get("minutes",60))
  "enter":
   if s.encounter.is_empty() or battle != null: return reject("No encounter")
   battle = Battle.new(self)
   s.battle = battle.t
  "resolve": return resolve_battle(false)
  "retreat": return resolve_battle(true)
  "levy":
   if battle != null: return reject("Resolve battle first")
   var sector = s.sectors[p.sector]
   if sector.owner != "company" or s.funds < 80: return reject("Need owned sector and 80 crowns")
   record(-80,"Recruit levy")
   sector.garrison += 1
  "save": return save_to(p.get("path","user://campaign.json"))
  "load": return load_from(p.get("path","user://campaign.json"))
  _: return reject("Unknown command: " + kind)
 return true

func remove_member(id: String) -> void:
 s.mercs[id].hired = false
 for q in s.squads.values():
  q.members.erase(id)
  if q.leader == id: q.leader = "" if q.members.is_empty() else q.members[0]
  if q.members.is_empty(): q.route = []

func neighbors(index: int) -> Array:
 var out = []
 for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
  var x = index % 16 + d.x
  var y = int(index / 16) + d.y
  if x >= 0 and x < 16 and y >= 0 and y < 16: out.append(y*16+x)
 return out

func travel_cost(q: Dictionary, sector: int) -> int:
 var cost = {"road":45,"grass":70,"forest":100,"hills":115,"marsh":140}[s.sectors[sector].terrain]
 var burden = 1.0
 for id in q.members:
  var m = s.mercs[id]
  burden = maxf(burden,1.0+m.fatigue/150.0+(1.0-m.hp/float(m.max_hp))*0.7+maxf(0,Data.weight(m)-m.strength/4.0)/30.0)
 if s.food <= 0: burden *= 1.3
 return int(ceil(cost*burden))

func strategic_path(start: int, goal: int, q: Dictionary) -> Array:
 var open = [start]
 var cost = {start:0}
 var prev = {}
 while not open.is_empty():
  open.sort_custom(func(a,b): return cost[a]<cost[b])
  var at = open.pop_front()
  if at == goal:
   var route = []
   while at != start:
    route.push_front(at)
    at = prev[at]
   return route
  for n in neighbors(at):
   var v = cost[at]+travel_cost(q,n)
   if not cost.has(n) or v<cost[n]:
    cost[n]=v
    prev[n]=at
    if not n in open: open.append(n)
 return []

func advance(minutes: int) -> bool:
 if minutes <= 0 or minutes > 43200: return reject("Advance 1 to 43200 minutes")
 if battle != null or not s.encounter.is_empty(): return reject("Time paused by encounter")
 var target = s.time+minutes
 while not s.events.is_empty() and s.events[0].at <= target:
  var event = s.events.pop_front()
  s.time = event.at
  if event.kind == "hour":
   hourly()
   schedule(s.time+60,"hour",{})
  elif event.kind == "arrival": arrive(event.payload.squad)
  elif event.kind == "employment":
   var m=s.mercs.get(event.payload.id,{})
   if not m.is_empty() and m.hired and m.expires<=s.time:
    remove_member(m.id)
    note(m.name+" contract expired")
  elif event.kind == "deadline":
   for j in s.jobs:
    if j.id==event.payload.id and j.status in ["active","available"] and j.deadline<=s.time:
     j.status="failed"
     note(j.name+" deadline missed")
  if not s.encounter.is_empty(): return true
 s.time = target
 return true

func hourly() -> void:
 var active = []
 for m in s.mercs.values():
  if m.hired and not m.dead: active.append(m)
 var need = active.size()
 var shortage = s.food < need
 s.food = maxi(0,s.food-need)
 for m in active:
  var moving = false
  var local_sector=s.sectors[17]
  for q in s.squads.values():
   if m.id in q.members:
    local_sector=s.sectors[q.sector]
    if not q.route.is_empty(): moving = true
  m.fatigue = clampi(m.fatigue+(maxi(2,8-int(m.endurance/20)) if moving else -8),0,100)
  if shortage:
   m.morale = maxi(0,m.morale-5)
   m.fatigue = mini(100,m.fatigue+8)
  if not moving:
   match m.assignment:
    "medical":
     if s.medicine > 0 and m.hp < m.max_hp:
      s.medicine -= 1
      var medic = m.medical
      for other in active: medic = maxi(medic,other.medical)
      m.hp = mini(m.max_hp,m.hp+2+int(medic/15))
      m.bleeding = 0
      m.wounds = maxi(0,m.wounds-1)
    "training":
     m.training += 1+int(m.wisdom/40)+(2 if local_sector.facility=="training" else 0)
     if m.training >= 12:
      m.training -= 12
      m.melee = mini(95,m.melee+1)
    "repair":
     if s.tools > 0 and m.condition < 100:
      s.tools -= 1
      m.condition = mini(100,m.condition+2+int(m.smithing/10)+(4 if local_sector.facility=="workshop" else 0))
    "rest":
     if m.bleeding == 0: m.hp = mini(m.max_hp,m.hp+1)
    "guard":
     if local_sector.owner=="company": local_sector.order=mini(100,local_sector.order+1)
    "scout":
     local_sector.known=true
     for n in neighbors(local_sector.id):
      s.sectors[n].known=true
      if m.perception>=75:
       for far in neighbors(n): s.sectors[far].known=true
    "garrison":
     if local_sector.owner=="company" and local_sector.garrison>0:
      local_sector.training=mini(100,local_sector.training+1+int(m.leadership/25))
  if m.bleeding > 0:
   m.hp = maxi(0,m.hp-m.bleeding)
   if m.hp == 0:
    m.dead = true
    remove_member(m.id)
    note(m.name+" died of untreated wounds")
  if m.hired and m.expires <= s.time:
   remove_member(m.id)
   note(m.name+" contract expired")
 for j in s.jobs:
  if j.status in ["active","available"] and s.time >= j.deadline:
   j.status = "failed"
   note(j.name+" deadline missed")
 if int(s.time)%1440 == 0: daily()

func daily() -> void:
 var wages = 0
 for m in s.mercs.values():
  if m.hired: wages += m.wage
 for sector in s.sectors:
  if sector.owner != "company": continue
  wages += sector.garrison*3
  var output = sector.loyalty*sector.order/10000.0
  if sector.facility == "farm": s.food += int(50*output)
  if sector.facility == "mine": record(int(100*output),"Iron production")
  if sector.garrison > 0: sector.training = mini(100,sector.training+3)
 record(-wages,"Daily wages and levy upkeep")
 if s.funds < 0:
  for m in s.mercs.values():
   if m.hired: m.morale = maxi(0,m.morale-15)
  note("Wage arrears damage morale")
 else:
  for q in s.squads.values():
   if not q.members.is_empty() and s.mercs.has(q.leader):
    for id in q.members: s.mercs[id].morale=mini(100,s.mercs[id].morale+1+int(s.mercs[q.leader].leadership/25))
 faction_tick()

func faction_tick() -> void:
 for g in s.groups:
  if g.strength <= 0: continue
  var target = g.objective
  if s.sectors[g.sector].owner != g.faction:
   target = g.sector
  elif g.sector == target:
   target = 17 if g.faction == "bandits" else 34
  var best = g.sector
  var distance = 999
  for n in neighbors(g.sector):
   var d = absi(n%16-int(target)%16)+absi(int(n/16)-int(target/16))
   if d < distance:
    best=n
    distance=d
  if target != g.sector: g.sector=best
  var sector = s.sectors[g.sector]
  for q in s.squads.values():
   if q.sector == g.sector and not q.members.is_empty():
    encounter(q,g.sector)
    return
  if sector.owner != g.faction:
   var defence = sector.garrison * (1.0+sector.training/100.0)
   if g.strength > defence:
    g.strength = maxi(1,g.strength-int(defence))
    sector.garrison=0
    sector.owner=g.faction
    note(g.faction+" captured "+sector.name)
   else:
    sector.garrison=maxi(0,sector.garrison-int(ceil(g.strength/2.0)))
    g.strength=0

func arrive(id: String) -> void:
 if not s.squads.has(id): return
 var q = s.squads[id]
 if q.route.is_empty() or q.members.is_empty(): return
 q.sector = q.route.pop_front()
 s.sectors[q.sector].known = true
 for n in neighbors(q.sector): s.sectors[n].known=true
 note(q.name+" arrived at "+s.sectors[q.sector].name)
 for g in s.groups:
  if g.sector == q.sector and g.strength > 0 and g.faction != "company":
   q.route=[]
   encounter(q,q.sector)
   return
 if not q.route.is_empty():
  q.due=s.time+travel_cost(q,q.route[0])
  schedule(q.due,"arrival",{"squad":id})

func encounter(q: Dictionary, sector: int) -> void:
 s.encounter={"squad":q.id,"sector":sector,"from":17}
 q.route=[]
 note("Hostile contact. Time paused. Deploy or withdraw.")

func resolve_battle(retreat: bool) -> bool:
 if battle == null: return reject("No battle")
 var outcome = battle.outcome()
 if not retreat and outcome == "ongoing": return reject("Battle still active")
 var q = s.squads[s.encounter.squad]
 var sector = s.sectors[s.encounter.sector]
 var victory = not retreat and outcome == "victory"
 for u in battle.t.units:
  if u.team != "company": continue
  if u.person.hp <= 0:
   u.person.dead=true
   remove_member(u.id)
  u.person.morale=clampi(u.person.morale+(8 if victory else -15),0,100)
 if victory:
  sector.owner="company"
  sector.cleared=true
  for g in s.groups:
   if g.sector == sector.id and g.faction != "company":
    s.factions[g.faction].losses += g.strength
    g.strength=0
  for item in battle.t.ground: s.stash.append(item.item)
  for j in s.jobs:
   if j.status == "active" and j.sector == sector.id and s.time <= j.deadline:
    j.status="paid"
    record(j.reward,"Contract: "+j.name)
 else:
  q.sector=17
 s.result={"outcome":"victory" if victory else ("retreat" if retreat else "defeat"),"sector":sector.name,"survivors":q.members.size()}
 note("Battle "+s.result.outcome+" at "+sector.name)
 battle=null
 s.battle={}
 s.encounter={}
 save_to(autosave_path)
 return true

func save_to(path: String) -> bool:
 if battle != null: s.battle=battle.t
 var f = FileAccess.open(path+".tmp",FileAccess.WRITE)
 if f == null: return reject("Cannot write save")
 f.store_string(JSON.stringify(s))
 f.flush()
 f.close()
 var absolute = ProjectSettings.globalize_path(path)
 if FileAccess.file_exists(path):
  var parser=JSON.new()
  if parser.parse(FileAccess.get_file_as_string(path))==OK and valid_save(parser.data):
   var backup_error = DirAccess.copy_absolute(absolute,absolute+".bak")
   if backup_error != OK: return reject("Cannot back up save")
 var code = DirAccess.rename_absolute(absolute+".tmp",absolute)
 return true if code == OK else reject("Cannot commit save")

func load_from(path: String) -> bool:
 var data = null
 for candidate in [path,path+".bak"]:
  if FileAccess.file_exists(candidate):
   var parser=JSON.new()
   var parsed=parser.parse(FileAccess.get_file_as_string(candidate))
   data=parser.data if parsed==OK else null
   if valid_save(data): break
 if not valid_save(data): return reject("Save invalid or unsupported version")
 s=normalize_numbers(data)
 battle=null
 if not s.battle.is_empty():
  battle=Battle.new(self,s.battle)
  # Rebind authoritative mercenary references after JSON decoding.
  for u in battle.t.units:
   if u.team == "company": u.person=s.mercs[u.id]
 return true

func valid_save(data: Variant) -> bool:
 if not data is Dictionary: return false
 for key in ["version","sectors","mercs","squads","events","rng","time","battle","encounter","funds","jobs","ledger","stash","groups","factions","food","medicine","tools","log","next_event","result"]:
  if not data.has(key): return false
 if data.version!=1 or not data.sectors is Array or data.sectors.size()!=256 or not data.mercs is Dictionary or not data.squads is Dictionary: return false
 if not data.events is Array or not data.battle is Dictionary or not data.encounter is Dictionary: return false
 if not (data.time is int or data.time is float) or not (data.rng is int or data.rng is float): return false
 if data.time<0 or data.rng<=0 or data.rng>=2147483647: return false
 for sector in data.sectors:
  if not sector is Dictionary: return false
  for key in ["id","x","y","owner","facility","terrain","known","garrison","loyalty","order","training","name"]:
   if not sector.has(key): return false
 for m in data.mercs.values():
  if not m is Dictionary: return false
  for key in Data.person("validation","validation","soldier","sword"):
   if not m.has(key): return false
  if not Data.WEAPONS.has(m.weapon) or not Data.ARMOUR.has(m.armour): return false
 for q in data.squads.values():
  if not q is Dictionary: return false
  for key in ["id","members","leader","sector","route","due","assignment","name"]:
   if not q.has(key): return false
  if not q.members is Array or not q.route is Array or q.sector<0 or q.sector>=256: return false
  for id in q.members:
   if not data.mercs.has(id): return false
 for event in data.events:
  if not event is Dictionary or not event.has_all(["id","at","kind","payload"]): return false
 if not data.battle.is_empty():
  if not data.battle.has_all(["units","tiles","width","height","turn","round","knowledge","log","ai","noise","ground"]): return false
  if data.battle.tiles.size()!=int(data.battle.width)*int(data.battle.height): return false
  if not data.encounter.has_all(["squad","sector"]) or not data.squads.has(data.encounter.squad): return false
 return true

func normalize_numbers(value: Variant) -> Variant:
 if value is float and value==floor(value): return int(value)
 if value is Array:
  for i in range(value.size()): value[i]=normalize_numbers(value[i])
 elif value is Dictionary:
  for key in value: value[key]=normalize_numbers(value[key])
 return value
