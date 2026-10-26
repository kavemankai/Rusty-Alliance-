extends SceneTree
const C=preload("res://sim/campaign.gd")
const D=C.Data
const S=C.Shipping
var passed=0
var failures=[]
func _init() -> void: call_deferred("run")
func check(ok: bool,title: String) -> void:
 if ok: passed+=1
 else: failures.append(title);print("FAIL: "+title)
func fresh(depart: bool=true):
 var c=C.new();c.autosave_path="user://greywake-test-auto.json"
 check(c.configure_fall_of_greywake(),"Production scenario configures")
 if depart:
  check(c.command("recruit_template",{"template":"militia_spearman"}),"First opening recruit")
  check(c.command("recruit_template",{"template":"militia_spearman"}),"Second opening recruit")
  check(c.command("embark"),"Two-person departure")
 return c
func unchanged(c,kind: String,p: Dictionary,title: String) -> void:
 var before=JSON.stringify(c.s)
 check(not c.command(kind,p) and JSON.stringify(c.s)==before,title)
func travel(c,at: int) -> void:
 check(c.advance(at-c.s.time),"Clock advances to "+str(at))
func restore(c,path: String):
 check(c.save_to(path),"Save "+path)
 var loaded=C.new();loaded.autosave_path="user://greywake-test-auto.json"
 check(loaded.load_from(path),"Load "+path)
 return loaded
