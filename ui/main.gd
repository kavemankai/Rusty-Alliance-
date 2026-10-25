extends Node
const Campaign=preload("res://sim/campaign.gd")
const Data=preload("res://sim/catalog.gd")
const MapView=preload("res://ui/world_map.gd")
const BattleView=preload("res://ui/battle_view.gd")
var game
var ui: Control
var header: Label
var message: Label
var content: HBoxContainer
var map_view
var battle_view
var side: VBoxContainer
var sector=17
var squad="first"
var selected="mara"
var target=""
var destination={}
var tab="sector"
var aim=0
var auto_minutes=0
var timer=0.0
var last_message=""
var save_slot="user://campaign.json"
var inspected_item=""
var supply_amount=5
var confirm: ConfirmationDialog

func _ready() -> void:
 ui=Control.new()
 ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(ui)
 var theme=Theme.new()
 theme.default_font_size=18
 ui.theme=theme
 confirm=ConfirmationDialog.new()
 ui.add_child(confirm)
 menu()

func clear() -> void:
 for child in ui.get_children():
  if child!=confirm:
   ui.remove_child(child)
   child.queue_free()

func button(parent: Node,title: String,callback: Callable) -> Button:
 var b=Button.new()
 b.text=title
 b.custom_minimum_size=Vector2(0,48)
 b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 parent.add_child(b)
 b.pressed.connect(callback)
 return b

func label(parent: Node,text: String) -> Label:
 var l=Label.new()
 l.text=text
 l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 parent.add_child(l)
 return l

func menu() -> void:
 clear()
 var box=VBoxContainer.new()
 box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
 box.position=Vector2(-230,-210)
 box.size=Vector2(460,420)
 ui.add_child(box)
 label(box,"THE BROKEN MARCHES\nMedieval mercenary campaign\nGodot 4.6 · mechanical greybox")
 button(box,"New campaign",func():game=Campaign.new(); tab="sector"; rebuild())
 button(box,"Load campaign",func():
  game=Campaign.new()
  if game.command("load",{"path":save_slot}): rebuild()
  else: label(box,game.error))
 button(box,"Continue autosave",func():
  game=Campaign.new()
  if game.command("load",{"path":"user://autosave.json"}): rebuild()
  else: label(box,game.error))
 label(box,"Tap to inspect. Drag to pan. Pinch or use +/− to zoom.\nRecruit → contract → travel → battle → recover.\nEvery action changes persistent campaign state.")

func rebuild() -> void:
 target=""
 destination={}
 aim=0
 clear()
 if not game.s.squads.has(squad): squad="first"
 var root=VBoxContainer.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.add_theme_constant_override("separation",8)
 ui.add_child(root)
 header=label(root,"")
 var nav=HBoxContainer.new()
 root.add_child(nav)
 for item in [["Map","sector"],["Company","company"],["Contracts","contracts"],["Inventory","inventory"],["Supplies","supplies"],["Ledger","ledger"],["Inspector","debug"],["Settings","settings"]]:
  button(nav,item[0],change_tab.bind(item[1]))
 content=HBoxContainer.new()
 content.size_flags_vertical=Control.SIZE_EXPAND_FILL
 root.add_child(content)
 map_view=null
 battle_view=null
 if game.battle==null:
  map_view=MapView.new()
  map_view.campaign=game
  map_view.selected=sector
  map_view.squad=squad
  map_view.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  map_view.custom_minimum_size.x=400
  content.add_child(map_view)
  map_view.sector_selected.connect(func(index): sector=index; tab="sector"; show_panel())
 else:
  battle_view=BattleView.new()
  battle_view.battle=game.battle
  battle_view.selected=selected
  battle_view.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  battle_view.custom_minimum_size.x=400
  content.add_child(battle_view)
  battle_view.cell_selected.connect(tactical_cell)
 var scroll=ScrollContainer.new()
 scroll.custom_minimum_size.x=380
 scroll.size_flags_horizontal=Control.SIZE_FILL
 content.add_child(scroll)
 side=VBoxContainer.new()
 side.custom_minimum_size.x=360
 side.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 scroll.add_child(side)
 var bar=HBoxContainer.new()
 root.add_child(bar)
 button(bar,"Save",func():run_command("save"))
 button(bar,"Load",func():
  if game.command("load",{"path":save_slot}): last_message="Campaign loaded"; rebuild()
  else: status(game.error))
 if game.battle==null:
  button(bar,"+1 hour",func():run_command("advance",{"minutes":60}))
  button(bar,"+6 hours",func():run_command("advance",{"minutes":360}))
  button(bar,"Pause",func():auto_minutes=0; status("Time paused"))
  button(bar,"Run ×1",func():auto_minutes=10)
  button(bar,"Run ×6",func():auto_minutes=60)
  button(bar,"−",func():map_view.zoom=clampf(map_view.zoom/1.15,0.65,2.8);map_view.queue_redraw())
  button(bar,"+",func():map_view.zoom=clampf(map_view.zoom*1.15,0.65,2.8);map_view.queue_redraw())
 else:
  if game.battle.t.phase=="deployment":
   button(bar,"Begin combat",func():run_command("confirm_deployment"))
  else:
   button(bar,"End turn",func():
    if not game.battle.end_turn(): status(game.battle.error)
    else: status("Enemy turn resolved")
    refresh())
   button(bar,"Resolve",func():run_command("resolve"))
  button(bar,"Retreat",func():
   var exits=game.retreat_options()
   var place="no safe exit" if exits.is_empty() else game.s.sectors[exits[0]].name
   ask("Withdraw to "+place+"? Injuries and losses persist.",func():run_command("retreat")))
  button(bar,"−",func():battle_view.camera.size=clampf(battle_view.camera.size+2,8,32))
  button(bar,"+",func():battle_view.camera.size=clampf(battle_view.camera.size-2,8,32))
 message=label(root,last_message)
 message.custom_minimum_size.y=46
 refresh()

