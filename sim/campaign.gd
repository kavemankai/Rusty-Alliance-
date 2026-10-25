extends RefCounted
const Data = preload("res://sim/catalog.gd")
const Battle = preload("res://sim/tactical.gd")
const Items = preload("res://sim/inventory.gd")
const Schema = preload("res://sim/save_schema.gd")
const Supplies = preload("res://sim/supplies.gd")
const Garrison = preload("res://sim/garrison.gd")
const Contracts = preload("res://sim/contracts.gd")
var s: Dictionary
var battle = null
var error = ""
var autosave_path="user://autosave.json"

func _init(seed_value: int = 731) -> void:
 s = {"version":3,"next_item":1,"next_levy":1,"stash_sector":17,"pending_encounters":[],"seed":seed_value,"rng":seed_value,"time":480,"funds":1200,
 "mercs":{},"squads":{},"sectors":[],"jobs":[],"events":[],"ledger":[],"groups":[],"factions":{},
 "stash":["sword","bow","spear","shield","mail"],"log":[],"next_event":1,"encounter":{},"battle":{},"result":{}}
 for y in range(16):
  for x in range(16):
   var terrain = ["grass","forest","hills","marsh"][(x * 7 + y * 11) % 4]
   if x == 1 or y == 2: terrain = "road"
   s.sectors.append({"id":y*16+x,"x":x,"y":y,"terrain":terrain,"owner":"free","known":false,
    "facility":"","loyalty":70,"order":80,"levies":[],"supplies":Supplies.empty(),"training":0,"name":"March %d:%d" % [x+1,y+1],"cleared":false})
 s.sectors[17].merge({"name":"Ashford market","owner":"company","facility":"market","known":true},true)
 s.sectors[34].merge({"name":"Redbank farm","owner":"bandits","facility":"farm","known":true},true)
 s.sectors[36].merge({"name":"Iron Hollow","owner":"bandits","facility":"mine","known":true},true)
 s.sectors[49].merge({"name":"Willow workshop","owner":"free","facility":"workshop","known":true},true)
 s.sectors[65].merge({"name":"Greywatch","owner":"nobles","facility":"garrison","known":true},true)
 s.sectors[52].merge({"name":"Briar camp","owner":"bandits","facility":"camp","known":true},true)
 s.sectors[81].merge({"name":"Old drill yard","owner":"free","facility":"training","known":true},true)
 for f in ["company","bandits","nobles","free"]:
  s.factions[f] = {"id":f,"resources":100,"losses":0}
 s.groups = [{"id":"raiders","faction":"bandits","sector":34,"strength":2,"objective":17},
 {"id":"mine_guard","faction":"bandits","sector":36,"strength":3,"objective":36},
 {"id":"grey_patrol","faction":"nobles","sector":65,"strength":3,"objective":34},
 {"id":"briar_guard","faction":"bandits","sector":52,"strength":2,"objective":52,"stationary":true}]
 var profiles = [["mara","Mara","soldier","sword"],["oswin","Oswin","hunter","bow"],
 ["ada","Ada","physician","spear"],["bram","Bram","smith","mace"],["elin","Elin","knight","sword"],["tom","Tom","farmer","crossbow"]]
 for entry in profiles:
  var p = Data.person(entry[0],entry[1],entry[2],entry[3])
  s.mercs[p.id] = p
 for id in ["mara","oswin"]:
  s.mercs[id].hired = true
  s.mercs[id].expires = s.time + 7*1440
 var shield=Items.create(s,"shield")
 s.mercs.mara.inventory.append(shield)
 s.mercs.mara.equipment.shield=shield.id
 var stash=[]
 for kind in s.stash: stash.append(Items.create(s,kind))
 s.stash=stash
 ensure_group_rosters()
 s.squads["first"] = {"id":"first","name":"First company","members":["mara","oswin"],"leader":"mara","sector":17,"route":[],"due":0,"assignment":"rest","supplies":{"food":60,"medicine":12,"tools":12}}
 for entry in [["redbank","Clear Redbank",34,450],["iron","Take Iron Hollow",36,650]]:
  s.jobs.append({"id":entry[0],"name":entry[1],"sector":entry[2],"reward":entry[3],"deadline":s.time+5*1440,"status":"available","type":"capture"})
 Contracts.seed_board(self)
 Contracts.normalize(s)
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
   if m.hired or m.dead or m.get("captured",false) or s.funds < m.fee or q.is_empty() or q.sector != 17 or not q.route.is_empty(): return reject("Recruit an available fighter at Ashford with sufficient funds")
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
  "accept": return Contracts.accept(self,p.get("id",""),p.get("squad","first"))
  "repost": return Contracts.repost(self,p.get("id",""))
  "buy":
   if battle != null: return reject("Market inaccessible in battle")
   var q = s.squads.get(p.get("squad","first"),{})
   if q.is_empty() or q.sector!=s.stash_sector or s.sectors[q.sector].facility != "market" or not q.route.is_empty(): return reject("Visit the Ashford market")
   var item = p.item
   var price = 0
   if Data.WEAPONS.has(item): price = Data.WEAPONS[item].price
   elif Data.ARMOUR.has(item): price = Data.ARMOUR[item].price
   elif item in ["food","medicine","tools","ammo","shield","helmet"]: price = {"food":20,"medicine":30,"tools":25,"ammo":15,"shield":65,"helmet":45}[item]
   else: return reject("Unknown item")
   if s.funds < price: return reject("Insufficient funds")
   record(-price,"Purchase " + item)
   if item == "food": q.supplies.food += 20
   elif item == "medicine": q.supplies.medicine += 5
   elif item == "tools": q.supplies.tools += 5
   else: s.stash.append(Items.create(s,item,16 if item=="ammo" else 1))
  "equip":
   var invalid=Items.equip(self,p)
   if invalid!="": return reject(invalid)
  "transfer":
   var invalid=Items.transfer(self,p)
   if invalid!="": return reject(invalid)
  "supply_transfer":
   var invalid=Supplies.transfer(self,p)
   if invalid!="": return reject(invalid)
  "unequip", "unequip_shield":
   var invalid=Items.unequip(self,p)
   if invalid!="": return reject(invalid)
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
  "split":
   if battle != null: return reject("Resolve battle first")
   var q = s.squads.get(p.get("squad","first"),{})
   if q.is_empty() or q.members.size() < 2 or not p.id in q.members or not q.route.is_empty(): return reject("Split a stationary squad with two members")
   var id = "squad_" + p.id
   if s.squads.has(id): return reject("Squad already exists")
   var provisions=Supplies.split(q.supplies,q.members.size())
   q.members.erase(p.id)
   if q.leader == p.id: q.leader = q.members[0]
   s.squads[id] = {"id":id,"name":s.mercs[p.id].name+" squad","members":[p.id],"leader":p.id,"sector":q.sector,"route":[],"due":0,"assignment":"rest","supplies":provisions}
  "merge":
   if battle != null: return reject("Resolve battle first")
   var a = s.squads.get(p.get("from",""),{})
   var b = s.squads.get(p.get("to","first"),{})
   if a.is_empty() or b.is_empty() or a.id == b.id or a.sector != b.sector or not a.route.is_empty() or not b.route.is_empty(): return reject("Merge stationary squads in same sector")
   b.members.append_array(a.members)
   Supplies.combine(a.supplies,b.supplies)
   s.squads.erase(a.id)
  "route":
   if battle != null or not s.encounter.is_empty(): return reject("Resolve encounter first")
   var q = s.squads.get(p.get("squad","first"),{})
   if q.is_empty() or q.members.is_empty() or not q.route.is_empty(): return reject("Squad unavailable")
   if p.sector < 0 or p.sector >= 256: return reject("Invalid destination")
   var route = strategic_path(q.sector,p.sector,q)
   if route.is_empty(): return reject("Already there or no route")
   q.route = route
   schedule_arrival(q)
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
   if sector.owner != "company" or s.funds < 80 or Garrison.living(sector)>=12 or not s.encounter.is_empty(): return reject("Need a peaceful owned sector, fewer than 12 levies and 80 crowns")
   record(-80,"Recruit levy")
   Garrison.create(s,sector)
  "save": return save_to(p.get("path","user://campaign.json"))
  "load": return load_from(p.get("path","user://campaign.json"))
  _: return reject("Unknown command: " + kind)
 Contracts.tick(self)
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
 var freight=0
 for j in s.jobs:
  if j.type=="escort" and j.status=="active" and j.squad==q.id: freight+=j.cargo
 var pack_weight=(Supplies.carried_weight(q.supplies)+freight*0.1)/maxi(1,q.members.size())
 burden+=pack_weight/60.0
 if q.supplies.food <= 0: burden *= 1.3
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
  elif event.kind == "arrival": arrive(event.payload.squad,event.payload.get("token",-1))
  elif event.kind == "employment":
   var m=s.mercs.get(event.payload.id,{})
   if not m.is_empty() and m.hired and m.expires<=s.time:
    remove_member(m.id)
    note(m.name+" contract expired")
  elif event.kind == "deadline": Contracts.tick(self)
  Contracts.tick(self)
  if not s.encounter.is_empty(): return true
 s.time = target
 Contracts.tick(self)
 return true

