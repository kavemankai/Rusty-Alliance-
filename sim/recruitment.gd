extends RefCounted
const Data=preload("res://sim/catalog.gd")
const R=preload("res://sim/records.gd")
const PURSE=2400
const ROSTER_FILE="res://data/greywake_roster.json"

static func workshop_templates() -> Array:
 if not FileAccess.file_exists(ROSTER_FILE): return []
 var doc=JSON.parse_string(FileAccess.get_file_as_string(ROSTER_FILE))
 if not doc is Dictionary or not doc.get("templates") is Array: return []
 return doc.templates if valid_templates(doc.templates) else []

static func valid_templates(rows: Variant) -> bool:
 if not rows is Array or rows.size()!=12: return false
 var counts={"cheap":0,"mid":0,"high":0,"elite":0};var ids={};var names={}
 for row in rows:
  if not row is Dictionary or not row.has_all(["id","name","tier","repeatable","background","weapon","fee","wage","attributes","skills"]): return false
  if not row.id is String or row.id=="" or row.id.length()>80 or not row.name is String or row.name=="" or row.name.length()>120 or ids.has(row.id) or names.has(row.name): return false
  if row.tier not in counts or not row.repeatable is bool or row.repeatable!=(row.tier=="cheap"): return false
  if row.background not in Data.BACKGROUNDS or row.weapon not in Data.WEAPONS: return false
  if not R.integer(row.fee,1,1000000) or not R.integer(row.wage,1,1000000) or (row.tier=="elite" and row.fee<=PURSE): return false
  if not row.attributes is Dictionary or not row.skills is Dictionary or row.attributes.size()!=7 or row.skills.size()!=7: return false
  for key in Data.Skills.ATTRIBUTES:
   if not R.integer(row.attributes.get(key),1,100): return false
  for key in Data.Skills.ALL:
   if not R.integer(row.skills.get(key),0,100): return false
  if row.has("armour") and row.armour not in Data.ARMOUR: return false
  for flag in ["shield","helmet"]:
   if row.has(flag) and not row[flag] is bool: return false
  for stat in ["max_hp","experience"]:
   if row.has(stat) and not R.integer(row[stat],1,1000): return false
  ids[row.id]=true;names[row.name]=true;counts[row.tier]+=1
 return counts=={"cheap":2,"mid":4,"high":4,"elite":2}

static func make_person(row: Dictionary,id: String,title: String) -> Dictionary:
 var person=Data.person(id,title,row.background,row.weapon)
 person.merge(row.attributes,true);person.merge(row.skills,true)
 person.fee=int(row.fee);person.wage=int(row.wage);person.template_id=row.id;person.tier=row.tier
 if row.has("max_hp"): person.max_hp=int(row.max_hp);person.hp=person.max_hp
 if row.has("experience"): person.experience=int(row.experience)
 if row.has("armour"): Data.equipped(person,"body").kind=row.armour
 for kind in ["shield","helmet"]:
  if row.get(kind,false):
   var entry=Data.item(id+":"+kind,kind);person.inventory.append(entry);person.equipment[kind]=entry.id
 return person

static func configure(state: Dictionary,rows: Array) -> Dictionary:
 if not valid_templates(rows): return {}
 var fresh=state.duplicate(true)
 fresh.scenario="greywake";fresh.recruitment={"templates":rows.duplicate(true),"next_id":1}
 fresh.mercs={};fresh.funds=PURSE;fresh.squads.first.members=[];fresh.squads.first.leader=""
 fresh.events=fresh.events.filter(func(e):return e.kind!="employment")
 fresh.ledger=[R.Transaction.new(fresh.time,0,"Greywake opening purse",PURSE).pack()]
 fresh.log=["Greywake: choose a starting company. Hiring fees and daily wages are separate; opening purse 2,400 crowns."]
 for row in rows:
  if not row.repeatable:
   var person=make_person(row,"greywake-named-"+row.id,row.name);fresh.mercs[person.id]=person
 return fresh

static func recruit(c,template_id: String,squad_id: String) -> bool:
 if c.s.get("scenario","")!="greywake" or not c.s.has("recruitment"): return c.reject("Repeatable recruitment belongs to Greywake")
 if c.battle!=null: return c.reject("Resolve battle first")
 var row={}
 for entry in c.s.recruitment.templates:
  if entry.id==template_id: row=entry;break
 if row.is_empty() or not row.repeatable: return c.reject("Choose a repeatable cheap archetype")
 var squad=c.s.squads.get(squad_id,{})
 if squad.is_empty() or squad.sector!=17 or not squad.route.is_empty() or c.s.sectors[17].owner!="company" or c.s.funds<row.fee: return c.reject("Recruit at controlled Ashford with sufficient hiring funds")
 if c.s.mercs.size()>=4096: return c.reject("Campaign profile storage is full")
 var counter=int(c.s.recruitment.next_id);var names={}
 for person in c.s.mercs.values(): names[person.name]=true
 var id="greywake-recruit-%08d" % counter
 var title="Hireling %08d · %s" % [counter,row.name]
 while c.s.mercs.has(id) or names.has(title):
  counter+=1;id="greywake-recruit-%08d" % counter;title="Hireling %08d · %s" % [counter,row.name]
 if counter>=1000000000: return c.reject("Recruit identity storage is full")
 var person=make_person(row,id,title)
 # All conditions are checked before money, counters, people or items change.
 c.record(-person.fee,"Hire "+person.name)
 person.hired=true;person.expires=c.s.time+7*1440
 c.s.mercs[id]=person;c.s.recruitment.next_id=counter+1;squad.members.append(id)
 if squad.leader=="": squad.leader=id
 c.schedule(person.expires,"employment",{"id":id});c.note(person.name+" recruited as an individual")
 return true

static func valid_state(state: Dictionary) -> bool:
 if state.get("scenario","original")=="original": return not state.has("recruitment")
 if state.get("scenario")!="greywake" or not state.get("recruitment") is Dictionary: return false
 var registry=state.recruitment
 if not valid_templates(registry.get("templates")) or not R.integer(registry.get("next_id"),1,1000000000): return false
 var names={};var named={};var types={}
 for row in registry.templates: types[row.id]=row
 for person in state.mercs.values():
  if names.has(person.name) or not types.has(person.get("template_id","")): return false
  names[person.name]=true
  var row=types[person.template_id]
  if person.get("tier")!=row.tier: return false
  if person.fee!=row.fee or person.wage!=row.wage: return false
  if not row.repeatable:
   if named.has(row.id) or person.id!="greywake-named-"+row.id or person.name!=row.name: return false
   named[row.id]=true
  else:
   if not person.id.begins_with("greywake-recruit-"): return false
   var serial=person.id.trim_prefix("greywake-recruit-")
   if not serial.is_valid_int() or int(serial)<1 or int(serial)>=registry.next_id: return false
 return named.size()==10
