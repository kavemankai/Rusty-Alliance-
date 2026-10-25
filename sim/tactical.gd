extends RefCounted
const Combat=preload("res://sim/combat_rules.gd")
const Tactics=preload("res://sim/tactics.gd")
const Visibility=preload("res://sim/visibility.gd")
const Exploration=preload("res://sim/exploration.gd")
const Data = preload("res://sim/catalog.gd")
const Layouts=preload("res://sim/battlefields.gd")
const Supplies=preload("res://sim/supplies.gd")
var campaign_ref: WeakRef
var campaign:
 get: return campaign_ref.get_ref()
var t: Dictionary
var error = ""
var fog_signature=-1
var fog_observers={}
var light_signature=-1

func _init(owner, restored: Dictionary = {}) -> void:
 campaign_ref=weakref(owner)
 if not restored.is_empty():
  t=restored
  if not t.has("phase"): t.phase="combat"
  if not t.has("quiet_rounds"): t.quiet_rounds=0
  if not t.has("ai_state"): t.ai_state={}
  if t.has("exploration"): t.exploration.running=false
  Visibility.refresh(self)
  return
 t={"night":int(campaign.s.time/60)%24<6 or int(campaign.s.time/60)%24>=20,"peaceful":campaign.s.encounter.get("peaceful",false),"ai_state":{},"quiet_rounds":0,"phase":"deployment","width":18,"height":14,"tiles":[],"units":[],"squads":[],"turn":"company","round":1,"knowledge":{"company":{},"enemy":{}},"log":[],"ai":[],"noise":[],"ground":[]}
 build_map(18,14)
 var sector=campaign.s.sectors[campaign.s.encounter.sector]
 if not sector.has("battlefield"): sector.battlefield=Layouts.create(sector)
 var saved=sector.battlefield
 for key in ["width","height","tiles","ground","fog","entry_zones"]+Layouts.META:
  if saved.has(key): t[key]=saved[key]
 campaign.ensure_group_rosters()
 var count=0
 for g in campaign.s.groups:
  if g.sector == sector.id and g.faction!="company":
   for p in g.fighters:
    if p.hp<=10 or p.get("captured",false) or p.get("released",false): continue
    var spawn={"x":11+count%3,"y":3+(count*3)%9}
    if t.has("enemy_spawns") and count<t.enemy_spawns.size(): spawn=t.enemy_spawns[count]
    var position=g.positions.get(p.id,spawn)
    var u=make_unit(p.id,"enemy",p,position.x,position.y)
    u.group=g.id
    # A later entrant may otherwise collide with a survivor's remembered position.
    place_unit(u)
    count+=1
 var index=0
 for q in campaign.combat_squads(sector.id):
  t.squads.append(q.id)
  for id in q.members:
   var m=campaign.s.mercs[id]
   if m.hp<=0 or m.get("captured",false): continue
   var u=make_unit(id,"company",m,2+int(index/5),3+(index%5)*2)
   u.squad=q.id
   place_deploying_unit(u)
   index+=1
 if sector.owner=="company":
  for p in sector.levies:
   if p.hp<=0 or p.get("captured",false): continue
   var u=make_unit(p.id,"company",p,4+int(index/5),3+(index%5)*2)
   u.role="levy"
   u.sector=sector.id
   place_deploying_unit(u)
   index+=1
 for job in campaign.s.jobs:
  if job.type!="escort" or job.status!="active" or job.squad not in t.squads: continue
  for actor in job.get("actors",[]):
   if actor.hp<=0: continue
   var u=make_unit(actor.id,"company",actor,2+int(index/5),3+(index%5)*2)
   u.role=actor.merchant_role;u.contract=job.id;u.squad=job.squad
   place_deploying_unit(u);index+=1
 refresh_knowledge()
 sector.battlefield=field_state()

func make_unit(id: String, team: String, p: Dictionary, x: int, y: int) -> Dictionary:
 return {"id":id,"team":team,"role":"merc" if team=="company" else "enemy","person":p,"x":x,"y":y,"ap":Data.ap(p),"stance":"stand","mode":"walk","facing":0 if team=="company" else 4,"attack_style":"normal","defence_mode":"balanced","aim_location":"auto","activated":team=="company","guard":false,"reason":"guarding"}

func place_unit(u: Dictionary) -> void:
 var cell=tile(u.x,u.y)
 if cell.is_empty() or cell.block or at(u.x,u.y)!=null:
  if u.team=="enemy":
   for point in t.get("enemy_spawns",[]):
    if not tile(point.x,point.y).block and at(point.x,point.y)==null:
     u.x=point.x;u.y=point.y
     t.units.append(u)
     return
  for candidate in t.tiles:
   if not candidate.block and at(candidate.x,candidate.y)==null:
    u.x=candidate.x;u.y=candidate.y
    break
 t.units.append(u)

