extends RefCounted
const Data = preload("res://sim/catalog.gd")
var campaign_ref: WeakRef
var campaign:
 get: return campaign_ref.get_ref()
var t: Dictionary
var error = ""

func _init(owner, restored: Dictionary = {}) -> void:
 campaign_ref=weakref(owner)
 if not restored.is_empty():
  t=restored
  return
 t={"width":18,"height":14,"tiles":[],"units":[],"turn":"company","round":1,"knowledge":{"company":{},"enemy":{}},"log":[],"ai":[],"noise":[],"ground":[]}
 build_map(18,14)
 var q=campaign.s.squads[campaign.s.encounter.squad]
 var sector=campaign.s.sectors[q.sector]
 if sector.has("battlefield"):
  var saved=sector.battlefield
  t.width=saved.width
  t.height=saved.height
  t.tiles=saved.tiles
  t.ground=saved.ground
 else: sector.battlefield={"width":t.width,"height":t.height,"tiles":t.tiles,"ground":t.ground}
 var index=0
 for id in q.members:
  var m=campaign.s.mercs[id]
  t.units.append(make_unit(id,"company",m,2+int(index/5),3+(index%5)*2))
  index+=1
 campaign.ensure_group_rosters()
 var count=0
 for g in campaign.s.groups:
  if g.sector == q.sector and g.faction!="company":
   for p in g.fighters:
    if p.hp<=10 or p.get("captured",false): continue
    var position=g.positions.get(p.id,{"x":11+count%3,"y":3+(count*3)%9})
    var u=make_unit(p.id,"enemy",p,position.x,position.y)
    u.group=g.id
    # A later entrant may otherwise collide with a survivor's remembered position.
    if at(u.x,u.y)!=null or tile(u.x,u.y).block:
     for cell in t.tiles:
      if not cell.block and at(cell.x,cell.y)==null:
       u.x=cell.x;u.y=cell.y
       break
    t.units.append(u)
    count+=1
 refresh_knowledge()

func make_unit(id: String, team: String, p: Dictionary, x: int, y: int) -> Dictionary:
 return {"id":id,"team":team,"person":p,"x":x,"y":y,"ap":Data.ap(p),"stance":"stand","mode":"walk","facing":0 if team=="company" else 4,"guard":false,"reason":"guarding"}

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
 return t.turn == u.team and u.person.hp>10 and outcome()=="ongoing"

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

func step_cost(u: Dictionary, from: Dictionary, dest: Dictionary) -> int:
 if dest.is_empty() or dest.block or at(dest.x,dest.y,u.id)!=null: return -1
 var dx=dest.x-from.x
 var dy=dest.y-from.y
 if absi(dx)>1 or absi(dy)>1 or (dx==0 and dy==0): return -1
 if dx!=0 and dy!=0:
  var a=tile(from.x+dx,from.y)
  var b=tile(from.x,from.y+dy)
  if a.is_empty() or b.is_empty() or a.block or b.block or at(a.x,a.y,u.id)!=null or at(b.x,b.y,u.id)!=null: return -1
 if absi(dest.elevation-from.elevation)>1: return -1
 var cost=dest.cost+maxi(0,dest.elevation-from.elevation)*2
 if dx!=0 and dy!=0: cost=int(ceil(cost*1.4))
 if u.stance=="crouch": cost+=1
 if u.stance=="prone": cost+=3
 if u.mode=="run": cost=maxi(1,cost-1)
 if u.mode=="cautious": cost+=1
 return cost

func path(u: Dictionary,x: int,y: int) -> Dictionary:
 var goal=tile(x,y)
 if goal.is_empty() or goal.block or at(x,y,u.id)!=null: return {"path":[],"cost":-1}
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
  var from=t.tiles[pos]
  for dy in range(-1,2):
   for dx in range(-1,2):
    var dest=tile(from.x+dx,from.y+dy)
    var c=step_cost(u,from,dest)
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
 for team in ["company","enemy"]:
  for key in t.knowledge[team]: t.knowledge[team][key].visible=false
  for observer in t.units:
   if observer.team!=team or observer.person.hp<=10: continue
   for other in t.units:
    if other.team==team or other.person.hp<=0: continue
    if visible(observer,other):
     t.knowledge[team][other.id]={"x":other.x,"y":other.y,"round":t.round,"visible":true}

func known(team: String,id: String) -> bool:
 return t.knowledge[team].has(id) and t.knowledge[team][id].visible