func medical_skill_at(index: int) -> int:
 var skill=-1
 for q in s.squads.values():
  if q.sector!=index or not q.route.is_empty(): continue
  for id in q.members:
   var p=s.mercs[id]
   if p.hired and p.hp>10 and not p.get("captured",false): skill=maxi(skill,p.medical)
 if s.sectors[index].owner=="company":
  for p in s.sectors[index].levies:
   if p.hp>10 and not p.get("captured",false): skill=maxi(skill,p.medical)
 return skill

func hourly() -> void:
 var active = []
 for m in s.mercs.values():
  if m.hired and not m.dead: active.append(m)
 var shortages={}
 for q in s.squads.values():
  var need=0
  for id in q.members:
   if s.mercs[id].hired and s.mercs[id].hp>0: need+=1
  shortages[q.id]=q.supplies.food<need
  q.supplies.food=maxi(0,q.supplies.food-need)
 for m in active:
  var own_squad=Supplies.squad_for(s,m.id)
  var provisions=Supplies.for_person(s,m.id)
  var shortage=shortages.get(own_squad.get("id",""),true)
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
     if provisions.get("medicine",0)>0 and (m.hp<m.max_hp or m.bleeding>0):
      var medic=medical_skill_at(local_sector.id)
      if medic>=0:
       provisions.medicine-=1
       m.hp = mini(m.max_hp,m.hp+2+int(medic/15))
       m.bleeding = 0
       m.wounds = maxi(0,m.wounds-1)
    "training":
     m.training += 1+int(m.wisdom/40)+(2 if local_sector.facility=="training" else 0)
     if m.training >= 12:
      m.training -= 12
      m.melee = mini(95,m.melee+1)
    "repair":
     for entry in m.inventory:
      if entry.kind!="ammo" and entry.condition<100 and provisions.get("tools",0)>0:
       provisions.tools-=1
       entry.condition=mini(100,entry.condition+2+int(m.smithing/10)+(4 if local_sector.facility=="workshop" else 0))
       break
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
     if local_sector.owner=="company" and Garrison.strength(local_sector)>0:
      Garrison.train(local_sector,1+int(m.leadership/25))
  if m.bleeding > 0:
   m.hp = maxi(0,m.hp-m.bleeding)
   if m.hp == 0:
    m.dead = true
    remove_member(m.id)
    note(m.name+" died of untreated wounds")
  if m.hired and m.expires <= s.time:
   remove_member(m.id)
   note(m.name+" contract expired")
 for sector in s.sectors:
  if sector.owner!="company": continue
  var need=Garrison.living(sector)
  var shortage=sector.supplies.food<need
  sector.supplies.food=maxi(0,sector.supplies.food-need)
  for levy in sector.levies:
   if levy.hp<=0 or levy.get("captured",false): continue
   levy.fatigue=maxi(0,levy.fatigue-8)
   if shortage:
    levy.morale=maxi(0,levy.morale-5)
    levy.fatigue=mini(100,levy.fatigue+8)
   var medic=medical_skill_at(sector.id)
   if levy.bleeding>0 and sector.supplies.medicine>0 and medic>=0:
    sector.supplies.medicine-=1
    levy.bleeding=0
    levy.hp=mini(levy.max_hp,levy.hp+2+int(medic/15))
    levy.wounds=maxi(0,levy.wounds-1)
   elif levy.bleeding>0:
    levy.hp=maxi(0,levy.hp-levy.bleeding)
    if levy.hp==0: levy.dead=true
   else: levy.hp=mini(levy.max_hp,levy.hp+1)
 if int(s.time)%1440 == 0: daily()
 Contracts.tick(self)