func build_map(w: int,h: int) -> void:
 t.width=w
 t.height=h
 t.tiles=[]
 for y in range(h):
  for x in range(w):
   var tile={"x":x,"y":y,"cost":2,"elevation":0,"block":false,"cover":0,"conceal":0,"door":false,"open":false,"kind":"grass"}
   if x == 7 and y>1 and y<h-2:
    tile.block=true
    tile.kind="wall"
   if x == 7 and y == 6:
    tile.door=true
    tile.kind="door"
   if x == 7 and y == 4:
    tile.kind="window"
   if x>9 and y>8:
    tile.elevation=1
    tile.cost=3
    tile.kind="hill"
   if x==5 and y in [3,4,8,9]:
    tile.cover=25
    tile.kind="barricade"
   if x==10 and y in [4,5]:
    tile.conceal=20
    tile.cost=4
    tile.kind="brush"
   t.tiles.append(tile)

func tile(x: int,y: int) -> Dictionary:
 if x<0 or y<0 or x>=t.width or y>=t.height: return {}
 return t.tiles[y*t.width+x]

func unit(id: String):
 for u in t.units:
  if u.id == id: return u
 return null

func at(x: int,y: int,ignore: String=""):
 for u in t.units:
  if u.id != ignore and u.x==x and u.y==y and u.person.hp>0: return u
 return null

func can_act(u: Dictionary) -> bool:
 if u.role=="cart":
  var driving=false
  for driver in t.units:
   if driver.role=="driver" and driver.get("contract","")==u.get("contract","") and driver.person.hp>10 and distance(u,driver)<=2: driving=true
  if not driving: return false
 return (t.phase=="combat" or (t.phase=="exploration" and u.team=="company")) and t.turn == u.team and u.person.hp>10 and outcome()=="ongoing"

func fail(message: String) -> bool:
 error=message
 return false

func log_event(message: String) -> void:
 t.log.append(message)
 if t.log.size()>40: t.log.pop_front()

func distance(a: Dictionary,b: Dictionary) -> int:
 return maxi(absi(a.x-b.x),absi(a.y-b.y))

func heading(dx: int,dy: int) -> int:
 var angle=atan2(float(dy),float(dx))
 return posmod(int(round(angle/(PI/4.0))),8)

func rear(a: Dictionary,b: Dictionary) -> bool:
 var dir=heading(a.x-b.x,a.y-b.y)
 return mini(posmod(dir-b.facing,8),posmod(b.facing-dir,8))>=3

func step_cost(u: Dictionary, from: Dictionary, dest: Dictionary,charted: bool=false) -> int:
 if dest.is_empty() or dest.block or planned_occupant(u,dest.x,dest.y,charted)!=null: return -1
 var dx=dest.x-from.x
 var dy=dest.y-from.y
 if absi(dx)>1 or absi(dy)>1 or (dx==0 and dy==0): return -1
 if dx!=0 and dy!=0:
  var a=Visibility.cell(self,from.x+dx,from.y,u.team) if charted else tile(from.x+dx,from.y)
  var b=Visibility.cell(self,from.x,from.y+dy,u.team) if charted else tile(from.x,from.y+dy)
  if a.is_empty() or b.is_empty() or a.block or b.block or planned_occupant(u,a.x,a.y,charted)!=null or planned_occupant(u,b.x,b.y,charted)!=null: return -1
 if absi(dest.elevation-from.elevation)>1: return -1
 var cost=dest.cost+maxi(0,dest.elevation-from.elevation)*2
 if dx!=0 and dy!=0: cost=int(ceil(cost*1.4))
 if u.role=="cart": cost+=1
 if u.stance=="crouch": cost+=1
 if u.stance=="prone": cost+=3
 if u.mode=="run": cost=maxi(1,cost-1)
 if u.mode=="cautious": cost+=1
 return cost

# Binary min-heap avoids sorting the entire frontier at every expansion.
func heap_push(heap: Array,entry: Array) -> void:
 heap.append(entry)
 var i=heap.size()-1
 while i>0:
  var parent=int((i-1)/2)
  if heap[parent][0]<=entry[0]: break
  heap[i]=heap[parent];i=parent
 heap[i]=entry

func heap_pop(heap: Array) -> Array:
 var result=heap[0]
 var tail=heap.pop_back()
 if heap.is_empty(): return result
 var i=0
 while i*2+1<heap.size():
  var child=i*2+1
  if child+1<heap.size() and heap[child+1][0]<heap[child][0]: child+=1
  if tail[0]<=heap[child][0]: break
  heap[i]=heap[child];i=child
 heap[i]=tail
 return result

