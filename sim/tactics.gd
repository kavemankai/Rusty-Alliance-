extends RefCounted

static func memory_goal(b,u: Dictionary,state: Dictionary) -> Dictionary:
 var ids=b.t.knowledge[u.team].keys();ids.sort()
 var best={};var recent=-1
 for id in ids:
  var info=b.t.knowledge[u.team][id]
  var key=id+":"+str(info.round)
  if info.visible or b.t.round-info.round>3 or state.get("searched","")==key: continue
  if info.round>recent:
   recent=info.round;best={"x":info.x,"y":info.y,"memory_key":key}
 if not best.is_empty() and b.distance(u,best)<=1:
  state.searched=best.memory_key
  return {}
 return best

static func wounded_ally(b,u: Dictionary):
 var ally=null;var range_to=7
 for other in b.t.units:
  if other.id==u.id or other.team!=u.team or other.person.hp<=10 or other.person.hp*2>=other.person.max_hp: continue
  var d=b.distance(u,other)
  if d<range_to: ally=other;range_to=d
 return ally

static func cover_step(b,u: Dictionary,target: Dictionary,weapon: Dictionary) -> Dictionary:
 var best={};var improvement=9
 var current=b.directional_cover(target,u)
 for dy in range(-1,2):
  for dx in range(-1,2):
   var cell=b.tile(u.x+dx,u.y+dy)
   var cost=b.step_cost(u,b.tile(u.x,u.y),cell)
   if cost<0 or cost+weapon.ap>u.ap: continue
   var candidate=u.duplicate();candidate.x=cell.x;candidate.y=cell.y
   if b.distance(candidate,target)>weapon.range or not b.los(candidate,target): continue
   var gain=b.directional_cover(target,candidate)-current-cost
   if gain>improvement: improvement=gain;best=cell
 return best