func run() -> void:
 var rows=C.Recruitment.workshop_templates()
 check(rows.size()==12,"All twelve authoritative templates load")
 var file=FileAccess.open("res://tests/fixtures/greywake-roster.txt",FileAccess.READ)
 var keys=file.get_csv_line();var n=0
 while not file.eof_reached():
  var values=file.get_csv_line()
  if values.size()!=keys.size(): continue
  var row=rows[n];n+=1
  for i in range(keys.size()):
   var expected=values[i]
   if keys[i] in ["id","name","tier"]: check(row[keys[i]]==expected,"Exact "+row.id+"/"+keys[i])
   elif keys[i]=="repeatable": check(row.repeatable==(expected=="true"),"Exact repeatability "+row.id)
   else: check(row[keys[i]]==int(expected),"Exact "+row.id+"/"+keys[i])
  var person=C.Recruitment.make_person(row,"golden-"+row.id,row.name)
  for key in D.Skills.ATTRIBUTES+D.Skills.ALL: check(person[key]==row[key],"Instantiated "+row.id+"/"+key)
  check(D.weapon(person)==row.weapon and D.armour(person)==row.armour,"Canonical loadout "+row.id)
  check(person.inventory.filter(func(item):return item.kind=="dagger").size()==(1 if row.id in ["nessa","ysra","sabine"] else 0),"Carried dagger "+row.id)
  for item in person.inventory:
   if item.kind=="ammo": check(item.ammo_type==D.ammo_kind_for(row.weapon) and item.quantity==16,"Typed ammunition "+row.id)
 var c=fresh(false)
 check(c.s.funds==2400 and c.s.squads.first.members.is_empty() and c.s.mercs.size()==10,"Empty opening company and exact purse")
 check(c.valid_save(c.s),"Empty selection valid for save")
 unchanged(c,"embark",{},"Empty departure rejected")
 unchanged(c,"advance",{"minutes":60},"Pre-voyage clock frozen")
 unchanged(c,"hire",{"id":"greywake-named-roderic"},"Roderic unaffordable")
 unchanged(c,"hire",{"id":"greywake-named-ysra"},"Ysra unaffordable")
 check(c.command("hire",{"id":"greywake-named-mara"}),"Named opening hire")
 unchanged(c,"embark",{},"One-person departure rejected")
 unchanged(c,"hire",{"id":"greywake-named-mara"},"Named opening duplication rejected")
 for i in range(5): check(c.command("recruit_template",{"template":"militia_crossbowman"}),"Repeatable opening slot "+str(i))
 check(c.s.funds==1350 and c.s.squads.first.members.size()==6,"Exact opening fees and six-person capacity")
 unchanged(c,"recruit_template",{"template":"militia_spearman"},"Seventh opening recruit rejected without consuming ID")
 var removed=c.s.squads.first.members[1];var counter=c.s.recruitment.next_id
 check(c.command("cancel_opening_hire",{"id":removed}) and c.s.funds==1490 and not c.s.mercs.has(removed),"Refund removes provisional owned kit")
 unchanged(c,"cancel_opening_hire",{"id":removed},"No duplicate refund")
 check(c.command("recruit_template",{"template":"militia_spearman"}) and c.s.recruitment.next_id==counter+1,"Cancelled ID is skipped permanently")
 c=restore(c,"user://greywake-selection-test.json")
 check(c.command("embark") and c.s.squads.first.sector==S.dock(c.s),"Chosen company lands together at Dock Town")
 c=restore(c,"user://greywake-landed-test.json")
 check(c.s.funds==1370 and c.s.opening_voyage.company==c.s.squads.first.members,"Opening funds and assignments persist")
 unchanged(c,"embark",{},"Departure cannot be repeated")
 unchanged(c,"hire",{"id":"greywake-named-oswin"},"Post-departure named shortcut blocked")
 unchanged(c,"recruit_template",{"template":"militia_spearman"},"Post-departure repeatable shortcut blocked")
 var ids={}
 for person in c.s.mercs.values():
  for item in person.inventory:
   check(not ids.has(item.id),"Unique owned item "+item.id);ids[item.id]=true
 var original=C.new()
 check(original.s.funds==1200 and original.s.squads.first.members==["mara","oswin"] and original.s.sectors[17].name=="Ashford market","Original campaign unchanged")
 check(original.command("hire",{"id":"ada"}) and original.valid_save(original.s),"Original direct recruitment preserved")
 check(restore(original,"user://greywake-original-test.json").s.squads.first.members==["mara","oswin","ada"],"Original save/load preserved")
 # Open arrival and persistent manifest.
 c=fresh();travel(c,S.FIRST_ARRIVAL)
 var v=c.s.shipping.vessels[0]
 check(v.status=="docked" and v.arrival_at==4680 and v.docked_at==4680 and v.recruitment_deadline==7560,"Day 4 06:00 open-port arrival")
 check(v.offers.size()>=2 and v.offers.size()<=4,"Persistent 2–4 passenger manifest")
 var copy=restore(c,"user://greywake-docked-test.json")
 check(copy.s.shipping==c.s.shipping,"Manifest identities stats equipment and prices survive load")
 var offer=v.offers[0]
 c.s.squads.first.sector=18
 unchanged(c,"hire_offer",{"offer":offer.id},"Inland hire fails atomically")
 c.s.squads.first.sector=17
 var funds=c.s.funds;c.record(-funds,"Test affordability")
 unchanged(c,"hire_offer",{"offer":offer.id},"Unaffordable offer fails atomically")
 c.record(funds,"Restore test funds")
 check(c.command("visit",{"squad":"first"}),"Peaceful tactical visit")
 unchanged(c,"hire_offer",{"offer":offer.id},"Active tactical encounter blocks hiring even at port")
 check(c.command("leave"),"Leave peaceful visit")
 check(c.command("hire_offer",{"offer":offer.id}),"Paid vessel hire succeeds")
 unchanged(c,"hire_offer",{"offer":offer.id},"Offer cannot be purchased twice")
 check(c.valid_save(c.s),"Hired manifest and owned inventory valid")
 var forged=c.s.duplicate(true)
 forged.shipping.vessels[0].offers[0].template_id="militia_crossbowman"
 for row in forged.recruitment.templates:
  if row.id=="militia_crossbowman":
   forged.shipping.vessels[0].offers[0].preview=row.duplicate(true)
   forged.shipping.vessels[0].offers[0].fee=row.fee;forged.shipping.vessels[0].offers[0].wage=row.wage
 check(not c.valid_save(forged),"Hired offer cannot be rebound to another character template")
 unchanged(c,"hire_offer",{"offer":42},"Malformed offer command rejected safely")
 var first_id=offer.person_id
 check(c.s.mercs[first_id].fee==offer.fee and c.s.mercs[first_id].wage==offer.wage and first_id in c.s.squads.first.members,"Employment binds reserved identity and squad")
 S.set_closure(c,"Authored harbour closure")
 var deadline=v.recruitment_deadline
 unchanged(c,"hire_offer",{"offer":v.offers[1].id},"Docked blockade suspends recruitment")
 check(v.status=="docked" and v.recruitment_deadline==deadline,"Docked blockade never resets window or becomes offshore")
 S.set_closure(c,"")
 check(v.status=="docked" and v.recruitment_deadline==deadline,"Reopening retains exact offers and deadline")
 travel(c,deadline)
 unchanged(c,"hire_offer",{"offer":v.offers[1].id},"Exclusive recruitment expiry rejects atomically")
 check(v.status=="departed","Normal vessel departure")
 # Offshore recovery boundaries and uninterrupted four-day calendar.
 for delay in [1439,1440]:
  c=fresh();S.set_closure(c,"Blockade");travel(c,S.FIRST_ARRIVAL)
  v=c.s.shipping.vessels[0]
  check(v.status=="offshore" and v.offshore_deadline==6120,"Blocked vessel waits exactly 24 hours")
  var manifest=JSON.stringify(v.offers)
  var saved=restore(c,"user://greywake-offshore-test.json")
  check(JSON.stringify(saved.s.shipping.vessels[0].offers)==manifest,"Offshore hidden manifest survives load")
  travel(c,S.FIRST_ARRIVAL+delay);travel(saved,S.FIRST_ARRIVAL+delay)
  S.set_closure(c,"");S.set_closure(saved,"")
  check(c.s.shipping==saved.s.shipping,"Continuous and reloaded deadline outcome agrees")
  check(v.status==("docked" if delay==1439 else "turned_back"),"Exclusive offshore boundary "+str(delay))
  check(c.s.shipping.next_arrival_at==10440,"Missed/late vessel never shifts Day 8 calendar")
  if delay==1439: check(v.docked_at==6119 and v.recruitment_deadline==8999,"Late docking gets full 48-hour window")
  else:
   S.access_changed(c);check(v.status=="turned_back","Terminal vessel never reopens")
  check(c.valid_save(c.s),"Offshore boundary state validates")
 # Long chronological advance, with original wages and expiries still running.
 c=fresh();travel(c,480+12*1440)
 check(c.s.shipping.vessels.size()==4,"Twelve-day advance creates exactly four scheduled vessels")
 check(c.s.shipping.vessels.map(func(ship):return ship.status)==["departed","departed","docked","scheduled"],"Each intermediate arrival and departure processes exactly once")
 check(c.s.shipping.next_arrival_at==21960 and c.valid_save(c.s),"Future calendar and long save validate")
 check(c.s.ledger.filter(func(row):return "Wage" in row.reason or "wage" in row.reason).size()>0,"Wages remain in chronological scheduler")
 # Military occupation derives from sector ownership; recovery hook shares access query.
 c=fresh();c.s.sectors[17].owner="bandits";S.access_changed(c);travel(c,S.FIRST_ARRIVAL)
 v=c.s.shipping.vessels[0]
 check(v.status=="offshore" and not S.accessible(c.s),"Hostile ownership closes harbour even with company present")
 c.s.sectors[17].owner="company";S.access_changed(c);S.access_changed(c)
 check(v.status=="docked" and c.s.shipping.vessels.size()==2,"Authoritative recovery docks exactly once")
 var before=c.s.time
 check(c.command("visit",{"squad":"first"}),"Tactical pause begins")
 unchanged(c,"advance",{"minutes":60},"Tactical encounter consumes no campaign time")
 check(c.s.time==before,"Battle clock cannot advance shipping")
 c.command("leave")
 c.remove_member(c.s.squads.first.members[0])
 check(c.s.squads.first.members.size()==1 and c.advance(1),"Surviving one-person company remains playable")
 # Corruption rejected; live state is not mutated by validation.
 var bad=c.s.duplicate(true);bad.shipping.vessels[0].offers[0].candidate_id="forged"
 check(not c.valid_save(bad),"Corrupt candidate identity rejected")
 bad=c.s.duplicate(true);bad.events.append(bad.events[-1].duplicate(true))
 check(not c.valid_save(bad),"Duplicate queued event rejected")
 bad=c.s.duplicate(true);bad.shipping.next_arrival_at+=1
 check(not c.valid_save(bad),"Shifted arrival calendar rejected")
 bad=c.s.duplicate(true);bad.shipping.vessels[0].offers[0].preview.fee=1
 check(not c.valid_save(bad),"Forged offer price rejected")
 # Named offers reference canonical records and never return after employment/death.
 var found=false
 for seed_value in range(731,751):
  var named_case=C.new(seed_value);named_case.autosave_path="user://greywake-test-auto.json";named_case.configure_fall_of_greywake()
  named_case.command("recruit_template",{"template":"militia_spearman"});named_case.command("recruit_template",{"template":"militia_spearman"});named_case.command("embark")
  named_case.record(10000,"Test reserve");named_case.s.squads.first.supplies.food=10000
  named_case.advance(S.FIRST_ARRIVAL-named_case.s.time)
  for o in named_case.s.shipping.vessels[0].offers:
   if o.preview.repeatable: continue
   found=true
   var count=named_case.s.mercs.size();var canonical=named_case.s.mercs[o.candidate_id];var kit=canonical.inventory.duplicate(true)
   check(named_case.command("hire_offer",{"offer":o.id}) and named_case.s.mercs.size()==count and canonical.inventory==kit,"Named vessel hire reuses canonical person and equipment")
   unchanged(named_case,"hire_offer",{"offer":o.id},"Named vessel hire cannot be duplicated")
   canonical.dead=true;canonical.hp=0;named_case.remove_member(canonical.id)
   named_case.advance(S.ARRIVAL_INTERVAL)
   check(named_case.s.shipping.vessels[1].offers.all(func(candidate):return candidate.candidate_id!=canonical.id),"Dead named professional never returns on later vessel")
   check(named_case.valid_save(named_case.s),"Named employment history and death save correctly")
   break
  if found: break
 check(found,"Deterministic manifest includes remaining professional pool")
 # Distinct repeatable vessel hires, no manifest refill, individual progression.
 c=fresh();travel(c,S.FIRST_ARRIVAL)
 var cheap_offers=c.s.shipping.vessels[0].offers.filter(func(o):return o.preview.repeatable)
 if cheap_offers.size()<2:
  c.advance(S.ARRIVAL_INTERVAL);cheap_offers=c.s.shipping.vessels[1].offers.filter(func(o):return o.preview.repeatable)
 check(cheap_offers.size()>=2,"Vessel has two cheap candidates for ownership check")
 if cheap_offers.size()>=2:
  var size_before=c.s.shipping.vessels[-2].offers.size()
  for o in cheap_offers.slice(0,2): check(c.command("hire_offer",{"offer":o.id}),"Repeatable passenger hire")
  var a=c.s.mercs[cheap_offers[0].person_id];var b=c.s.mercs[cheap_offers[1].person_id]
  check(a.id!=b.id and a.name!=b.name and a.inventory[0].id!=b.inventory[0].id,"Repeatable passengers have distinct permanent identities and equipment")
  var prior=b.melee;a.melee+=1
  check(b.melee==prior and c.s.shipping.vessels[-2].offers.size()==size_before,"Individual progression cannot change another recruit or refill vessel")
  check(restore(c,"user://greywake-passengers-test.json").s.mercs[a.id].melee==a.melee,"Passenger progression persists")
 # Real tactical recovery of occupied Dock Town uses the established victory/control transition.
 c=fresh();c.s.squads.first.supplies.food=10000;travel(c,S.FIRST_ARRIVAL-1)
 c.s.sectors[17].owner="bandits";travel(c,S.FIRST_ARRIVAL)
 var enemy=D.hostile("port-occupier",0);enemy.hp=1
 c.s.groups=[{"id":"port-occupation","faction":"bandits","sector":17,"objective":17,"fighters":[enemy],"positions":{}}]
 c.encounter(c.s.squads.first,17)
 check(c.command("enter") and c.command("confirm_deployment"),"Occupied port opens established tactical encounter")
 var rounds=0
 while c.battle.outcome()=="ongoing" and rounds<60:
  for u in c.battle.t.units:
   if u.team=="company" and c.battle.can_act(u): c.battle.ai_unit(u)
  if c.battle.outcome()=="ongoing": c.battle.end_turn()
  rounds+=1
 check(c.battle.outcome()=="victory" and c.command("resolve"),"Port occupation defeated through legal tactical actions")
 check(c.s.sectors[17].owner=="company" and c.s.shipping.vessels[0].status=="docked","Tactical military recovery reopens harbour and lands waiting vessel")
 check(c.valid_save(c.s),"Recovered port shipping and tactical history validate")
 # A remote free squad cannot receive a hire during another squad's encounter.
 var offer_again=c.s.shipping.vessels[0].offers[0]
 c.command("split",{"id":c.s.squads.first.members[-1],"squad":"first"})
 var remote=c.s.squads.values()[-1];remote.sector=18
 c.encounter(remote,18);c.command("enter")
 check(c.battle!=null,"Remote tactical encounter actually exists")
 unchanged(c,"hire_offer",{"offer":offer_again.id,"squad":"first"},"Ongoing battle elsewhere blocks remote Dock Town hire")
 # Save one minute before the exact offshore deadline, then compare continuous/reloaded expiry.
 c=fresh();S.set_closure(c,"Deadline fixture");travel(c,S.FIRST_ARRIVAL+1439)
 var before_deadline=restore(c,"user://greywake-last-minute-test.json")
 check(c.advance(1) and before_deadline.advance(1),"Continuous and loaded final minute advances")
 S.set_closure(c,"");S.set_closure(before_deadline,"")
 check(c.s.shipping==before_deadline.s.shipping and c.s.shipping.vessels[0].status=="turned_back","Last-minute reload obeys exact exclusive deadline")
 # Cancellation is terminal and preserves the regular calendar.
 c=fresh();check(S.cancel(c,c.s.shipping.vessels[0].id),"Authored vessel cancellation supported")
 check(c.s.shipping.next_arrival_at==10440 and c.valid_save(c.s),"Cancellation preserves Day 8 calendar and event validation")
 travel(c,S.FIRST_ARRIVAL);S.access_changed(c)
 check(c.s.shipping.vessels[0].status=="cancelled","Cancelled scheduled vessel never activates retroactively")
 var impossible=fresh(false).s.duplicate(true);impossible.shipping.vessels[0].docked_at=1
 check(not c.valid_save(impossible),"Scheduled vessel cannot have a past docking history")
 var corrupt=c.s.duplicate(true)
 corrupt.events=corrupt.events.filter(func(e):return e.kind!="greywake_ship_arrival")
 check(not c.valid_save(corrupt),"Missing authoritative future shipping event rejected")
 corrupt=c.s.duplicate(true);corrupt.shipping.vessels[0].offers="not a manifest"
 check(not c.valid_save(corrupt),"Malformed shipping container rejected safely")
 corrupt=c.s.duplicate(true);corrupt.shipping.port_blockade=true
 check(not c.valid_save(corrupt),"Contradictory blockade field type rejected safely")
 var result={"passed":passed,"failed":failures.size(),"failures":failures}
 var out=FileAccess.open("res://greywake-test-results.json",FileAccess.WRITE);out.store_string(JSON.stringify(result,"  "));out.close()
 print("GREYWAKE: "+JSON.stringify(result));quit(0 if failures.is_empty() else 1)