func path(u: Dictionary,x: int,y: int,charted: bool=false) -> Dictionary:
 # Preserve established equal-cost route choices in authored small encounters.
 if t.tiles.size()<=512: return path_reference(u,x,y,charted)
 return path_heap(u,x,y,charted)

func path_heap(u: Dictionary,x: int,y: int,charted: bool=false) -> Dictionary:
 var goal=Visibility.cell(self,x,y,u.team) if charted else tile(x,y)
 if goal.is_empty() or goal.block or planned_occupant(u,x,y,charted)!=null: return {"path":[],"cost":-1}
 var start=int(u.y*t.width+u.x);var end=y*t.width+x
 if start==end: return {"path":[],"cost":0}
 var minimum=1000000
 for actual in t.tiles:
  var cell=Visibility.cell(self,actual.x,actual.y,u.team) if charted else actual
  minimum=mini(minimum,int(cell.cost))
 var orth=minimum;var diagonal=int(ceil(minimum*1.4))
 var extra=(1 if u.role=="cart" else 0)+(1 if u.stance=="crouch" else (3 if u.stance=="prone" else 0))
 orth+=extra;diagonal+=extra
 if u.mode=="run": orth=maxi(1,orth-1);diagonal=maxi(1,diagonal-1)
 if u.mode=="cautious": orth+=1;diagonal+=1
 diagonal=mini(diagonal,orth*2)
 var heap=[];var costs={start:0};var previous={}
 heap_push(heap,[route_estimate(start,end,orth,diagonal),start,0])
 while not heap.is_empty():
  var entry=heap_pop(heap);var pos=entry[1]
  if entry[2]!=costs[pos]: continue
  if pos==end:
   var route=[]
   while pos!=start:
    route.push_front(pos);pos=previous[pos]
   return {"path":route,"cost":costs[end]}
  var from=Visibility.cell(self,int(pos)%int(t.width),int(pos)/int(t.width),u.team) if charted else t.tiles[pos]
  for dy in range(-1,2):
   for dx in range(-1,2):
    var dest=Visibility.cell(self,from.x+dx,from.y+dy,u.team) if charted else tile(from.x+dx,from.y+dy)
    var step=step_cost(u,from,dest,charted)
    if step<0: continue
    var next=dest.y*t.width+dest.x;var total=costs[pos]+step
    if not costs.has(next) or total<costs[next]:
     costs[next]=total;previous[next]=pos
     heap_push(heap,[total+route_estimate(next,end,orth,diagonal),next,total])
 return {"path":[],"cost":-1}

func route_estimate(a: int,b: int,orth: int,diagonal: int) -> int:
 var dx=absi(a%int(t.width)-b%int(t.width));var dy=absi(int(a/t.width)-int(b/t.width))
 return mini(dx,dy)*diagonal+absi(dx-dy)*orth

func path_reference(u: Dictionary,x: int,y: int,charted: bool=false) -> Dictionary:
 var goal=Visibility.cell(self,x,y,u.team) if charted else tile(x,y)
 if goal.is_empty() or goal.block or planned_occupant(u,x,y,charted)!=null: return {"path":[],"cost":-1}
 var start=int(u.y*t.width+u.x)
 var end=y*t.width+x
 if end==start: return {"path":[],"cost":0}
 var open=[start]
 var costs={start:0}
 var previous={}
 while not open.is_empty():
  open.sort_custom(func(a,b): return costs[a]+heuristic(a,end)<costs[b]+heuristic(b,end))
  var pos=open.pop_front()
  if pos==end:
   var route=[]
   while pos!=start:
    route.push_front(pos)
    pos=previous[pos]
   return {"path":route,"cost":costs[end]}
  var from=Visibility.cell(self,int(pos)%int(t.width),int(pos)/int(t.width),u.team) if charted else t.tiles[pos]
  for dy in range(-1,2):
   for dx in range(-1,2):
    var dest=Visibility.cell(self,from.x+dx,from.y+dy,u.team) if charted else tile(from.x+dx,from.y+dy)
    var c=step_cost(u,from,dest,charted)
    if c<0: continue
    var next=dest.y*t.width+dest.x
    var total=costs[pos]+c
    if not costs.has(next) or total<costs[next]:
     costs[next]=total
     previous[next]=pos
     if not next in open: open.append(next)
 return {"path":[],"cost":-1}

func heuristic(a: int,b: int) -> int:
 return maxi(absi(a%int(t.width)-b%int(t.width)),absi(int(a/t.width)-int(b/t.width)))

