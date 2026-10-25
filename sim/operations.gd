extends RefCounted
const Data=preload("res://sim/catalog.gd")
const Items=preload("res://sim/inventory.gd")
const Layouts=preload("res://sim/battlefields.gd")

static func run(c,kind: String,p: Dictionary) -> bool:
 var q=c.s.squads.get(p.get("squad","first"),{})
 if kind=="leave":
  if c.battle==null or not c.battle.t.get("peaceful",false): return c.reject("Leave only a peaceful visit; use retreat during hostile contact")
  c.s.sectors[c.s.encounter.sector].battlefield=c.battle.field_state()
  for u in c.battle.t.units:
   if u.team=="company" and u.role=="merc" and u.person.hp<=0: c.remove_member(u.id)
  c.battle=null;c.s.battle={};c.next_encounter();c.save_to(c.autosave_path)
  return true
 if c.battle!=null or not c.s.encounter.is_empty(): return c.reject("Finish the tactical visit or encounter first")
 if q.is_empty() or not q.route.is_empty() or q.members.is_empty(): return c.reject("Select a stationary staffed squad")
 if kind=="visit":
  if c.hostile_at(q.sector): return c.reject("Hostile forces require deployment")
  c.s.encounter={"squad":q.id,"sector":q.sector,"from":q.sector,"peaceful":true}
  c.battle=c.Battle.new(c);c.s.battle=c.battle.t
  c.battle.t.peaceful=true;c.battle.Exploration.begin(c.battle)
  return true
 if kind=="transport":
  if q.sector!=17: return c.reject("Buy or sell transport at Ashford")
  var asset=p.get("asset","")
  if asset not in ["horses","carts"]: return c.reject("Choose horses or carts")
  var owned=q.get("transport",{"horses":0,"carts":0})
  var price=120 if asset=="horses" else 160
  if p.get("sell",false):
   if owned[asset]<1: return c.reject("No transport asset to sell")
   owned[asset]-=1;c.record(int(price/2),"Sell "+asset)
  else:
   if c.s.funds<price: return c.reject("Insufficient transport funds")
   c.record(-price,"Buy "+asset);owned[asset]+=1
  q.transport=owned
  return true
 if kind=="prisoner":
  if c.s.sectors[q.sector].owner!="company": return c.reject("Handle prisoners at a controlled sector")
  for g in c.s.groups:
   for captive in g.fighters:
    if captive.id!=p.get("id","") or not captive.get("captured",false) or captive.get("released",false) or captive.hp<=0 or captive.get("captured_sector",g.sector)!=q.sector: continue
    var choice=p.get("choice","")
    if choice not in ["release","ransom","recruit"]: return c.reject("Choose release, ransom or recruitment")
    if choice=="recruit":
     if c.s.funds<150: return c.reject("Recruitment requires 150 crowns")
     c.record(-150,"Prisoner enlistment")
     g.fighters.erase(captive);g.losses_accounted=maxi(0,g.get("losses_accounted",0)-1)
     captive.captured=false;captive.released=false;captive.hired=true;captive.dead=false;captive.morale=25;captive.expires=c.s.time+10080
     c.s.mercs[captive.id]=captive;q.members.append(captive.id)
     c.schedule(captive.expires,"employment",{"id":captive.id})
    else:
     captive.captured=false;captive.released=true
     if choice=="ransom": c.record(50,"Prisoner ransom")
    c.note(captive.name+": "+choice)
    return true
  return c.reject("No living detained prisoner here")
 return c.reject("Unknown operation")

static func rescue(c,index: int) -> void:
 var squads=c.combat_squads(index)
 if squads.is_empty(): return
 for captive in c.s.mercs.values():
  if not captive.get("captured",false) or captive.get("captured_sector",-1)!=index or captive.hp<=0: continue
  captive.captured=false;captive.hired=true;captive.expires=maxi(captive.expires,c.s.time+1440)
  squads[0].members.append(captive.id)
  c.schedule(captive.expires,"employment",{"id":captive.id})
  c.note(captive.name+" rescued and reunited locally")

static func build(b,u: Dictionary,p: Dictionary) -> bool:
 if not b.t.get("peaceful",false) or b.campaign.s.sectors[b.campaign.s.encounter.sector].owner!="company": return b.fail("Build during a peaceful visit to a controlled sector")
 var cell=b.tile(p.get("x",-1),p.get("y",-1));var kind=p.get("kind","")
 if kind not in ["barricade","palisade","gate","torch"] or cell.is_empty() or cell.block or b.at(cell.x,cell.y)!=null or b.distance(u,cell)>1 or u.ap<8: return b.fail("Build on an adjacent empty tile for 8 AP, 3 tools and 20 crowns")
 var supplies=b.Supplies.for_person(b.campaign.s,u.id)
 if supplies.get("tools",0)<3 or b.campaign.s.funds<20: return b.fail("Need three local tools and twenty crowns")
 supplies.tools-=3;b.campaign.record(-20,"Construct "+kind);u.ap-=8
 cell.kind="door" if kind=="gate" else kind;cell.block=kind in ["palisade","gate"];cell.door=kind=="gate";cell.open=false
 cell.cover=35 if kind=="barricade" else 0;cell.cover_edge=u.facing
 if kind=="torch": cell.light=3
 b.refresh_knowledge()
 return true