func daily() -> void:
 var wages = 0
 for m in s.mercs.values():
  if m.hired: wages += m.wage
 for sector in s.sectors:
  if sector.owner != "company": continue
  wages += Garrison.living(sector)*3
  var output = sector.loyalty*sector.order/10000.0
  if sector.facility == "farm": sector.supplies.food += int(50*output)
  if sector.facility == "mine": record(int(100*output),"Iron production")
  if Garrison.strength(sector)>0: Garrison.train(sector,3)
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

func ensure_group_rosters() -> void:
 for g in s.groups:
  if not g.has("fighters"):
   g.fighters=[]
   for index in range(g.get("strength",0)):
    var id=g.id+"_fighter_%d" % index
    var p=Data.hostile(id,index)
    g.fighters.append(p)
   g.erase("strength")
  if not g.has("positions"): g.positions={}

func force_strength(g: Dictionary) -> int:
 var count=0
 for m in g.get("fighters",[]):
  if m.hp>10 and not m.get("captured",false): count+=1
 return count if g.has("fighters") else g.get("strength",0)

func group_losses(g: Dictionary,amount: int) -> void:
 for m in g.fighters:
  if amount<=0: break
  if m.hp>10 and not m.get("captured",false):
   m.hp=0
   m.dead=true
   amount-=1
 record_group_losses(g)