func visible(a: Dictionary,b: Dictionary) -> bool:
 var d=distance(a,b)
 var radius=5+int(a.person.perception/10)
 if t.get("night",false): radius=maxi(2,radius-3)
 radius+=t.get("illumination",{}).get(str(b.y*int(t.width)+b.x),0)
 if rear(b,a): radius=maxi(2,int(radius*0.65))
 if b.get("stance","stand")=="prone": radius-=2
 radius-=int(tile(b.x,b.y).conceal/10)
 return d<=radius and los(a,b)

func los(a: Dictionary,b: Dictionary) -> bool:
 # Supercover samples: adjacent side cells also stop diagonal corner sight.
 var dx=b.x-a.x
 var dy=b.y-a.y
 var steps=maxi(absi(dx),absi(dy))*4
 for i in range(1,steps):
  var f=float(i)/steps
  var x=int(round(a.x+dx*f))
  var y=int(round(a.y+dy*f))
  if (x==a.x and y==a.y) or (x==b.x and y==b.y): continue
  var cell=tile(x,y)
  if cell.block and cell.kind!="window": return false
  var eye=lerpf(tile(a.x,a.y).elevation+1.5,tile(b.x,b.y).elevation+1.0,f)
  if cell.elevation>eye: return false
 return true

func refresh_knowledge() -> void:
 Visibility.refresh(self)
 if t.phase=="deployment": return
 for team in ["company","enemy"]:
  for key in t.knowledge[team]: t.knowledge[team][key].visible=false
  for observer in t.units:
   if observer.team!=team or observer.person.hp<=10: continue
   for other in t.units:
    if other.team==team or other.person.hp<=0: continue
    if visible(observer,other):
     t.knowledge[team][other.id]={"x":other.x,"y":other.y,"round":t.round,"visible":true}

 for receiver in t.units:
  if receiver.person.hp<=10: continue
  if not receiver.has("memory"): receiver.memory={}
  for other in t.units:
   if other.team==receiver.team or other.person.hp<=0: continue
   var informed=visible(receiver,other)
   if not informed:
    for ally in t.units:
     if ally.team==receiver.team and ally.person.hp>10 and distance(receiver,ally)<=6 and visible(ally,other): informed=true;break
   if informed: receiver.memory[other.id]={"x":other.x,"y":other.y,"round":t.round,"visible":true}
   elif receiver.memory.has(other.id): receiver.memory[other.id].visible=false
 campaign.Contracts.tick(campaign)
 if t.phase=="exploration" and Exploration.contact(self): Exploration.combat(self,"Opponents detected")
 elif t.phase=="combat" and Exploration.contact(self): t.quiet_rounds=0

func known(team: String,id: String) -> bool:
 return t.knowledge[team].has(id) and t.knowledge[team][id].visible

func move(u: Dictionary,x: int,y: int) -> bool:
 error=""
 if t.phase=="exploration": return Exploration.order(self,u.id,x,y)
 if not can_act(u): return fail("Unit cannot act")
 var preview=path(u,x,y,u.team=="company")
 if preview.cost<=0 or preview.cost>u.ap: return fail("Unreachable or insufficient AP")
 # Step execution permits reactions and halts on new contact, matching path costs.
 for index in preview.path:
  var dest=t.tiles[index]
  var cost=step_cost(u,tile(u.x,u.y),dest)
  if cost<0 or cost>u.ap: break
  for enemy in t.units:
   if enemy.team==u.team or enemy.person.hp<=10 or not enemy.guard: continue
   var w=Data.WEAPONS[Data.weapon(enemy.person)]
   if w.reach>0 and not u.get("disengaging",false) and enemy.ap>=w.ap and known(enemy.team,u.id) and los(enemy,u) and distance(enemy,u)<=w.reach and maxi(absi(enemy.x-dest.x),absi(enemy.y-dest.y))>w.reach:
    attack(enemy,u,0,true)
    enemy.guard=false
  if u.person.hp<=10: break
  u.ap-=cost
  u.facing=heading(dest.x-u.x,dest.y-u.y)
  u.x=dest.x
  u.y=dest.y
  u.person.fatigue=mini(100,u.person.fatigue+(maxi(1,5-int(u.person.endurance/20)) if u.mode=="run" else 1))
  refresh_knowledge()
  for enemy in t.units:
   if enemy.team==u.team or enemy.person.hp<=10 or not enemy.guard: continue
   var w=Data.WEAPONS[Data.weapon(enemy.person)]
   if w.reach==0 and known(enemy.team,u.id) and distance(enemy,u)<=w.range and enemy.person.loaded and Data.ammo(enemy.person)>0 and enemy.ap>=w.ap:
    attack(enemy,u,0,true)
    enemy.guard=false
  if u.person.hp<=10: break
  if outcome()!="ongoing": break
 log_event(u.person.name+" moved; AP %d" % u.ap)
 return true

