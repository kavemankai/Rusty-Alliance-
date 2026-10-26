extends RefCounted
const FILE="res://data/greywake_island.json"
static func content() -> Dictionary: return JSON.parse_string(FileAccess.get_file_as_string(FILE))
static func applies(s: Dictionary) -> bool: return s.get("scenario")=="fall_of_greywake" and s.get("greywake",{}).get("world_mode")=="island_v1"
static func land(index: int,mask: Array=[]) -> bool:
 if index<0 or index>=256 or index%16>=10 or int(index/16)>=10: return false
 var rows=content().mask if mask.is_empty() else mask
 return rows[int(index/16)].substr(index%16,1)=="#"
static func passable(s: Dictionary,index: int) -> bool: return not applies(s) or (index>=0 and index<256 and s.sectors[index].get("greywake_land",false))
static func install(c) -> void:
 var doc=content();c.s.greywake.world_mode="island_v1";c.s.greywake.world_version=1
 var terrain={"M":"marsh","R":"road","G":"grass","F":"forest","H":"hills"}
 for cell in c.s.sectors:
  cell.greywake_land=land(cell.id,doc.mask);cell.owner="free";cell.facility="";cell.known=false;cell.name="Open sea"
  if cell.greywake_land:
   cell.terrain=terrain[doc.terrain[cell.y].substr(cell.x,1)];cell.name={"road":"Island road","forest":"Woodland","hills":"Coastal hills","grass":"Open country","marsh":"Low ground"}[cell.terrain]
  else: cell.terrain="marsh"
 for id in doc.roads: c.s.sectors[int(id)].terrain="road"
 for location in doc.locations:
  var cell=c.s.sectors[int(location.sector)]
  cell.name=location.name;cell.facility=location.facility;cell.owner=location.owner;cell.greywake_location=location.id
 c.s.sectors[17].known=true
 for id in c.neighbors(17): c.s.sectors[id].known=true
static func location(index: int) -> Dictionary:
 for row in content().locations:
  if int(row.sector)==index: return row
 return {}
static func can_upgrade(s: Dictionary) -> bool:
 if s.get("scenario")!="fall_of_greywake" or s.get("greywake",{}).get("world_mode")!="dock_town_staging" or s.time!=480: return false
 if s.squads.size()!=1 or not s.squads.has("first"): return false
 if not s.battle.is_empty() or not s.encounter.is_empty() or not s.pending_encounters.is_empty() or not s.groups.is_empty() or not s.jobs.is_empty(): return false
 for q in s.squads.values():
  if q.sector!=17 or not q.route.is_empty(): return false
 for cell in s.sectors:
  if cell.has("battlefield") or not cell.levies.is_empty(): return false
 return true
static func valid(s: Dictionary) -> bool:
 if not applies(s): return true
 if s.greywake.get("world_version")!=1: return false
 var mask=content().mask
 for cell in s.sectors:
  if not cell.get("greywake_land") is bool or cell.greywake_land!=land(int(cell.id),mask): return false
  if not cell.greywake_land and (cell.facility!="" or not cell.levies.is_empty()): return false
 for q in s.squads.values():
  if not land(q.sector): return false
  for id in q.route:
   if not land(int(id)): return false
 for g in s.groups:
  if not land(int(g.sector)) or not land(int(g.objective)): return false
 for job in s.jobs:
  if not land(int(job.sector)) or not land(int(job.get("origin",17))): return false
  for id in job.get("waypoints",[]):
   if not land(int(id)): return false
 if not s.encounter.is_empty() and not land(int(s.encounter.sector)): return false
 for contact in s.pending_encounters:
  if not land(int(contact.sector)): return false
 for row in content().locations:
  var cell=s.sectors[int(row.sector)]
  if cell.get("greywake_location")!=row.id or cell.name!=row.name: return false
 return true