func record_group_losses(g: Dictionary) -> void:
 var count=0
 for m in g.fighters:
  if m.hp<=0 or m.get("captured",false): count+=1
 var fresh=maxi(0,count-g.get("losses_accounted",0))
 s.factions[g.faction].losses+=fresh
 g.losses_accounted=count

func schedule_arrival(q: Dictionary) -> void:
 q.route_token=q.get("route_token",0)+1
 q.due=s.time+travel_cost(q,q.route[0])
 schedule(q.due,"arrival",{"squad":q.id,"token":q.route_token})

func combat_squads(index: int) -> Array:
 var result=[]
 var ids=s.squads.keys()
 ids.sort()
 for id in ids:
  var q=s.squads[id]
  if q.sector==index and not q.members.is_empty() and q.route.is_empty(): result.append(q)
 return result

func hostile_at(index: int) -> bool:
 for g in s.groups:
  if g.sector==index and g.faction!="company" and force_strength(g)>0: return true
 return false

func faction_tick() -> void:
 ensure_group_rosters()
 for g in s.groups:
  if force_strength(g)<=0: continue
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
  if target != g.sector and not g.get("stationary",false):
   g.sector=best
   g.positions={}
  var sector = s.sectors[g.sector]
  var contacted=false
  for q in s.squads.values():
   if q.sector == g.sector and not q.members.is_empty():
    encounter(q,g.sector)
    contacted=true
  if contacted: continue
  if sector.owner=="company" and Garrison.strength(sector)>0:
   encounter({},sector.id)
   continue
  if sector.owner != g.faction:
   var defence = Garrison.strength(sector) * (1.0+sector.training/100.0)
   if force_strength(g) > defence:
    group_losses(g,int(defence))
    for p in sector.levies:
     if p.hp>0: p.captured=true
    sector.owner=g.faction
    note(g.faction+" captured "+sector.name)
   else:
    var casualties=int(ceil(force_strength(g)/2.0))
    for p in sector.levies:
     if p.hp>10 and not p.get("captured",false) and casualties>0:
      p.hp=0;p.dead=true;casualties-=1
    group_losses(g,force_strength(g))

 Contracts.tick(self)