func hit_chance(a: Dictionary,b: Dictionary,aim: int=0) -> int:
 var w=Data.WEAPONS[Data.weapon(a.person)]
 var ranged=w.reach==0
 var d=distance(a,b)
 var skill=a.person.ranged if ranged else a.person.melee
 var chance=Combat.accuracy(a)+50+int(skill*0.6)-int(b.person.agility*0.25)+w.accuracy+aim*7
 chance-=int(a.person.fatigue/5)+int((a.person.max_hp-a.person.hp)/5)
 chance+=int((a.person.morale-50)/10)+int(a.person.experience*2)
 chance+=5*(tile(a.x,a.y).elevation-tile(b.x,b.y).elevation)
 if ranged:
  chance-=maxi(0,d-w.effective)*7
  chance-=directional_cover(a,b)+tile(b.x,b.y).conceal
  if b.stance=="crouch": chance-=8
  if b.stance=="prone": chance-=15
  if a.stance=="crouch": chance+=5
 else:
  chance-=int(b.person.melee/8)
  if rear(a,b): chance+=22
  var pressure=0
  for friend in t.units:
   if friend.team==a.team and friend.person.hp>10 and distance(friend,b)<=1: pressure+=1
  chance+=maxi(0,pressure-1)*5
 return clampi(chance,5,95)

func attack(a: Dictionary,b: Dictionary,aim: int=0,reaction: bool=false) -> bool:
 error=""
 if t.phase!="combat": return fail("Confirm deployment before combat")
 if aim<0 or aim>3: return fail("Aim must be 0 to 3")
 if a.team==b.team or a.person.hp<=10 or b.person.hp<=0: return fail("Invalid combatants")
 if not reaction and not can_act(a): return fail("Unit cannot act")
 var w=Data.WEAPONS[Data.weapon(a.person)]
 var ranged=w.reach==0
 var cost=Combat.cost(a,aim)
 if distance(a,b)>w.range or not los(a,b): return fail("Out of reach or blocked line of sight")
 if not known(a.team,b.id): return fail("Target not perceived")
 if ranged and (Data.ammo(a.person)<=0 or not a.person.loaded): return fail("Reload with ammunition first")
 if a.ap<cost: return fail("Insufficient AP")
 var chance=hit_chance(a,b,aim)
 a.ap-=cost
 a.facing=heading(b.x-a.x,b.y-a.y)
 a.person.fatigue=mini(100,a.person.fatigue+2)
 if ranged:
  Data.consume_ammo(a.person)
  a.person.loaded=false
 var used_weapon=Data.equipped(a.person,"weapon")
 if not used_weapon.is_empty(): used_weapon.condition=maxi(0,used_weapon.condition-1)
 # Acoustic information records a location, never the unseen target entity.
 t.noise.append({"x":a.x,"y":a.y,"round":t.round,"team":a.team,"strength":1 if ranged else 2})
 if campaign.roll(100)>=chance:
  log_event(a.person.name+" missed (%d%%)" % chance)
  return true
 var defence=""
 var back=rear(a,b)
 if not back and b.ap>=2 and b.person.hp>10 and b.person.morale>=20:
  var shield=Data.equipped(b.person,"shield")
  var block=int((20+b.person.dexterity/4.0+Combat.defence_bonus(b,"shield"))*shield.condition/100.0) if not shield.is_empty() else 0
  if a.get("attack_style","normal")=="feint": block=int(block/2)
  if block>0 and campaign.roll(100)<block:
   b.ap-=2
   shield.condition=maxi(0,shield.condition-5-int(w.damage/8))
   defence="shield block"
  elif not ranged and Data.WEAPONS[Data.weapon(b.person)].defence>0 and campaign.roll(100)<Combat.parry_chance(a,b):
   b.ap-=2
   var parrying=Data.equipped(b.person,"weapon")
   parrying.condition=maxi(0,parrying.condition-1)
   defence="parry"
  elif campaign.roll(100)<Combat.dodge_chance(a,b):
   b.ap-=2
   defence="dodge"
 if defence!="":
  log_event(b.person.name+" used "+defence+" (2 AP)")
  return true
 var raw=w.damage+int(a.person.strength/12) if not ranged else w.damage
 raw=int(raw*(0.65+Data.condition(a.person)/285.0))
 raw=int(raw*Combat.ATTACKS[a.get("attack_style","normal")].damage)
 if b.get("defence_mode","balanced")=="brace": raw=int(raw*0.8)
 if Combat.intercept(self,a,b): raw=int(raw*0.65)
 Combat.hit(self,a,b,raw,"pierce" if a.get("attack_style","normal")=="thrust" and w.reach>0 else w.kind,a.get("aim_location","auto"))
 refresh_knowledge()
 return true