func move(u: Dictionary,x: int,y: int) -> bool:
 error=""
 if not can_act(u): return fail("Unit cannot act")
 var preview=path(u,x,y)
 if preview.cost<=0 or preview.cost>u.ap: return fail("Unreachable or insufficient AP")
 # Step execution permits reactions and halts on new contact, matching path costs.
 for index in preview.path:
  var dest=t.tiles[index]
  var cost=step_cost(u,tile(u.x,u.y),dest)
  if cost<0 or cost>u.ap: break
  for enemy in t.units:
   if enemy.team==u.team or enemy.person.hp<=10 or not enemy.guard: continue
   var w=Data.WEAPONS[Data.weapon(enemy.person)]
   if w.reach>0 and distance(enemy,u)<=w.reach and maxi(absi(enemy.x-dest.x),absi(enemy.y-dest.y))>w.reach:
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
 var chance=50+int(skill*0.6)-int(b.person.agility*0.25)+w.accuracy+aim*7
 chance-=int(a.person.fatigue/5)+int((a.person.max_hp-a.person.hp)/5)
 chance+=int((a.person.morale-50)/10)+int(a.person.experience*2)
 chance+=5*(tile(a.x,a.y).elevation-tile(b.x,b.y).elevation)
 if ranged:
  chance-=maxi(0,d-w.effective)*7
  chance-=tile(b.x,b.y).cover+tile(b.x,b.y).conceal
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
 if aim<0 or aim>3: return fail("Aim must be 0 to 3")
 if a.team==b.team or a.person.hp<=10 or b.person.hp<=0: return fail("Invalid combatants")
 if not reaction and not can_act(a): return fail("Unit cannot act")
 var w=Data.WEAPONS[Data.weapon(a.person)]
 var ranged=w.reach==0
 var cost=w.ap+aim
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
 t.noise.append({"x":a.x,"y":a.y,"round":t.round,"team":a.team})
 if campaign.roll(100)>=chance:
  log_event(a.person.name+" missed (%d%%)" % chance)
  return true
 var defence=""
 var back=rear(a,b)
 if not back and b.ap>=2 and b.person.hp>10 and b.person.morale>=20:
  var shield=Data.equipped(b.person,"shield")
  var block=int((20+b.person.dexterity/4.0)*shield.condition/100.0) if not shield.is_empty() else 0
  if block>0 and campaign.roll(100)<block:
   b.ap-=2
   shield.condition=maxi(0,shield.condition-1)
   defence="shield block"
  elif not ranged and Data.WEAPONS[Data.weapon(b.person)].defence>0 and campaign.roll(100)<int(b.person.melee/5)+Data.WEAPONS[Data.weapon(b.person)].defence:
   b.ap-=2
   var parrying=Data.equipped(b.person,"weapon")
   parrying.condition=maxi(0,parrying.condition-1)
   defence="parry"
  elif campaign.roll(100)<int(b.person.agility/7):
   b.ap-=2
   defence="dodge"
 if defence!="":
  log_event(b.person.name+" used "+defence+" (2 AP)")
  return true
 var raw=w.damage+int(a.person.strength/12) if not ranged else w.damage
 raw=int(raw*(0.65+Data.condition(a.person)/285.0))
 var location=["torso","torso","arms","legs","head"][campaign.roll(5)]
 var body=Data.equipped(b.person,"body")
 var armour=int(Data.ARMOUR[Data.armour(b.person)][w.kind]*body.get("condition",100)/100.0)
 if location=="head":
  armour=int(8*Data.equipped(b.person,"helmet").get("condition",0)/100.0)
  raw=int(raw*1.3)
 var damage=maxi(1,raw-armour)
 var protection=Data.equipped(b.person,"helmet") if location=="head" else body
 if armour>0 and not protection.is_empty(): protection.condition=maxi(0,protection.condition-1)
 b.person.hp=maxi(0,b.person.hp-damage)
 b.person.wounds+=1
 if w.kind!="blunt": b.person.bleeding+=maxi(1,int(damage/14))
 b.person.morale=maxi(0,b.person.morale-8-int(damage/5))
 a.person.morale=mini(100,a.person.morale+2)
 if b.person.hp==0:
  b.person.dead=true
  a.person.kills+=1
  if int(a.person.kills)%3==0: a.person.experience+=1
  for other in t.units:
   if other.team==b.team and distance(other,b)<7: other.person.morale=maxi(0,other.person.morale-12)
  campaign.drop_inventory(b.person,b.x,b.y,t.ground)
 log_event("%s hit %s %s: %d - %d armour = %d (%d%%)" % [a.person.name,b.person.name,location,raw,armour,damage,chance])
 refresh_knowledge()
 return true