func arrive(id: String,token: int=-1) -> void:
 if not s.squads.has(id): return
 var q = s.squads[id]
 if q.route.is_empty() or q.members.is_empty(): return
 if token!=-1 and (token!=q.get("route_token",0) or q.due!=s.time): return
 q.previous_sector=q.sector
 q.sector = q.route.pop_front()
 q.due=0
 s.sectors[q.sector].known = true
 for n in neighbors(q.sector): s.sectors[n].known=true
 note(q.name+" arrived at "+s.sectors[q.sector].name)
 for g in s.groups:
  if g.sector == q.sector and force_strength(g)>0 and g.faction != "company":
   q.route=[]
   encounter(q,q.sector)
   return
 Contracts.visit(self,q)
 if not q.route.is_empty():
  schedule_arrival(q)

func encounter(q: Dictionary, sector: int) -> void:
 var contact={"squad":q.get("id",""),"sector":sector,"from":q.get("previous_sector",sector)}
 for other in s.squads.values():
  if other.sector==sector and not other.members.is_empty():
   other.route=[]
   other.due=0
   other.route_token=other.get("route_token",0)+1
 if not s.encounter.is_empty():
  if s.encounter.sector==sector: return
  for queued in s.pending_encounters:
   if queued.sector==sector: return
  s.pending_encounters.append(contact)
 else: s.encounter=contact
 note("Hostile contact. Time paused. Deploy or withdraw.")

func next_encounter() -> void:
 s.encounter={}
 while not s.pending_encounters.is_empty():
  var contact=s.pending_encounters.pop_front()
  var squads=combat_squads(contact.sector)
  var defended=s.sectors[contact.sector].owner=="company" and Garrison.strength(s.sectors[contact.sector])>0
  if squads.is_empty() and not defended: continue
  if not hostile_at(contact.sector): continue
  if not squads.is_empty():
   if not s.squads.has(contact.squad) or s.squads[contact.squad] not in squads: contact.squad=squads[0].id
  else: contact.squad=""
  s.encounter=contact
  return

func retreat_options() -> Array:
 if s.encounter.is_empty(): return []
 var options=[]
 var preferred=s.encounter.get("from",-1)
 for index in neighbors(s.encounter.sector):
  if s.sectors[index].owner not in ["company","free"]: continue
  var hostile=false
  for g in s.groups:
   if g.sector==index and g.faction!="company" and force_strength(g)>0: hostile=true
  if not hostile:
   if index==preferred: options.push_front(index)
   else: options.append(index)
 return options

func drop_inventory(person: Dictionary,x: int,y: int,ground: Array) -> void:
 for entry in person.inventory: ground.append({"x":x,"y":y,"item":entry})
 person.inventory=[]
 person.equipment={}