func change_tab(value: String) -> void:
 tab=value
 show_panel()

func status(text: String) -> void:
 last_message=text
 if is_instance_valid(message): message.text=text

func refresh() -> void:
 var s=game.s
 var pack=game.s.squads[squad].supplies
 var caption=game.s.squads[squad].name
 if game.battle!=null:
  if game.battle.unit(selected)==null:
   for u in game.battle.t.units:
    if u.team=="company": selected=u.id;break
  if game.battle.unit(selected)!=null:
   pack=game.Supplies.for_person(s,selected)
   caption=game.battle.unit(selected).person.name
 header.text="  Day %d · %02d:%02d  |  %d crowns  |  %s: Food %d · Medicine %d · Tools %d" % [int(s.time/1440)+1,int(s.time/60)%24,int(s.time)%60,s.funds,caption,pack.get("food",0),pack.get("medicine",0),pack.get("tools",0)]
 if map_view!=null:
  map_view.campaign=game
  map_view.selected=sector
  map_view.squad=squad
  map_view.queue_redraw()
 if battle_view!=null:
  battle_view.selected=selected
  battle_view.redraw()
 show_panel()

func run_command(kind: String,p: Dictionary={}) -> void:
 if kind=="save" and not p.has("path"): p={"path":save_slot}
 var had_battle=game.battle!=null
 var previous_log="" if game.s.log.is_empty() else str(game.s.log.back())
 if game.command(kind,p):
  var titles={"supply_transfer":"Supplies transferred","enter":"Deployment ready","deploy":"Placement updated","confirm_deployment":"Combat started","equip":"Equipment updated","unequip":"Item unequipped","unequip_shield":"Shield unequipped","transfer":"Item transferred","resolve":"Battle resolved","retreat":"Company withdrew","levy":"Levy recruited","hire":"Fighter hired","advance":"Time advanced","assignment":"Assignment updated","route":"Route plotted","split":"Squad split","merge":"Squads merged","buy":"Purchase completed","save":"Campaign saved","load":"Campaign loaded"}
  var update=titles.get(kind,kind.capitalize()+" completed")
  if not game.s.log.is_empty() and str(game.s.log.back())!=previous_log: update+=". "+str(game.s.log.back())
  status(update)
  if kind=="deploy": destination={}
  if kind in ["resolve","retreat","enter","load","confirm_deployment"] or had_battle!=(game.battle!=null): rebuild()
  else: refresh()
 else: status(game.error)