static func act(b,u: Dictionary) -> void:
 if b.t.phase!="combat" or not b.can_act(u): return
 var state=b.t.ai_state.get(u.id,{})
 b.t.ai_state[u.id]=state
 var actions=[];var covered=false
 var budget=24
 while u.ap>0 and u.person.hp>10 and budget>0 and b.outcome()=="ongoing":
  budget-=1
  b.refresh_knowledge()
  var targets=[]
  # Current coordinates are read only for opponents currently perceived by team.
  for id in b.t.knowledge[u.team]:
   if b.known(u.team,id):
    var candidate=b.unit(id)
    if candidate!=null and candidate.person.hp>10: targets.append(candidate)
  var ally=wounded_ally(b,u)
  targets.sort_custom(func(a,z):return b.distance(a,ally if ally!=null else u)<b.distance(z,ally if ally!=null else u))
  var target=targets[0] if not targets.is_empty() else null
  var w=b.Data.WEAPONS[b.Data.weapon(u.person)]
  if u.person.morale<15:
   var best={};var safety=-9999
   for dy in range(-1,2):
    for dx in range(-1,2):
     var cell=b.tile(u.x+dx,u.y+dy)
     var cost=b.step_cost(u,b.tile(u.x,u.y),cell)
     if cost<0 or cost>u.ap: continue
     var value=(b.distance(cell,target) if target!=null else (cell.x if u.team=="enemy" else -cell.x))*10-cost
     if value>safety: safety=value;best=cell
   if not best.is_empty(): b.move(u,best.x,best.y)
   u.reason="morale retreat";actions.append(u.reason);break
  if w.reach==0 and not u.person.loaded and b.Data.ammo(u.person)>0 and u.ap>=w.reload:
   if b.action(u.id,"reload"): u.reason="reload";actions.append(u.reason);continue
  if target!=null:
   if w.reach==0 and not covered:
    var sheltered=cover_step(b,u,target,w)
    if not sheltered.is_empty() and b.move(u,sheltered.x,sheltered.y):
     covered=true;u.reason="take directional cover";actions.append(u.reason);continue
   if b.distance(u,target)<=w.range and u.ap>=w.ap and b.attack(u,target):
    u.reason="support wounded ally" if ally!=null else "attack perceived opponent"
    actions.append(u.reason);continue
  var goal={}
  if target!=null: goal={"x":target.x,"y":target.y}
  else:
   goal=memory_goal(b,u,state)
   if not goal.is_empty(): u.reason="investigate last seen contact"
   if goal.is_empty():
    for noise in b.t.noise:
     if noise.team!=u.team and b.t.round-noise.round<=2 and b.distance(u,noise)<=10:
      goal={"x":noise.x,"y":noise.y};u.reason="investigate sound"
   if goal.is_empty() and ally!=null:
    if b.distance(u,ally)<=1: u.reason="guard wounded ally";actions.append(u.reason);break
    goal={"x":ally.x,"y":ally.y};u.reason="support wounded ally"
   if goal.is_empty():
    goal={"x":maxi(1,u.x-1) if u.team=="enemy" else mini(b.t.width-2,u.x+1),"y":u.y}
    u.reason="patrol"
  state.goal={"x":goal.x,"y":goal.y}
  # Navigation looks for a route to a reachable neighbour of an occupied goal.
  var waypoint={};var approaches=[]
  for dy in range(-1,2):
   for dx in range(-1,2):
    var cell=b.tile(goal.x+dx,goal.y+dy)
    if not cell.is_empty() and not cell.block and b.at(cell.x,cell.y,u.id)==null: approaches.append(cell)
  approaches.sort_custom(func(a,z):return b.distance(u,a)<b.distance(u,z))
  for cell in approaches:
   var route=b.path(u,cell.x,cell.y)
   if route.cost>0 and not route.path.is_empty():
    waypoint=b.t.tiles[route.path[0]];break
  var best={};var score=-99999.0
  for dy in range(-1,2):
   for dx in range(-1,2):
    var cell=b.tile(u.x+dx,u.y+dy)
    var cost=b.step_cost(u,b.tile(u.x,u.y),cell)
    if cost<0 or cost>u.ap: continue
    var value=-b.distance(cell,goal)*10-cost
    if not waypoint.is_empty() and cell.x==waypoint.x and cell.y==waypoint.y: value+=12
    if target!=null:
     var candidate=u.duplicate();candidate.x=cell.x;candidate.y=cell.y
     value+=b.directional_cover(target,candidate)*0.3
     if w.reach==0 and b.distance(cell,target)<3: value-=35
    if value>score: score=value;best=cell
  if best.is_empty():
   for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
    var cell=b.tile(u.x+d.x,u.y+d.y)
    if not cell.is_empty() and cell.door and not cell.open and b.action(u.id,"door",{"x":cell.x,"y":cell.y}):
     u.reason="open obstructing door";actions.append(u.reason);break
   break
  if not b.move(u,best.x,best.y): break
  if target!=null: u.reason="coordinate against visible threat" if ally!=null else "approach perceived opponent"
  actions.append(u.reason)
 u.guard=true
 state.actions=actions
 b.t.ai.append({"id":u.id,"reason":u.reason,"remaining_ap":u.ap,"actions":actions})

static func valid(t: Dictionary) -> bool:
 if not t.has("ai_state"): return true
 if not t.ai_state is Dictionary: return false
 var ids={}
 for u in t.units: ids[u.id]=true
 for id in t.ai_state:
  var state=t.ai_state[id]
  if not ids.has(id) or not state is Dictionary: return false
  if state.has("searched") and not state.searched is String: return false
  if state.has("goal"):
   var p=state.goal
   if not p is Dictionary or not p.has_all(["x","y"]): return false
   if not (p.x is int or p.x is float) or not (p.y is int or p.y is float) or p.x!=floor(p.x) or p.y!=floor(p.y) or p.x<0 or p.y<0 or p.x>=t.width or p.y>=t.height: return false
  if state.has("actions"):
   if not state.actions is Array or state.actions.size()>24: return false
   for action in state.actions:
    if not action is String: return false
 return true