func action(id: String,kind: String,p: Dictionary={}) -> bool:
 error=""
 var u=unit(id)
 if u==null or not can_act(u): return fail("Select an active unit")
 if t.phase=="exploration" and kind in ["attack","guard"]: return fail("Enter combat before attacking or guarding")
 if u.role=="cart" and kind!="move": return fail("Carts can only move while a living driver is nearby")
 match kind:
  "charge": return Combat.charge(self,u,p)
  "bash": return Combat.bash(self,u,p)
  "protect": return Combat.protect(self,u,p)
  "repair_cart":
   var cart=unit(p.get("target",""));var pack=Supplies.for_person(campaign.s,u.id)
   if cart==null or cart.role!="cart" or cart.person.hp<=0 or distance(u,cart)>1 or u.ap<5 or pack.get("tools",0)<1: return fail("Repair an adjacent surviving cart for 5 AP and one local tool")
   pack.tools-=1;u.ap-=5;cart.person.hp=mini(cart.person.max_hp,cart.person.hp+12+int(u.person.smithing/10));Data.treat(cart.person,u.person.smithing)
  "rally":
   if u.ap<4 or u.get("rallied_round",-1)==t.round: return fail("Rally costs 4 AP and can be used once per round")
   u.ap-=4;u.rallied_round=t.round
   for ally in t.units:
    if ally.team==u.team and ally.person.hp>10 and distance(u,ally)<=3: ally.person.morale=mini(100,ally.person.morale+4+int(u.person.leadership/15))
  "formation": return formation(u,p)
  "build": return campaign.Operations.build(self,u,p)
  "attack_style":
   if Data.WEAPONS[Data.weapon(u.person)].reach==0 and p.get("value","")!="normal": return fail("Melee styles require a melee weapon")
   if not Combat.ATTACKS.has(p.get("value","")): return fail("Unknown attack style")
   u.attack_style=p.value
  "defence_mode":
   if p.get("value","") not in Combat.DEFENCES or u.ap<2: return fail("Choose a defence with 2 AP")
   if p.value=="shield" and not Data.shield(u.person): return fail("A functional shield is required")
   u.ap-=2;u.defence_mode=p.value
  "aim_location":
   if p.get("value","") not in Combat.LOCATIONS: return fail("Unknown body target")
   u.aim_location=p.value
  "disengage": return Combat.disengage(self,u,p)
  "throw": return Combat.throw_item(self,u,p)
  "move": return move(u,p.x,p.y)
  "attack":
   var target=unit(p.get("target",""))
   if target==null: return fail("Unknown target")
   return attack(u,target,p.get("aim",0))
  "reload":
   var w=Data.WEAPONS[Data.weapon(u.person)]
   if w.reach>0 or u.person.loaded or Data.ammo(u.person)<=0: return fail("No reload needed or no ammunition")
   if u.ap<w.reload: return fail("Insufficient AP")
   u.ap-=w.reload
   u.person.loaded=true
  "stance":
   if not p.value in ["stand","crouch","prone"] or p.value==u.stance or u.ap<2: return fail("Invalid stance or insufficient AP")
   u.ap-=2
   u.stance=p.value
  "mode":
   if not p.value in ["walk","run","cautious"]: return fail("Unknown movement mode")
   u.mode=p.value
  "turn":
   if u.ap<1: return fail("Need 1 AP")
   u.ap-=1
   u.facing=posmod(u.facing+1,8)
  "door":
   var cell=tile(p.x,p.y)
   if cell.is_empty() or not cell.door or distance(u,cell)>1 or u.ap<3 or at(cell.x,cell.y)!=null: return fail("Need adjacent door and 3 AP")
   u.ap-=3
   cell.open=not cell.open
   cell.block=not cell.open
  "aid":
   var target=unit(p.get("target",id))
   var provisions=Supplies.for_person(campaign.s,id)
   if target==null or target.role=="cart" or target.team!=u.team or target.person.hp<=0 or distance(u,target)>1 or u.ap<5 or provisions.get("medicine",0)<=0: return fail("Need nearby survivor, medicine in the actor's local pack and 5 AP")
   u.ap-=5
   provisions.medicine-=1
   target.person.bleeding=0
   Data.treat(target.person,u.person.medical)
   target.person.hp=mini(target.person.max_hp,target.person.hp+2+int(u.person.medical/12))
  "guard": u.guard=true
  "loot":
   if u.ap<3: return fail("Need 3 AP")
   for item in t.ground:
    if distance(u,item)<=1:
     u.ap-=3
     u.person.inventory.append(item.item)
     t.ground.erase(item)
     return true
   return fail("No adjacent loot")
  _: return fail("Unknown action")
 refresh_knowledge()
 return true