func show_panel() -> void:
 if not is_instance_valid(side): return
 for child in side.get_children():
  side.remove_child(child)
  child.queue_free()
 if game.battle!=null and tab=="sector":
  tactical_panel()
  return
 match tab:
  "company": company_panel()
  "contracts": contracts_panel()
  "inventory": inventory_panel()
  "supplies": supplies_panel()
  "ledger":
   label(side,"FINANCIAL LEDGER")
   for i in range(game.s.ledger.size()-1,-1,-1):
    var entry=game.s.ledger[i]
    label(side,"Day %d: %+d · %s\nBalance %d" % [int(entry.time/1440)+1,entry.amount,entry.reason,entry.balance])
  "debug":
   label(side,"DEVELOPER INSPECTOR\nSeed %d · RNG %d\nTime %d · events %d" % [game.s.seed,game.s.rng,game.s.time,game.s.events.size()])
   for e in game.s.events.slice(0,12): label(side,str(e))
   if game.battle!=null:
    label(side,"KNOWLEDGE\n"+JSON.stringify(game.battle.t.knowledge,"  "))
    label(side,"AI\n"+JSON.stringify(game.battle.t.ai,"  "))
    for u in game.battle.t.units: label(side,"%s · AP %d · fresh AP %d\n%s" % [u.id,u.ap,Data.ap(u.person),str(u.person)])
   label(side,"FACTIONS\n"+JSON.stringify(game.s.groups,"  "))
   for line in game.s.log: label(side,line)
  "settings":
   label(side,"PAUSE / SETTINGS")
   auto_minutes=0
   button(side,"Return to map / battle",func():change_tab("sector"))
   button(side,"Save campaign",run_command.bind("save",{}))
   button(side,"Main menu",func():ask("Save and return to menu?",func():game.command("save",{"path":save_slot});menu()))
   label(side,"Compatibility renderer · landscape\nPrimitive geometry · touch input\nManual save and boundary autosaves\nPinch or +/− zoom; drag to pan.")
  _: sector_panel()

func sector_panel() -> void:
 var cell=game.s.sectors[sector]
 label(side,"%s · %d:%d\n%s · %s\nFacility: %s\nLoyalty %d · Order %d · Levy %d" % [cell.name,cell.x+1,cell.y+1,cell.terrain,cell.owner,cell.facility if cell.facility!="" else "none",cell.loyalty,cell.order,game.Garrison.strength(cell)])
 if cell.owner=="company":
  label(side,"LOCAL DEPOT\nFood %d · Medicine %d · Tools %d" % [cell.supplies.food,cell.supplies.medicine,cell.supplies.tools])
  for levy in cell.levies:
   if levy.hp>0 and not levy.get("captured",false): label(side,"%s: %d/%d HP · melee %d · %s" % [levy.name,levy.hp,levy.max_hp,levy.melee,Data.weapon(levy)])
 for g in game.s.groups:
  if g.sector==sector and game.force_strength(g)>0 and cell.known: label(side,"Known force: %s · %d fighters" % [g.faction,game.force_strength(g)])
 label(side,"SELECT SQUAD")
 for q in game.s.squads.values():
  if q.members.is_empty(): continue
  button(side,("● " if q.id==squad else "")+q.name+" · %d fighters" % q.members.size(),func():squad=q.id;refresh())
 if not game.s.encounter.is_empty():
  label(side,"HOSTILE CONTACT · strategic time paused")
  button(side,"Deploy garrison" if game.s.encounter.squad=="" else "Deploy company",run_command.bind("enter",{}))
 else:
  var q=game.s.squads[squad]
  var route=game.strategic_path(q.sector,sector,q)
  var eta=0
  for index in route: eta+=game.travel_cost(q,index)
  label(side,"Route %d sectors · estimated %d min\nActive route %d · next arrival %d" % [route.size(),eta,q.route.size(),q.due])
  button(side,"Plot route to selected sector",run_command.bind("route",{"squad":squad,"sector":sector}))
 if cell.owner=="company": button(side,"Recruit levy · 80 crowns",run_command.bind("levy",{"sector":sector}))
 if not game.s.result.is_empty(): label(side,"LAST BATTLE\n"+str(game.s.result))
 label(side,"Blue: company · Red: bandits\nPurple: noble house · Dark: undiscovered\nLetters: facilities · Dots: forces\nSelect sector 3:3 for the first job.")