func resolve_battle(retreat: bool) -> bool:
 if battle == null: return reject("No battle")
 var outcome = battle.outcome()
 if not retreat and outcome == "ongoing": return reject("Battle still active")
 var sector = s.sectors[s.encounter.sector]
 var victory = not retreat and outcome == "victory"
 var exits=retreat_options()
 var mobile_fighter=false
 for u in battle.t.units:
  if u.team=="company" and u.role=="merc" and u.person.hp>10: mobile_fighter=true
 if retreat and (exits.is_empty() or not mobile_fighter): return reject("Need a capable mercenary and safe adjacent withdrawal; levies defend their home")
 var participating=battle.t.squads.duplicate()
 var engaged=[]
 for u in battle.t.units:
  if u.team=="enemy" and not u.group in engaged: engaged.append(u.group)
 # The sector owns structures and uncollected items; groups own enemy profiles.
 sector.battlefield={"width":battle.t.width,"height":battle.t.height,"tiles":battle.t.tiles,"ground":battle.t.ground}
 for u in battle.t.units:
  if u.person.hp<=0 and not u.person.inventory.is_empty(): drop_inventory(u.person,u.x,u.y,battle.t.ground)
  if u.team=="enemy":
   for g in s.groups:
    if g.id==u.get("group",""): g.positions[u.id]={"x":u.x,"y":u.y}
 for u in battle.t.units:
  if u.team != "company": continue
  if u.person.hp <= 0:
   u.person.dead=true
   if u.role=="merc": remove_member(u.id)
  u.person.morale=clampi(u.person.morale+(8 if victory else -15),0,100)
 if victory:
  sector.owner="company"
  sector.cleared=true
  for g in s.groups:
   if g.sector == sector.id and g.faction != "company":
    for m in g.fighters:
     if m.hp>0:
      m.captured=true
      drop_inventory(m,g.positions.get(m.id,{"x":11,"y":6}).x,g.positions.get(m.id,{"x":11,"y":6}).y,battle.t.ground)
  # Collected loot is carried by survivors, never teleported into the base stash.
  var survivors=[]
  for u in battle.t.units:
   if u.team=="company" and u.role=="merc" and u.person.hp>0: survivors.append(u.person)
  if not survivors.is_empty():
   var index=0
   for placement in battle.t.ground:
    survivors[index%survivors.size()].inventory.append(placement.item)
    index+=1
   battle.t.ground.clear()

 else:
  if not retreat:
   for u in battle.t.units:
    if u.team=="company" and u.person.hp>0:
     u.person.captured=true
     if u.role=="merc": remove_member(u.id)
  for id in participating:
   var q=s.squads[id]
   if retreat and not q.members.is_empty():
    var preferred=q.get("previous_sector",-1)
    q.sector=preferred if preferred in exits else exits[0]
    for member in q.members: s.mercs[member].fatigue=mini(100,s.mercs[member].fatigue+10)
   elif q.members.is_empty(): Supplies.combine(q.supplies,sector.supplies)
   q.route=[]
   q.due=0
   q.route_token=q.get("route_token",0)+1
  var reserve=false
  for remaining in combat_squads(sector.id):
   for member in remaining.members:
    if s.mercs[member].hp>10: reserve=true
  if Garrison.strength(sector)==0 and not reserve:
   for g in s.groups:
    if g.sector==sector.id and g.faction!="company" and force_strength(g)>0:
     sector.owner=g.faction
     break
 for g in s.groups:
  if g.sector==sector.id and g.faction!="company": record_group_losses(g)
 Contracts.resolved(self,sector.id,victory,participating,engaged)
 var surviving=0
 for u in battle.t.units:
  if u.team=="company" and u.person.hp>0 and not u.person.get("captured",false): surviving+=1
 s.result={"outcome":"victory" if victory else ("retreat" if retreat else "defeat"),"sector":sector.name,"survivors":surviving}
 note("Battle "+s.result.outcome+" at "+sector.name)
 battle=null
 s.battle={}
 Contracts.tick(self)
 next_encounter()
 if not victory and hostile_at(sector.id):
  var reserves=combat_squads(sector.id)
  if not reserves.is_empty(): encounter(reserves[0],sector.id)
  elif sector.owner=="company" and Garrison.strength(sector)>0: encounter({},sector.id)
 save_to(autosave_path)
 return true

func save_to(path: String) -> bool:
 if battle != null:
  s.battle=battle.t
  s.sectors[s.encounter.sector].battlefield={"width":battle.t.width,"height":battle.t.height,"tiles":battle.t.tiles,"ground":battle.t.ground}
 var invalid=Items.ownership_error(s)
 if invalid!="": return reject(invalid)
 if not valid_save(s): return reject("Campaign state is inconsistent; previous save preserved")
 var f = FileAccess.open(path+".tmp",FileAccess.WRITE)
 if f == null: return reject("Cannot write save")
 f.store_string(JSON.stringify(s))
 f.flush()
 f.close()
 var absolute = ProjectSettings.globalize_path(path)
 if FileAccess.file_exists(path):
  var parser=JSON.new()
  if parser.parse(FileAccess.get_file_as_string(path))==OK and valid_save(Schema.upgrade(parser.data)):
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
   data=Schema.upgrade(normalize_numbers(parser.data)) if parsed==OK else {}
   if valid_save(data): break
 if not valid_save(data): return reject("Save invalid or unsupported version")
 s=normalize_numbers(data)
 Contracts.normalize(s)
 battle=null
 if not s.battle.is_empty():
  battle=Battle.new(self,s.battle)
  # Rebind authoritative mercenary references after JSON decoding.
  for u in battle.t.units:
   if u.team == "company":
    if u.role=="merc": u.person=s.mercs[u.id]
    else:
     for p in s.sectors[u.sector].levies:
      if p.id==u.id: u.person=p
   else:
    for g in s.groups:
     if g.id==u.group:
      for m in g.fighters:
       if m.id==u.id: u.person=m
  s.sectors[s.encounter.sector].battlefield={"width":battle.t.width,"height":battle.t.height,"tiles":battle.t.tiles,"ground":battle.t.ground}
 return true