func outcome() -> String:
 if t.phase=="deployment": return "deployment"
 var friends=0
 var enemies=0
 for u in t.units:
  if u.person.hp>10:
   if u.team=="company" and u.role not in ["cart","driver"]: friends+=1
   elif u.team=="enemy": enemies+=1
 if friends==0: return "defeat"
 if enemies==0: return "ongoing" if t.get("peaceful",false) else "victory"
 return "ongoing"

func start_turn(team: String) -> void:
 if t.phase!="combat": return
 t.turn=team
 for u in t.units:
  if u.team!=team: continue
  if u.person.hp>0 and u.person.bleeding>0:
   u.person.hp=maxi(0,u.person.hp-u.person.bleeding)
   if u.person.hp==0:
    u.person.dead=true
    campaign.drop_inventory(u.person,u.x,u.y,t.ground)
  var carry=mini(4,u.ap) if u.get("activated",false) else 0
  u.ap=mini(26,Data.ap(u.person)+carry)
  u.activated=true
  u.protecting=""
  u.guard=false
 refresh_knowledge()

func end_turn() -> bool:
 if t.phase!="combat" or t.turn!="company" or outcome()!="ongoing": return fail("No active player turn")
 start_turn("enemy")
 t.ai=[]
 for u in t.units:
  if u.team=="enemy" and u.person.hp>10 and outcome()=="ongoing": ai_unit(u)
 t.round+=1
 start_turn("company")
 if not Exploration.contact(self): t.quiet_rounds=mini(3,t.quiet_rounds+1)
 return true

func ai_unit(u: Dictionary) -> void:
 Tactics.act(self,u)

# Authored zones persist with each battlefield; legacy maps keep the western strip.
static func deployment_tile(state: Dictionary,x: int,y: int) -> bool:
 if x<0 or y<0 or x>=state.width or y>=state.height: return false
 var inside=false
 for zone in state.get("active_zones",state.get("deployment_zones",[{"x":0,"y":0,"w":mini(6,int(state.width)),"h":state.height}])):
  if x>=zone.x and y>=zone.y and x<zone.x+zone.w and y<zone.y+zone.h: inside=true
 if not inside: return false
 var cell=state.tiles[y*int(state.width)+x]
 if cell.block: return false
 for other in state.units:
  if other.team=="enemy" and other.person.hp>0 and maxi(absi(other.x-x),absi(other.y-y))<4: return false
 return true

func place_deploying_unit(u: Dictionary) -> void:
 u.deployed=false
 if deployment_tile(t,u.x,u.y) and at(u.x,u.y)==null:
  u.deployed=true
 else:
  for cell in t.tiles:
   if deployment_tile(t,cell.x,cell.y) and at(cell.x,cell.y)==null:
    u.x=cell.x;u.y=cell.y;u.deployed=true
    break
 # A congested entry zone is reviewable but cannot be confirmed. Never relocate
 # persistent hostiles to make room for incoming company units.
 if u.deployed: t.units.append(u)
 else: place_unit(u)

func deployment_error(id: String,x: int,y: int) -> String:
 var u=unit(id)
 if t.phase!="deployment": return "Deployment is already confirmed"
 if u==null or u.team!="company" or u.person.hp<=0: return "Select a living friendly fighter"
 if not deployment_tile(t,x,y): return "Choose an available tile in the highlighted deployment zone"
 if at(x,y,id)!=null: return "Deployment tile is occupied"
 return ""

func deploy(id: String,p: Dictionary) -> bool:
 error=""
 for key in ["x","y"]:
  if not p.has(key) or not (p[key] is int or p[key] is float) or p[key]!=floor(p[key]): return fail("Choose a whole deployment tile")
 var invalid=deployment_error(id,p.x,p.y)
 if invalid!="": return fail(invalid)
 var facing=p.get("facing",unit(id).facing)
 if not (facing is int or facing is float) or facing!=floor(facing) or facing<0 or facing>7: return fail("Facing must be 0 to 7")
 var u=unit(id)
 u.x=int(p.x);u.y=int(p.y);u.facing=int(facing);u.deployed=true
 return true

func confirm_deployment(explore: bool=false) -> bool:
 error=""
 if t.phase!="deployment": return fail("Deployment is already confirmed")
 for u in t.units:
  if u.team!="company" or u.person.hp<=0: continue
  if not u.get("deployed",false): return fail("Place every friendly fighter before starting combat")
  var invalid=deployment_error(u.id,u.x,u.y)
  if invalid!="": return fail(invalid)
 t.phase="combat"
 if explore: return Exploration.begin(self)
 refresh_knowledge()
 log_event("Deployment confirmed; combat begins")
 return true