func supplies_panel() -> void:
 label(side,"SUPPLIES · local stores")
 for q in game.s.squads.values():
  button(side,("● " if q.id==squad else "")+q.name,func():squad=q.id;refresh())
 var q=game.s.squads[squad]
 var location=game.s.sectors[q.sector]
 label(side,"%s · %s\nPACK: Food %d · Medicine %d · Tools %d\nDEPOT: Food %d · Medicine %d · Tools %d" % [q.name,location.name,q.supplies.food,q.supplies.medicine,q.supplies.tools,location.supplies.food,location.supplies.medicine,location.supplies.tools])
 label(side,"Transfer amount: %d" % supply_amount)
 var choices=HBoxContainer.new()
 side.add_child(choices)
 for amount in [1,5,10,20]: button(choices,str(amount),func():supply_amount=amount;show_panel())
 for resource in game.Supplies.KINDS:
  button(side,"Load %d %s from depot" % [supply_amount,resource],run_command.bind("supply_transfer",{"from":"sector:%d" % q.sector,"to":q.id,"resource":resource,"amount":supply_amount}))
  button(side,"Store %d %s in depot" % [supply_amount,resource],run_command.bind("supply_transfer",{"from":q.id,"to":"sector:%d" % q.sector,"resource":resource,"amount":supply_amount}))
  for other in game.s.squads.values():
   if other.id!=q.id: button(side,"Give %d %s to %s" % [supply_amount,resource,other.name],run_command.bind("supply_transfer",{"from":q.id,"to":other.id,"resource":resource,"amount":supply_amount}))
 label(side,"Supply exchanges require stationary stores in the same sector and a controlled depot. Levies use their home depot. Farms produce local food. Market purchases go into the selected squad's pack.")

func company_panel() -> void:
 label(side,"COMPANY & RECRUITMENT")
 for m in game.s.mercs.values():
  if m.dead:
   label(side,m.name+" · deceased")
   continue
  if m.get("captured",false):
   label(side,m.name+" · captured")
   continue
  button(side,("● " if selected==m.id else "")+m.name+" · "+m.background,func():selected=m.id;show_panel())
  if selected!=m.id: continue
  label(side,"HP %d/%d · AP %d · Morale %d\nFatigue %d · Wounds %d · Bleed %d\nSTR %d AGI %d DEX %d END %d\nPER %d WIS %d LEAD %d EXP %d\nMelee %d Ranged %d Medical %d Smith %d\n%s / %s · weight %d\n%d crowns/day" % [m.hp,m.max_hp,Data.ap(m),m.morale,m.fatigue,m.wounds,m.bleeding,m.strength,m.agility,m.dexterity,m.endurance,m.perception,m.wisdom,m.leadership,m.experience,m.melee,m.ranged,m.medical,m.smithing,Data.weapon(m),Data.armour(m),Data.weight(m),m.wage])
  if not m.hired: button(side,"Hire · %d crowns / 7 days" % m.fee,run_command.bind("hire",{"id":m.id,"squad":squad}))
  else:
   label(side,"Assignment: "+m.assignment)
   for value in ["rest","medical","training","repair","guard","scout","garrison"]: button(side,value.capitalize(),run_command.bind("assignment",{"id":m.id,"value":value}))
   button(side,"Renew 7 days · %d crowns" % (m.wage*7),run_command.bind("renew",{"id":m.id}))
   button(side,"Split into new squad",run_command.bind("split",{"id":m.id,"squad":squad}))
   if squad!="first": button(side,"Merge this squad into First company",run_command.bind("merge",{"from":squad,"to":"first"}))
   button(side,"Dismiss",func():ask("Dismiss "+m.name+"?",func():run_command("dismiss",{"id":m.id})))

func inventory_panel() -> void:
 label(side,"INVENTORY · select fighter")
 for m in game.s.mercs.values():
  if m.hired: button(side,("● " if selected==m.id else "")+m.name,func():selected=m.id;show_panel())
 var m=game.s.mercs.get(selected,{})
 if not m.is_empty():
  label(side,"%s · %s · ammo %d\nArmour %s · Shield %s\nWeapon condition %d%% · carried weight %d\nEquipment changes cost 3 AP in battle." % [m.name,Data.weapon(m),Data.ammo(m),Data.armour(m),str(Data.shield(m)),Data.condition(m),Data.weight(m)])
  label(side,"CARRIED ITEMS · tap to manage")
  for entry in m.inventory:
   var slot=""
   for key in m.equipment:
    if m.equipment[key]==entry.id: slot=key
   button(side,Data.item_label(entry)+(" · "+slot if slot!="" else ""),func():inspected_item=entry.id;show_panel())
   if inspected_item!=entry.id: continue
   if slot!="": button(side,"Unequip to backpack",run_command.bind("unequip",{"id":selected,"slot":slot}))
   elif entry.kind!="ammo": button(side,"Equip carried item",run_command.bind("equip",{"id":selected,"item":entry.id}))
   if slot=="":
    button(side,"Deposit at Ashford",run_command.bind("transfer",{"from":selected,"to":"stash","item":entry.id}))
    for other in game.s.mercs.values():
     if other.hired and other.id!=selected: button(side,"Give to "+other.name,run_command.bind("transfer",{"from":selected,"to":other.id,"item":entry.id}))
 label(side,"ASHFORD STOCKPILE · visit to collect")
 for item in game.s.stash:
  button(side,"Take "+Data.item_label(item),run_command.bind("transfer",{"from":"stash","to":selected,"item":item.id}))
  button(side,"Equip "+Data.item_label(item),run_command.bind("equip",{"id":selected,"item":item.id}))
 label(side,"MARKET · visit Ashford")
 for item in ["food","medicine","tools","ammo","shield","helmet","sword","spear","axe","mace","bow","crossbow","mail","plate"]:
  var price=Data.WEAPONS[item].price if Data.WEAPONS.has(item) else (Data.ARMOUR[item].price if Data.ARMOUR.has(item) else {"food":20,"medicine":30,"tools":25,"ammo":15,"shield":65,"helmet":45}[item])
  button(side,"Buy %s · %d crowns" % [item,price],run_command.bind("buy",{"item":item,"squad":squad}))

