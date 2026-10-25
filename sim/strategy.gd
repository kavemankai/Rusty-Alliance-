extends RefCounted
const Data=preload("res://sim/catalog.gd")
const Layouts=preload("res://sim/battlefields.gd")

static func daily(c) -> void:
 if not c.s.has("next_force"): c.s.next_force=1
 for faction in ["bandits","nobles"]:
  var f=c.s.factions[faction]
  var income=0;var upkeep=0
  for sector in c.s.sectors:
   if sector.owner==faction: income+=30 if sector.facility=="mine" else (20 if sector.facility=="farm" else (10 if sector.facility in ["camp","garrison"] else 0))
  for group in c.s.groups:
   if group.faction==faction: upkeep+=c.force_strength(group)*3
  f.resources=maxi(0,f.resources+income-upkeep)
  if not f.has("history"): f.history=[]
  f.history.append({"time":c.s.time,"income":income,"upkeep":upkeep,"balance":f.resources})
  if f.history.size()>90: f.history.pop_front()
  # Recruitment requires an existing command group physically at its base.
  for group in c.s.groups:
   if group.faction!=faction or c.force_strength(group)<=0 or c.force_strength(group)>=6: continue
   var base=c.s.sectors[group.sector]
   if base.owner!=faction or base.facility not in ["camp","garrison"] or f.resources<60: continue
   if not c.s.encounter.is_empty() and c.s.encounter.sector==base.id: continue
   var id="reinforcement_%d" % c.s.next_force;c.s.next_force+=1
   group.fighters.append(Data.hostile(id,group.fighters.size()))
   f.resources-=60
   f.history.append({"time":c.s.time,"recruit":id,"sector":base.id,"cost":60,"balance":f.resources})
   while f.history.size()>90: f.history.pop_front()
   c.note(faction+" recruited a budgeted defender at "+base.name)
   break

static func orders(c,g: Dictionary) -> void:
 var f=c.s.factions[g.faction]
 if not g.has("patrol_origin"): g.patrol_origin=g.sector
 if not f.has("intel"): f.intel={}
 var observed=c.neighbors(g.sector);observed.append(g.sector)
 for index in observed:
  var strength=0
  for q in c.s.squads.values():
   if q.sector!=index: continue
   for id in q.members:
    if c.s.mercs[id].hp>10: strength+=1
  if strength>0 or c.s.sectors[index].owner=="company": f.intel[str(index)]={"sector":index,"strength":strength,"time":c.s.time}
 for key in f.intel.keys():
  if c.s.time-f.intel[key].time>2880: f.intel.erase(key)
 if g.get("stationary",false): g.order="defend";return
 var threat={};var score=-9999
 for info in f.intel.values():
  var sector=c.s.sectors[info.sector]
  var distance=absi(int(g.sector)%16-int(info.sector)%16)+absi(int(g.sector)/16-int(info.sector)/16)
  var value=(20 if sector.facility!="" else 5)-distance*3
  if value>score: score=value;threat=info
 if not threat.is_empty():
  if threat.strength>c.force_strength(g)*2:
   var home=-1;var distance=999
   for sector in c.s.sectors:
    if sector.owner!=g.faction or sector.facility not in ["camp","garrison"]: continue
    var d=absi(int(g.sector)%16-int(sector.id)%16)+absi(int(g.sector)/16-int(sector.id)/16)
    if d<distance: distance=d;home=sector.id
   if home>=0: g.objective=home;g.order="withdraw";return
  g.objective=threat.sector;g.order="respond" if c.s.sectors[threat.sector].owner==g.faction else "raid"
 else:
  g.order="patrol" if g.id.contains("patrol") else "raid"
  if g.order=="patrol" and g.sector==g.objective and c.s.sectors[g.sector].owner==g.faction:
   g.objective=g.patrol_origin if g.sector!=g.patrol_origin else 34

static func clash(c,g: Dictionary) -> void:
 for other in c.s.groups:
  if other==g or other.faction==g.faction or other.sector!=g.sector or c.force_strength(other)<=0: continue
  var a=c.force_strength(g);var b=c.force_strength(other)
  var winner=g if a>=b else other;var loser=other if a>=b else g
  c.group_losses(loser,c.force_strength(loser))
  c.group_losses(winner,maxi(0,int(mini(a,b)/2)))
  var sector=c.s.sectors[g.sector]
  if not sector.has("battlefield"): sector.battlefield=Layouts.create(sector)
  for army in [g,other]:
   for person in army.fighters:
    if person.hp<=0 and not person.inventory.is_empty():
     var placement={"x":12,"y":6}
     for cell in sector.battlefield.tiles:
      if not cell.block and cell.x>=10: placement=cell;break
     c.drop_inventory(person,placement.x,placement.y,sector.battlefield.ground)
  sector.owner=winner.faction
  c.note("Army clash at "+sector.name+": "+winner.faction+" prevailed with persistent casualties")
  if c.force_strength(g)<=0: return