func field_state() -> Dictionary:
 var field={"width":t.width,"height":t.height,"tiles":t.tiles,"ground":t.ground,"fog":t.get("fog",{"company":{},"enemy":{}})}
 for key in Layouts.META+["entry_zones"]:
  if t.has(key): field[key]=t[key]
 return field

func resume_exploration() -> bool:
 if t.phase!="combat" or outcome()!="ongoing" or t.quiet_rounds<3: return fail("Need three full rounds without either side detecting opponents")
 if Exploration.current_contact(self): return fail("Opponents remain in contact")
 return Exploration.begin(self)

func planned_occupant(u: Dictionary,x: int,y: int,charted: bool):
 var other=at(x,y,u.id)
 if other==null or not charted or other.team==u.team or known(u.team,other.id): return other
 return null

func directional_cover(attacker: Dictionary,defender: Dictionary) -> int:
 var own=tile(defender.x,defender.y)
 var protection=own.cover
 var incoming=heading(attacker.x-defender.x,attacker.y-defender.y)
 if own.has("cover_edge") and mini(posmod(incoming-own.cover_edge,8),posmod(own.cover_edge-incoming,8))>1: protection=0
 var dx=signi(attacker.x-defender.x);var dy=signi(attacker.y-defender.y)
 if dx==0 and dy==0: return protection
 var edges=[{"x":defender.x+dx,"y":defender.y+dy,"weight":1.0}]
 if dx!=0 and dy!=0:
  edges.append({"x":defender.x+dx,"y":defender.y,"weight":0.5})
  edges.append({"x":defender.x,"y":defender.y+dy,"weight":0.5})
 for edge in edges:
  var c=tile(edge.x,edge.y)
  if c.is_empty(): continue
  var value=maxi(c.cover,35 if c.block else 0)
  if c.has("cover_edge") and mini(posmod(incoming-c.cover_edge,8),posmod(c.cover_edge-incoming,8))>1: value=0
  protection=maxi(protection,int(value*edge.weight))
 protection-=maxi(0,tile(attacker.x,attacker.y).elevation-tile(defender.x,defender.y).elevation)*10
 return clampi(protection,0,60)

func choose_entry(direction: String) -> bool:
 if t.phase!="deployment" or not t.get("entry_zones",{}).has(direction): return fail("Choose an authored approach before deployment is confirmed")
 t.active_zones=t.entry_zones[direction].duplicate(true);t.active_entry=direction
 var friends=t.units.filter(func(u):return u.team=="company")
 t.units=t.units.filter(func(u):return u.team!="company")
 for u in friends:
  u.x=-1;u.y=-1;place_deploying_unit(u)
 refresh_knowledge()
 return true

func lighting(stamp: int=-1) -> void:
 if stamp==-1: stamp=t.tiles.hash()
 if light_signature==stamp: return
 light_signature=stamp;t.illumination={}
 for cell in t.tiles:
  var radius=cell.get("light",0)
  if radius<=0: continue
  for y in range(maxi(0,cell.y-radius),mini(t.height,cell.y+radius+1)):
   for x in range(maxi(0,cell.x-radius),mini(t.width,cell.x+radius+1)):
    if los(cell,tile(x,y)): t.illumination[str(y*int(t.width)+x)]=3

func formation(leader: Dictionary,p: Dictionary) -> bool:
 var style=p.get("style","line")
 if style not in ["line","column","wedge"]: return fail("Choose line, column or wedge")
 var plans=[];var reserved={};var index=0
 for u in t.units:
  if u.team!="company" or u.person.hp<=10 or u.get("role","") in ["cart","driver"]: continue
  var x=p.get("x",leader.x)+(index%3-1 if style!="column" else 0)
  var y=p.get("y",leader.y)+(int(index/3) if style=="line" else (index if style=="column" else absi(index%3-1)+int(index/3)))
  var key=str(x)+":"+str(y)
  var route=path(u,x,y,true)
  if reserved.has(key) or route.cost<0 or (t.phase=="combat" and route.cost>u.ap): return fail("Formation needs distinct reachable destinations and enough AP for every fighter")
  reserved[key]=true;plans.append({"id":u.id,"x":x,"y":y});index+=1
 for plan in plans:
  if unit(plan.id).x==plan.x and unit(plan.id).y==plan.y: continue
  if not action(plan.id,"move",plan): break
  if outcome()!="ongoing": break
 return true