func tactical_cell(x: int,y: int) -> void:
 tab="sector"
 var b=game.battle
 var u=b.at(x,y)
 destination={"x":x,"y":y}
 target=""
 battle_view.preview=[]
 if b.t.phase=="deployment":
  if u!=null and u.team=="company":
   selected=u.id
   destination={}
  battle_view.selected=selected
  battle_view.redraw()
  show_panel()
  return
 if u!=null and u.team=="company":
  selected=u.id
  destination={}
 elif u!=null and b.known("company",u.id): target=u.id
 else:
  var actor=b.unit(selected)
  if actor!=null:
   var route=b.path(actor,x,y)
   battle_view.preview=route.path
 battle_view.selected=selected
 battle_view.redraw()
 show_panel()

func battle_action(kind: String,p: Dictionary={}) -> void:
 if game.battle.action(selected,kind,p): status("Done: "+kind)
 else: status(game.battle.error)
 destination={}
 if battle_view!=null: battle_view.preview=[]
 refresh()

func tactical_panel() -> void:
 var b=game.battle
 if b.t.phase=="deployment":
  deployment_panel()
  return
 label(side,"FIELD · "+game.s.sectors[game.s.encounter.sector].name+" · "+b.t.get("layout","legacy"))
 label(side,"BATTLE · round %d · %s\n%s" % [b.t.round,b.t.turn,b.outcome()])
 for u in b.t.units:
  if u.team=="company" and u.person.hp>0: button(side,("● " if selected==u.id else "")+u.person.name+" · %d AP / %d HP" % [u.ap,u.person.hp],func():selected=u.id;target="";destination={};battle_view.selected=selected;refresh())
 var u=b.unit(selected)
 if u==null: return
 label(side,"%s · %s · %s\nAP %d · Fatigue %d · Morale %d\nBleeding %d · %s · Ammo %d" % [u.person.name,u.stance,u.mode,u.ap,u.person.fatigue,u.person.morale,u.person.bleeding,Data.weapon(u.person),Data.ammo(u.person)])
 if target!="":
  var enemy=b.unit(target)
  label(side,"Target %s · HP %d\nRange %d · Hit %d%% · aim %d\nAttack cost %d AP · defence may negate hit" % [enemy.person.name,enemy.person.hp,b.distance(u,enemy),b.hit_chance(u,enemy,aim),aim,Data.WEAPONS[Data.weapon(u.person)].ap+aim])
  button(side,"Aim + (max 3)",func():aim=(aim+1)%4;show_panel())
  button(side,"Confirm attack",battle_action.bind("attack",{"target":target,"aim":aim}))
 elif not destination.is_empty():
  var route=b.path(u,destination.x,destination.y)
  var cell=b.tile(destination.x,destination.y)
  label(side,"Tile %d:%d · move cost %d AP\nRemaining %d · %s\nElevation %d · Cover %d · Concealment %d" % [destination.x,destination.y,route.cost,u.ap-maxi(0,route.cost),cell.kind.capitalize(),cell.elevation,cell.cover,cell.conceal])
  for placement in b.t.ground:
   if placement.x==destination.x and placement.y==destination.y: label(side,"Ground: "+Data.item_label(placement.item))
  button(side,"Confirm movement",battle_action.bind("move",destination.duplicate()))
  button(side,"Open / close door · 3 AP",battle_action.bind("door",destination.duplicate()))
 button(side,"Cancel selection",func():target="";destination={};battle_view.preview=[];refresh())
 button(side,"Reload",battle_action.bind("reload",{}))
 for value in ["stand","crouch","prone"]: button(side,value.capitalize()+" · 2 AP",battle_action.bind("stance",{"value":value}))
 for value in ["walk","run","cautious"]: button(side,value.capitalize(),battle_action.bind("mode",{"value":value}))
 button(side,"Turn 45° · 1 AP",battle_action.bind("turn",{}))
 button(side,"Guard / disengagement reaction",battle_action.bind("guard",{}))
 button(side,"First aid self · 5 AP",battle_action.bind("aid",{}))
 button(side,"Loot adjacent · 3 AP",battle_action.bind("loot",{}))
 for text in b.t.log.slice(maxi(0,b.t.log.size()-6)): label(side,text)