func action(id: String,kind: String,p: Dictionary={}) -> bool:
 error=""
 var u=unit(id)
 if u==null or not can_act(u): return fail("Select an active unit")
 match kind:
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
   if target==null or target.team!=u.team or target.person.hp<=0 or distance(u,target)>1 or u.ap<5 or campaign.s.medicine<=0: return fail("Need nearby survivor, medicine and 5 AP")
   u.ap-=5
   campaign.s.medicine-=1
   target.person.bleeding=0
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
 var friends=0
 var enemies=0
 for u in t.units:
  if u.person.hp>10:
   if u.team=="company": friends+=1
   else: enemies+=1
 if friends==0: return "defeat"
 if enemies==0: return "victory"
 return "ongoing"

func start_turn(team: String) -> void:
 t.turn=team
 for u in t.units:
  if u.team!=team: continue
  if u.person.hp>0 and u.person.bleeding>0:
   u.person.hp=maxi(0,u.person.hp-u.person.bleeding)
   if u.person.hp==0:
    u.person.dead=true
    campaign.drop_inventory(u.person,u.x,u.y,t.ground)
  u.ap=Data.ap(u.person)
  u.guard=false
 refresh_knowledge()

func end_turn() -> bool:
 if t.turn!="company" or outcome()!="ongoing": return fail("No active player turn")
 start_turn("enemy")
 t.ai=[]
 for u in t.units:
  if u.team=="enemy" and u.person.hp>10 and outcome()=="ongoing": ai_unit(u)
 t.round+=1
 start_turn("company")
 return true

func ai_unit(u: Dictionary) -> void:
 # Only perceived opponents and stored coordinates can inform decisions.
 var budget=24
 while u.ap>0 and u.person.hp>10 and budget>0 and outcome()=="ongoing":
  budget-=1
  refresh_knowledge()
  var targets=[]
  for id in t.knowledge[u.team]:
   if known(u.team,id):
    var candidate=unit(id)
    if candidate!=null and candidate.person.hp>10: targets.append(candidate)
  targets.sort_custom(func(a,b):return distance(u,a)<distance(u,b))
  var w=Data.WEAPONS[Data.weapon(u.person)]
  if u.person.morale<15:
   u.reason="morale retreat"
   var retreat=path(u,mini(t.width-1,u.x+1),u.y)
   if retreat.cost>0 and retreat.cost<=u.ap: move(u,mini(t.width-1,u.x+1),u.y)
   break
  if w.reach==0 and not u.person.loaded and Data.ammo(u.person)>0 and u.ap>=w.reload:
   u.ap-=w.reload
   u.person.loaded=true
   u.reason="reload"
   continue
  var target=targets[0] if not targets.is_empty() else null
  if target!=null and distance(u,target)<=w.range and u.ap>=w.ap:
   if attack(u,target):
    u.reason="attack perceived opponent"
    continue
  var goal={}
  if target!=null: goal={"x":target.x,"y":target.y}
  elif not t.knowledge[u.team].is_empty():
   for id in t.knowledge[u.team]: goal=t.knowledge[u.team][id]
   u.reason="investigate last known position"
  else:
   for noise in t.noise:
    if noise.team!=u.team and t.round-noise.round<=2 and distance(u,noise)<=10:
     goal=noise
     u.reason="investigate heard sound"
   if goal.is_empty():
    goal={"x":maxi(1,u.x-1),"y":u.y}
    u.reason="patrol west"
  var best={}
  var score=-100000.0
  for dy in range(-1,2):
   for dx in range(-1,2):
    var cell=tile(u.x+dx,u.y+dy)
    var cost=step_cost(u,tile(u.x,u.y),cell)
    if cost<0 or cost>u.ap: continue
    var d=distance(cell,goal)
    var value=-d*10.0-cost+cell.cover*0.2+cell.elevation*2
    if target!=null and w.reach==0 and d<3: value-=40
    if value>score:
     score=value
     best=cell
  if best.is_empty():
   # Doors use the exact same action validation as a player.
   if u.ap>=3:
    for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
     var cell=tile(u.x+d.x,u.y+d.y)
     if not cell.is_empty() and cell.door and not cell.open:
      action(u.id,"door",{"x":cell.x,"y":cell.y})
      u.reason="open obstructing door"
      break
   break
  if not move(u,best.x,best.y): break
  if target!=null: u.reason="reposition toward perceived threat"
 u.guard=true
 t.ai.append({"id":u.id,"reason":u.reason,"remaining_ap":u.ap})