func valid_save(data: Variant) -> bool:
 if not data is Dictionary: return false
 for key in ["version","sectors","mercs","squads","events","rng","time","battle","encounter","funds","jobs","ledger","stash","groups","factions","log","next_event","result"]:
  if not data.has(key): return false
 if data.version!=3 or not data.has_all(["next_item","next_levy","stash_sector","pending_encounters"]) or not data.sectors is Array or data.sectors.size()!=256 or not data.mercs is Dictionary or not data.squads is Dictionary: return false
 if not (data.next_item is int or data.next_item is float) or data.next_item<1 or data.next_item!=floor(data.next_item): return false
 if not (data.stash_sector is int or data.stash_sector is float) or data.stash_sector<0 or data.stash_sector>=256: return false
 if not Contracts.valid(data): return false
 if not data.pending_encounters is Array or not data.groups is Array or not data.stash is Array: return false
 if not (data.next_levy is int or data.next_levy is float) or data.next_levy<1 or data.next_levy!=floor(data.next_levy): return false
 if data.has("food") or data.has("medicine") or data.has("tools"): return false
 if not data.events is Array or not data.battle is Dictionary or not data.encounter is Dictionary: return false
 if not (data.time is int or data.time is float) or not (data.rng is int or data.rng is float): return false
 if data.time<0 or data.rng<=0 or data.rng>=2147483647: return false
 for sector in data.sectors:
  if not sector is Dictionary: return false
  for key in ["id","x","y","owner","facility","terrain","known","levies","supplies","loyalty","order","training","name"]:
   if not sector.has(key): return false
  if not sector.levies is Array or not Supplies.valid(sector.supplies): return false
  if sector.has("garrison"): return false
  for levy in sector.levies:
   if not levy is Dictionary or not levy.has("id") or not levy.id is String: return false
   if levy.id.begins_with("levy_"):
    var suffix=levy.id.trim_prefix("levy_")
    if not suffix.is_valid_int() or int(suffix)>=data.next_levy: return false
 var people=data.mercs.values()
 for sector in data.sectors: people.append_array(sector.levies)
 for g in data.groups:
  if not g is Dictionary or not g.has_all(["id","sector","fighters","positions","faction","objective"]) or not g.fighters is Array or not g.positions is Dictionary: return false
  if not data.factions.has(g.faction): return false
  people.append_array(g.fighters)
 var entity_ids={}
 for m in people:
  if not m is Dictionary: return false
  for key in Data.person("validation","validation","soldier","sword"):
   if not m.has(key): return false
  if not m.inventory is Array or not m.equipment is Dictionary: return false
  if entity_ids.has(m.id): return false
  entity_ids[m.id]=m
  for stat in ["hp","max_hp","fatigue","morale","strength","agility","dexterity","endurance","perception","wisdom","leadership","melee","ranged","medical","smithing","experience","bleeding","wounds"]:
   if not (m[stat] is int or m[stat] is float): return false
  if m.max_hp<=0 or m.hp<0 or m.hp>m.max_hp: return false
 var assigned={}
 for q in data.squads.values():
  if not q is Dictionary: return false
  for key in ["id","members","leader","sector","route","due","assignment","name","supplies"]:
   if not q.has(key): return false
  if not q.members is Array or not q.route is Array or q.sector<0 or q.sector>=256: return false
  if not Supplies.valid(q.supplies): return false
  for id in q.members:
   if not data.mercs.has(id) or assigned.has(id): return false
   assigned[id]=q.id
 for event in data.events:
  if not event is Dictionary or not event.has_all(["id","at","kind","payload"]): return false
  if not event.payload is Dictionary or not (event.at is int or event.at is float) or event.at<data.time: return false
 for contact in data.pending_encounters:
  if not contact is Dictionary or not contact.has_all(["squad","sector","from"]): return false
  if (contact.squad!="" and not data.squads.has(contact.squad)) or contact.sector<0 or contact.sector>=256: return false
 for cell in data.sectors:
  if cell.has("battlefield") and not valid_battlefield(cell.battlefield): return false
 if not data.battle.is_empty():
  if not data.battle.has_all(["units","tiles","width","height","turn","round","knowledge","log","ai","noise","ground","squads"]): return false
  if data.battle.tiles.size()!=int(data.battle.width)*int(data.battle.height): return false
  if not data.encounter.has_all(["squad","sector"]) or (data.encounter.squad!="" and not data.squads.has(data.encounter.squad)): return false
  if data.encounter.sector<0 or data.encounter.sector>=256: return false
  var field=data.sectors[data.encounter.sector].get("battlefield",{})
  if not valid_battlefield(field) or field.tiles!=data.battle.tiles or field.ground!=data.battle.ground: return false
  var unit_ids={}
  for u in data.battle.units:
   if not u is Dictionary or not u.has_all(["id","team","role","person","x","y","ap","stance","mode","facing","guard"]): return false
   if unit_ids.has(u.id) or not entity_ids.has(u.id) or u.person!=entity_ids[u.id]: return false
   unit_ids[u.id]=true
   for number in ["x","y","ap"]:
    if not (u[number] is int or u[number] is float): return false
   if u.x<0 or u.y<0 or u.x>=data.battle.width or u.y>=data.battle.height or u.ap<0: return false
   if u.team=="company":
    if u.role=="merc":
     if not data.mercs.has(u.id) or not u.has("squad") or not data.squads.has(u.squad) or u.id not in data.squads[u.squad].members: return false
    elif u.role=="levy":
     if not u.has("sector") or u.sector!=data.encounter.sector or u.person not in data.sectors[u.sector].levies: return false
    else: return false
   if u.team=="enemy":
    var bound=false
    for g in data.groups:
     if g.id==u.get("group","") and u.person in g.fighters: bound=true
    if not bound: return false
 return Items.ownership_error(data)==""