func ask(text: String,callback: Callable) -> void:
 confirm.dialog_text=text
 for connection in confirm.confirmed.get_connections(): confirm.confirmed.disconnect(connection.callable)
 confirm.confirmed.connect(callback,CONNECT_ONE_SHOT)
 confirm.popup_centered(Vector2i(500,200))

func _process(delta: float) -> void:
 if game==null or auto_minutes==0 or game.battle!=null: return
 timer+=delta
 if timer>=1:
  timer=0
  if not game.command("advance",{"minutes":auto_minutes}):
   auto_minutes=0
   status(game.error)
  if not game.s.encounter.is_empty(): auto_minutes=0
  refresh()

func _notification(what: int) -> void:
 if what==NOTIFICATION_APPLICATION_PAUSED and game!=null:
  auto_minutes=0
  game.save_to(game.autosave_path)

func contracts_panel() -> void:
 label(side,"CONTRACT BOARD · selected squad: "+squad)
 label(side,"Finish before the listed deadline. Road work reposts one day after closing.")
 for j in game.s.jobs:
  label(side,"%s · %s · %s\n%d crowns · sector %d:%d\nDeadline day %d, %02d:%02d" % [j.name,j.type,j.status,j.reward,int(j.sector)%16+1,int(j.sector/16)+1,int(j.deadline/1440)+1,int(j.deadline%1440/60),int(j.deadline%60)])
  label(side,game.Contracts.describe(j))
  if j.squad!="": label(side,"Assigned: "+j.squad)
  if j.reason!="": label(side,j.reason)
  if j.status=="available": button(side,"Accept "+j.name,run_command.bind("accept",{"id":j.id,"squad":squad}))
  elif j.type in ["escort","patrol"] and j.status in ["paid","failed"] and game.s.time>=j.finished+1440:
   button(side,"Repost "+j.name,run_command.bind("repost",{"id":j.id}))

func deployment_panel() -> void:
 var b=game.battle
 label(side,"DEPLOYMENT · "+game.s.sectors[game.s.encounter.sector].name+" · "+b.t.get("layout","legacy"))
 label(side,"Select a fighter, then tap a green deployment tile. Confirm placement and choose facing. Begin combat when the formation is ready. Placement costs no AP.")
 for fighter in b.t.units:
  if fighter.team!="company" or fighter.person.hp<=0: continue
  var title=("● " if selected==fighter.id else "")+fighter.person.name+" · "+("placed" if fighter.get("deployed",false) else "needs placement")
  button(side,title,func():selected=fighter.id;destination={};target="";refresh())
 var u=b.unit(selected)
 if u==null or u.team!="company": return
 label(side,"%s · %s\nTile %d:%d · facing %s · %d AP reserved" % [u.person.name,u.get("squad","Home garrison"),u.x,u.y,["East","Southeast","South","Southwest","West","Northwest","North","Northeast"][u.facing],u.ap])
 if not destination.is_empty():
  var invalid=b.deployment_error(u.id,destination.x,destination.y)
  label(side,"Place at %d:%d" % [destination.x,destination.y] if invalid=="" else invalid)
  var place=button(side,"Confirm placement",run_command.bind("deploy",{"id":u.id,"x":destination.x,"y":destination.y}))
  place.disabled=invalid!=""
 button(side,"Rotate facing · free",run_command.bind("deploy",{"id":u.id,"x":u.x,"y":u.y,"facing":posmod(u.facing+1,8)}))
 button(side,"Cancel placement",func():destination={};refresh())
 label(side,"Enemy turns, attacks, equipment changes and world time remain frozen until Begin combat.")