func valid_battlefield(field: Variant) -> bool:
 if not field is Dictionary or not field.has_all(["width","height","tiles","ground"]): return false
 if not (field.width is int or field.width is float) or not (field.height is int or field.height is float): return false
 if field.width<1 or field.height<1 or field.width>160 or field.height>160: return false
 if not field.tiles is Array or field.tiles.size()!=int(field.width)*int(field.height) or not field.ground is Array: return false
 for cell in field.tiles:
  if not cell is Dictionary or not cell.has_all(["x","y","cost","elevation","block","cover","conceal","door","open","kind"]): return false
  for number in ["x","y","cost","elevation","cover","conceal"]:
   if not (cell[number] is int or cell[number] is float): return false
  if cell.x<0 or cell.y<0 or cell.x>=field.width or cell.y>=field.height or cell.cost<1: return false
 for placement in field.ground:
  if not placement is Dictionary or not placement.has_all(["x","y","item"]): return false
  if not (placement.x is int or placement.x is float) or not (placement.y is int or placement.y is float): return false
  if placement.x<0 or placement.y<0 or placement.x>=field.width or placement.y>=field.height: return false
 return true

func normalize_numbers(value: Variant) -> Variant:
 if value is float and value==floor(value): return int(value)
 if value is Array:
  for i in range(value.size()): value[i]=normalize_numbers(value[i])
 elif value is Dictionary:
  for key in value: value[key]=normalize_numbers(value[key])
 return value
