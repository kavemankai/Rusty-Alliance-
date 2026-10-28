extends Node
const Campaign=preload("res://sim/campaign.gd")
const Data=preload("res://sim/catalog.gd")
const GreywakeMap=preload("res://ui/greywake_map.gd")
const MapView=preload("res://ui/world_map.gd")
const BattleView=preload("res://ui/battle_view.gd")
const OpeningView=preload("res://ui/greywake_opening_view.gd")
const Desktop=preload("res://ui/desktop.gd")
const PC=preload("res://ui/pc_controls.gd")
const BattleHUD=preload("res://ui/battle_hud.gd")
const TacticalRadial=preload("res://ui/tactical_radial.gd")
const Icons=preload("res://ui/asset_icons.gd")
var game
var ui: Control
var header: Label
var message: Label
var content: Container
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
var opening_transition=false
var opening_tween: Tween
var advanced_controls=false
var tavern_selected="militia_spearman"
var base_theme: Theme
var island_theme: Theme
var opening_view
var title_visible=false
var shipping_alert=""
var port_status: Label
var confirm: ConfirmationDialog
var desktop=Desktop.new()
var desktop_feedback: Label
var binding_action=""
var pan_keys={}
var view_memory={}
var crew: HBoxContainer
var action_dock: HBoxContainer
var preview_caption: Label
var primary_button: Button
var background_paused=false
var sidebar_offset=-60
var nav_buttons={}
var reload_button: Button
var guard_button: Button
var battle_hud
var battle_radial
var battle_details=false

func _ready() -> void:
 if Desktop.enabled(): desktop.load_settings();desktop.apply_window(get_window(),true)
 ui=Control.new()
 ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(ui)
 get_viewport().size_changed.connect(func():call_deferred("apply_safe_area"))
 apply_safe_area()
 var theme=Theme.new()
 theme.default_font_size=18
 ui.theme=theme;base_theme=theme
 island_theme=theme.duplicate();island_theme.default_font_size=16
 island_theme.set_color("font_color","Label",Color("e2d4b2"))
 island_theme.set_color("font_color","Button",Color("e2d4b2"))
 apply_desktop_theme()
 confirm=ConfirmationDialog.new()
 ui.add_child(confirm)
 menu()
 if OS.is_debug_build() and OS.has_feature("android") and FileAccess.file_exists("user://mobile-qa.enabled"):
  add_child(preload("res://ui/mobile_probe.gd").new())

func apply_safe_area() -> void:
 if not OS.has_feature("android") or ui==null: return
 var padding=preload("res://ui/safe_area.gd").insets(DisplayServer.get_display_safe_area(),DisplayServer.window_get_size(),get_viewport().get_visible_rect().size)
 ui.offset_left=padding.x;ui.offset_top=padding.y;ui.offset_right=-padding.z;ui.offset_bottom=-padding.w

func clear() -> void:
 for child in ui.get_children():
  if child!=confirm:
   ui.remove_child(child)
   child.queue_free()

func button(parent: Node,title: String,callback: Callable) -> Button:
 var b=Button.new()
 b.text=title
 b.mouse_filter=Control.MOUSE_FILTER_PASS
 b.clip_text=true
 b.tooltip_text=title
 b.custom_minimum_size=Vector2(0,36 if game!=null and Campaign.World.applies(game.s) and not OS.has_feature("android") else 48)
 for resource in ["food","medicine","tools","horse","cart"]:
  if resource in title.to_lower():
   b.icon=Icons.get_icon(resource);b.expand_icon=true;b.add_theme_constant_override("icon_max_width",36)
   break
 b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 parent.add_child(b)
 if game!=null and Campaign.World.applies(game.s): preload("res://ui/greywake_art.gd").apply_button(b)
 if Desktop.enabled(): desktop.style_button(b)
 b.pressed.connect(callback,CONNECT_DEFERRED)
 return b

func label(parent: Node,text: String) -> Label:
 var l=Label.new()
 l.text=text
 if Desktop.enabled(): l.add_theme_font_size_override("font_size",round(16*desktop.ui_scale))
 l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 parent.add_child(l)
 return l

func menu() -> void:
 auto_minutes=0;title_visible=true;ui.theme=base_theme;clear()
 opening_view=OpeningView.new();opening_view.app=self;opening_view.mode="title";ui.add_child(opening_view)

func start_original() -> void:
 title_visible=false;game=Campaign.new();save_slot="user://campaign.json";selected="mara";squad="first";tab="sector";rebuild()

func start_greywake() -> void:
 var candidate=Campaign.new()
 if not candidate.configure_greywake_opening(): return
 title_visible=false;tavern_selected="militia_spearman";game=candidate;save_slot="user://greywake.json";selected="";squad="first";tab="sector";rebuild()

func load_original(path: String) -> void:
 var candidate=Campaign.new()
 if candidate.command("load",{"path":path}): game=candidate;save_slot="user://campaign.json";title_visible=false;rebuild()
 else: last_message=candidate.error

func continue_greywake() -> void:
 var paths=["user://greywake.json","user://greywake-autosave.json"]
 paths.sort_custom(func(a,b):return FileAccess.get_modified_time(a)>FileAccess.get_modified_time(b))
 for path in paths:
  var candidate=Campaign.new()
  if candidate.command("load",{"path":path}) and Campaign.Recruitment.is_greywake(candidate.s):
   game=candidate;save_slot="user://greywake.json";selected="";squad="first";tab="sector";title_visible=false;rebuild();return

func title_settings() -> void:
 if not Desktop.enabled():
  clear();var box=VBoxContainer.new();box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.add_child(box)
  label(box,"Touch: select · drag: pan · pinch: zoom");button(box,"Back",menu);return
 pause_desktop();clear()
 var margin=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for key in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+key,40)
 ui.add_child(margin)
 var columns=HBoxContainer.new();margin.add_child(columns);columns.add_spacer(false)
 var card=VBoxContainer.new();card.custom_minimum_size.x=680;columns.add_child(card);columns.add_spacer(false)
 button(card,"Back",menu)
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;card.add_child(scroll)
 var box=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(box)
 PC.settings(self,box)

func opening_execute(kind: String,p: Dictionary={}) -> void:
 if opening_transition: return
 var before=Campaign.Opening.stage(game.s)
 if game.command(kind,p):
  last_message="Saved" if kind=="save" else ""
  if before!=Campaign.Opening.stage(game.s):
   opening_transition=true
   var curtain=ColorRect.new();curtain.color=Color.BLACK;curtain.modulate.a=0;curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.add_child(curtain)
   opening_tween=create_tween();opening_tween.tween_property(curtain,"modulate:a",1.0,.10)
   opening_tween.tween_callback(func():rebuild();fade_in())
  else: rebuild()
 else: last_message=game.error;rebuild()

func fade_in() -> void:
 var curtain=ColorRect.new();curtain.color=Color.BLACK;curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);curtain.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(curtain)
 opening_tween=create_tween();opening_tween.tween_property(curtain,"modulate:a",0.0,.15);opening_tween.tween_callback(curtain.queue_free)

func open_greywake(path: String) -> void:
 var candidate=Campaign.new()
 if not candidate.command("load",{"path":path}) or not Campaign.Recruitment.is_greywake(candidate.s):
  var dialog=AcceptDialog.new();dialog.dialog_text="Unable to load the Greywake save. "+candidate.error
  ui.add_child(dialog);dialog.popup_centered();return
 game=candidate;game.autosave_path="user://greywake-autosave.json";save_slot="user://greywake.json"
 selected="";squad="first";tab="company";rebuild()

func rebuild() -> void:
 cache_views()
 crew=null;action_dock=null;primary_button=null;preview_caption=null;nav_buttons.clear();battle_hud=null;battle_radial=null
 if opening_tween!=null and opening_tween.is_valid(): opening_tween.kill()
 opening_transition=false
 title_visible=false
 ui.theme=island_theme if Campaign.World.applies(game.s) else base_theme
 if Campaign.Opening.locked(game.s):
  auto_minutes=0;clear();map_view=null;battle_view=null
  opening_view=OpeningView.new();opening_view.app=self;ui.add_child(opening_view);return
 if Campaign.Recruitment.opening(game.s):
  opening_screen();return
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
 var navigation=[["Map","sector"],["Operations","operations"],["Company","company"],["Contracts","contracts"],["Inventory","inventory"],["Supplies","supplies"],["Ledger","ledger"],["Inspector","debug"],["Settings","settings"]]
 if Campaign.World.applies(game.s): navigation=[["Map","sector"],["Harbour","harbour"],["Company","company"],["Contracts","contracts"],["Inventory","inventory"],["Supplies","supplies"],["Settings","settings"]]
 elif Campaign.Shipping.applies(game.s): navigation=[["Dock Town","harbour"],["Company","company"],["Inventory","inventory"],["Supplies","supplies"],["Ledger","ledger"],["Settings","settings"]]
 if Campaign.Shipping.applies(game.s) and game.battle!=null:
  if Desktop.enabled(): navigation=navigation.filter(func(item):return item[1]!="sector")
  navigation.push_front(["Battle","sector"])
  if tab=="harbour": tab="sector"
 for item in navigation:
  if Desktop.enabled() and item[1]=="debug": continue
  var entry=button(nav,item[0],change_tab.bind(item[1]))
  if Desktop.enabled(): entry.toggle_mode=true;nav_buttons[item[1]]=entry
 content=HSplitContainer.new() if Desktop.enabled() else HBoxContainer.new()
 if Desktop.enabled():
  content.split_offset=sidebar_offset
  content.dragged.connect(func(value):sidebar_offset=value)
 content.size_flags_vertical=Control.SIZE_EXPAND_FILL
 root.add_child(content)
 map_view=null
 battle_view=null
 if game.battle==null and Campaign.Shipping.applies(game.s) and not Campaign.World.applies(game.s):
  var port=VBoxContainer.new();port.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  content.add_child(port)
  label(port,"DOCK TOWN · Recruitment port\nThe Fall of Greywake")
  port_status=label(port,"")
  label(port,"The 10×10 island map and its routes are a later milestone. Company, inventory and scheduled mainland recruitment are available here.")
  if Campaign.World.can_upgrade(game.s): button(port,"Upgrade staging save to island opening",run_command.bind("upgrade_greywake",{}))
  label(port,"Existing staging geography is preserved unless an eligible save is explicitly upgraded.")
  button(port,"Recruitment harbour",func():change_tab("harbour"))
  button(port,"Visit Dock Town",run_command.bind("visit",{"squad":squad}))
  if tab in ["sector","contracts","operations"]: tab="harbour"
 elif game.battle==null:
  map_view=GreywakeMap.new() if Campaign.World.applies(game.s) else MapView.new()
  map_view.campaign=game
  map_view.selected=sector
  map_view.squad=squad
  map_view.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  map_view.custom_minimum_size.x=400
  content.add_child(map_view)
  restore_view(map_view,"map")
  map_view.sector_selected.connect(func(index): sector=index; tab="sector"; show_panel())
 else:
  if game.battle.unit(selected)==null:
   for unit in game.battle.t.units:
    if unit.team=="company" and unit.person.hp>0: selected=unit.id;break
  battle_view=BattleView.new()
  battle_view.battle=game.battle
  battle_view.selected=selected
  battle_view.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  battle_view.custom_minimum_size.x=400
  battle_view.render_scale=desktop.render_scale if Desktop.enabled() else 1.0
  content.add_child(battle_view)
  restore_view(battle_view,"battle")
  battle_view.cell_selected.connect(tactical_cell)
  if Desktop.enabled(): battle_view.context_requested.connect(open_battle_radial)
 var scroll=ScrollContainer.new()
 scroll.custom_minimum_size.x=360 if Desktop.enabled() else 380
 scroll.size_flags_horizontal=Control.SIZE_FILL
 content.add_child(scroll)
 side=VBoxContainer.new()
 side.custom_minimum_size.x=340 if Desktop.enabled() else 360
 side.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 scroll.add_child(side)
 if Desktop.enabled() and game.battle!=null:
  battle_hud=BattleHUD.new();battle_hud.app=self;root.add_child(battle_hud)
  action_dock=HBoxContainer.new();root.add_child(action_dock)
  preview_caption=label(action_dock,"");preview_caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  primary_button=button(action_dock,"Confirm preview",confirm_preview);primary_button.custom_minimum_size.x=180
  reload_button=button(action_dock,"Reload",func():battle_action("reload"))
  guard_button=button(action_dock,"Guard",func():battle_action("guard"))
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
  if map_view!=null: button(bar,"−",func():map_view.zoom=clampf(map_view.zoom/1.15,0.65,2.8);map_view.queue_redraw())
  if map_view!=null: button(bar,"+",func():map_view.zoom=clampf(map_view.zoom*1.15,0.65,2.8);map_view.queue_redraw())
 else:
  if game.battle.t.phase=="deployment":
   button(bar,"Begin combat",func():run_command("confirm_deployment"))
   button(bar,"Scout before contact",func():run_command("confirm_deployment",{"explore":true}))
  elif game.battle.t.phase=="exploration":
   button(bar,"Pause exploration" if game.battle.t.exploration.get("running",false) else "Run exploration",func():run_command("exploration_running"))
   button(bar,"Wait / scout",func():run_command("explore_wait"))
   if not game.battle.t.get("peaceful",false): button(bar,"Enter combat",func():run_command("combat"))
   if not game.battle.t.get("peaceful",false): button(bar,"Resolve",func():run_command("resolve"))
  else:
   button(bar,"End turn",func():
    if not game.battle.end_turn(): status(game.battle.error)
    else: status("Enemy turn resolved");game.Opening.mark(game.s,"turn")
    refresh())
   button(bar,"Resolve",func():run_command("resolve"))
  if game.battle.t.get("peaceful",false): button(bar,"Leave sector",func():run_command("leave"))
  if not game.battle.t.get("peaceful",false):
   button(bar,"Retreat",func():
    var exits=game.retreat_options()
    var place="no safe exit" if exits.is_empty() else game.s.sectors[exits[0]].name
    ask("Withdraw to "+place+"? Injuries and losses persist.",func():run_command("retreat")))
  button(bar,"−",func():battle_view.camera.size=clampf(battle_view.camera.size+2,8,32))
  button(bar,"+",func():battle_view.camera.size=clampf(battle_view.camera.size-2,8,32))
 message=label(root,last_message)
 message.custom_minimum_size.y=26 if Desktop.enabled() else 46
 if Desktop.enabled(): message.max_lines_visible=2
 if Desktop.enabled() and game.battle!=null:
  battle_radial=TacticalRadial.new();battle_radial.app=self;ui.add_child(battle_radial)
 refresh()
 if Desktop.enabled(): restore_sidebar_after_layout(content)

func change_tab(value: String) -> void:
 close_radial()
 pan_keys.clear()
 if Desktop.enabled() and value=="settings": pause_desktop()
 tab=value
 show_panel()

func status(text: String) -> void:
 last_message=text
 if is_instance_valid(message): message.text=text;message.tooltip_text=text

func refresh() -> void:
 var s=game.s
 if Campaign.Shipping.applies(s):
  if is_instance_valid(port_status):
   var active="scheduled"
   for vessel in s.shipping.vessels:
    if vessel.arrival_at<=s.time: active=vessel.status
   port_status.text="⚓ Harbour "+("open" if Campaign.Shipping.accessible(s) else "blockaded")+" · Vessel "+active+" · Next "+Campaign.Shipping.timestamp(s.shipping.next_arrival_at)
  for i in range(s.log.size()-1,-1,-1):
   var line=s.log[i]
   if "OFFSHORE" in line or "HARBOUR REOPENED" in line or "REINFORCEMENTS LOST" in line or "MAINLAND VESSEL ARRIVED" in line:
    if shipping_alert!=line: shipping_alert=line;status(line)
    break
 var pack=game.s.squads[squad].supplies
 var caption=game.s.squads[squad].name
 if game.battle!=null:
  if game.battle.unit(selected)==null or (Desktop.enabled() and game.battle.unit(selected).person.hp<=0):
   for u in game.battle.t.units:
    if u.team=="company" and (not Desktop.enabled() or u.person.hp>0): selected=u.id;break
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
  battle_view.highlight_target=target
  battle_view.redraw()
 refresh_crew()
 if is_instance_valid(battle_hud):
  var phase=game.battle.t.phase
  header.text="  "+("DEPLOYMENT" if phase=="deployment" else ("EXPLORATION" if phase=="exploration" else ("PLAYER'S TURN" if game.battle.t.turn=="company" else "ENEMY TURN")))+"  ·  Round %d  ·  %s  ·  %d crowns"%[game.battle.t.round,game.s.sectors[game.s.encounter.sector].name,game.s.funds]
 show_panel()

func run_command(kind: String,p: Dictionary={}) -> void:
 close_radial()
 cache_views()
 if kind=="save" and not p.has("path"): p={"path":save_slot}
 var had_battle=game.battle!=null
 var previous_phase="" if not had_battle else game.battle.t.phase
 var previous_log="" if game.s.log.is_empty() else str(game.s.log.back())
 if game.command(kind,p):
  var titles={"explore_wait":"Scouting advanced","explore":"Exploration resumed","combat":"Combat started","supply_transfer":"Supplies transferred","enter":"Deployment ready","deploy":"Placement updated","confirm_deployment":"Combat started","equip":"Equipment updated","unequip":"Item unequipped","unequip_shield":"Shield unequipped","transfer":"Item transferred","resolve":"Battle resolved","retreat":"Company withdrew","levy":"Levy recruited","hire":"Fighter hired","advance":"Time advanced","assignment":"Assignment updated","route":"Route plotted","split":"Squad split","merge":"Squads merged","buy":"Purchase completed","save":"Campaign saved","load":"Campaign loaded"}
  var update=titles.get(kind,kind.capitalize()+" completed")
  if not game.s.log.is_empty() and str(game.s.log.back())!=previous_log: update+=". "+str(game.s.log.back())
  status(update)
  if kind=="deploy": destination={}
  if kind in ["resolve","retreat","enter","load","confirm_deployment","exploration_running","upgrade_greywake","dockside_start"] or had_battle!=(game.battle!=null) or (game.battle!=null and previous_phase!=game.battle.t.phase): rebuild()
  else: refresh()
 else: status(game.error)

func show_panel() -> void:
 if game!=null and game.battle!=null and target!="" and not game.battle.known("company",target):
  target=""
  if is_instance_valid(battle_view): battle_view.highlight_target=""
 if is_instance_valid(battle_hud):
  battle_hud.visible=tab=="sector"
  if is_instance_valid(side): side.get_parent().visible=tab!="sector" or battle_details
  battle_hud.refresh_info()
 for key in nav_buttons:
  if is_instance_valid(nav_buttons[key]): nav_buttons[key].set_pressed_no_signal(key==tab)
 update_context_dock()
 if not is_instance_valid(side): return
 for child in side.get_children():
  side.remove_child(child)
  child.queue_free()
 if game.battle!=null and tab=="sector":
  tactical_panel()
  return
 match tab:
  "harbour": harbour_panel()
  "operations": operations_panel()
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
   if Desktop.enabled(): PC.settings(self,side)
   else: label(side,"Drag to pan · Pinch or +/− to zoom. Manual save and boundary autosaves.")
  _: sector_panel()

func sector_panel() -> void:
 if Campaign.World.applies(game.s):
  island_panel();return
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
 if game.s.get("scenario","")=="greywake":
  label(side,"GREYWAKE · repeatable cheap recruits")
  for row in game.s.recruitment.templates:
   if row.repeatable:
    button(side,"Recruit %s · %d crowns" % [row.name,row.fee],run_command.bind("recruit_template",{"template":row.id,"squad":squad}))
    label(side,"Daily wage: %d crowns · each recruit keeps individual equipment and progression" % row.wage)
 for m in game.s.mercs.values():
  if m.dead:
   label(side,m.name+" · deceased")
   continue
  if m.get("captured",false):
   label(side,m.name+" · captured")
   continue
  var recruit=button(side,("● " if selected==m.id else "")+m.name+" · "+m.background,func():selected=m.id;show_panel())
  recruit.icon=Icons.get_icon(m.background);recruit.expand_icon=true;recruit.add_theme_constant_override("icon_max_width",44)
  if selected!=m.id: continue
  label(side,"HP %d/%d · AP %d · Morale %d\nFatigue %d · Wounds %d · Bleed %d\nSTR %d AGI %d DEX %d END %d\nPER %d WIS %d LEAD %d EXP %d\nMelee %d Ranged %d Medical %d Smith %d\n%s / %s · weight %d\n%d crowns/day" % [m.hp,m.max_hp,Data.ap(m),m.morale,m.fatigue,m.wounds,m.bleeding,m.strength,m.agility,m.dexterity,m.endurance,m.perception,m.wisdom,m.leadership,m.experience,m.melee,m.ranged,m.medical,m.smithing,Data.weapon(m),Data.armour(m),Data.weight(m),m.wage])
  label(side,"Stealth %d · Fieldcraft %d · Athletics %d\nHiring fee %d crowns · daily wage %d crowns" % [m.stealth,m.fieldcraft,m.athletics,m.fee,m.wage])
  if not m.hired:
   if Campaign.Shipping.applies(game.s): label(side,"Mainland professional · requires a current vessel offer")
   else: button(side,"Hire · %d crowns / 7 days" % m.fee,run_command.bind("hire",{"id":m.id,"squad":squad}))
  else:
   label(side,"Assignment: "+m.assignment)
   for value in ["rest","medical","training","repair","guard","scout","garrison"]: button(side,value.capitalize(),run_command.bind("assignment",{"id":m.id,"value":value}))
   label(side,"Training: %s · %d/12 progress" % [m.training_skill.capitalize(),m.training])
   for skill in Data.Skills.ALL:
    button(side,"Train "+skill.capitalize(),run_command.bind("assignment",{"id":m.id,"value":"training","skill":skill}))
   button(side,"Renew 7 days · %d crowns" % (m.wage*7),run_command.bind("renew",{"id":m.id}))
   button(side,"Split into new squad",run_command.bind("split",{"id":m.id,"squad":squad}))
   if squad!="first": button(side,"Merge this squad into First company",run_command.bind("merge",{"from":squad,"to":"first"}))
   button(side,"Dismiss",func():ask("Dismiss "+m.name+"?",func():run_command("dismiss",{"id":m.id})))

func inventory_panel() -> void:
 label(side,"INVENTORY · select fighter")
 for m in game.s.mercs.values():
  if m.hired: button(side,("● " if selected==m.id else "")+m.name,func():selected=m.id;show_panel())
 for defender in game.s.sectors[sector].levies:
  if game.s.sectors[sector].owner=="company": button(side,("● " if selected==defender.id else "")+defender.name,func():selected=defender.id;show_panel())
 var m=game.Items.person(game.s,selected)
 if not m.is_empty():
  label(side,"%s · %s · ammo %d\nArmour %s · Shield %s\nWeapon condition %d%% · carried weight %d\nDraw costs: 3 AP; heavy weapons and helmets 4 AP." % [m.name,Data.weapon(m),Data.ammo(m),Data.armour(m),str(Data.shield(m)),Data.condition(m),Data.weight(m)])
  label(side,"CARRIED ITEMS · tap to manage")
  for entry in m.inventory:
   var slot=""
   for key in m.equipment:
    if m.equipment[key]==entry.id: slot=key
   var item_button=button(side,Data.item_label(entry)+(" · "+slot if slot!="" else ""),func():inspected_item=entry.id;show_panel())
   item_button.icon=Icons.item(entry);item_button.expand_icon=true;item_button.add_theme_constant_override("icon_max_width",40)
   if inspected_item!=entry.id: continue
   if slot!="": button(side,"Unequip to backpack",run_command.bind("unequip",{"id":selected,"slot":slot}))
   elif entry.kind!="ammo": button(side,"Equip carried item",run_command.bind("equip",{"id":selected,"item":entry.id}))
   if slot=="":
    button(side,"Deposit at Dock Town" if Campaign.Shipping.applies(game.s) else "Deposit at Ashford",run_command.bind("transfer",{"from":selected,"to":"stash","item":entry.id}))
    for other in game.s.mercs.values()+game.s.sectors[sector].levies:
     if other.get("hired",false) or other in game.s.sectors[sector].levies:
      if other.id==selected: continue
      button(side,"Give to "+other.name,run_command.bind("transfer",{"from":selected,"to":other.id,"item":entry.id}))
 label(side,"DOCK TOWN STOCKPILE · visit to collect" if Campaign.Shipping.applies(game.s) else "ASHFORD STOCKPILE · visit to collect")
 for item in game.s.stash:
  var take=button(side,"Take "+Data.item_label(item),run_command.bind("transfer",{"from":"stash","to":selected,"item":item.id}))
  take.icon=Icons.item(item);take.expand_icon=true;take.add_theme_constant_override("icon_max_width",40)
  var equip=button(side,"Equip "+Data.item_label(item),run_command.bind("equip",{"id":selected,"item":item.id}))
  equip.icon=Icons.item(item);equip.expand_icon=true;equip.add_theme_constant_override("icon_max_width",40)
 label(side,"MARKET · visit Dock Town" if Campaign.Shipping.applies(game.s) else "MARKET · visit Ashford")
 for item in ["food","medicine","tools","ammo","arrows","bolts","javelins","stone","shield","helmet","sword","spear","axe","mace","bow","crossbow","mail","plate"]:
  var price=Data.WEAPONS[item].price if Data.WEAPONS.has(item) else (Data.ARMOUR[item].price if Data.ARMOUR.has(item) else {"food":20,"medicine":30,"tools":25,"ammo":15,"shield":65,"helmet":45,"arrows":15,"bolts":15,"javelins":15,"stone":5}[item])
  button(side,"Buy %s · %d crowns" % [item,price],run_command.bind("buy",{"item":item,"squad":squad}))

func tactical_cell(x: int,y: int) -> void:
 get_viewport().gui_release_focus()
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
  refresh_crew()
  show_panel()
  return
 if u!=null and u.team=="company":
  game.Opening.mark(game.s,"select")
  selected=u.id
  destination={}
 elif u!=null and b.known("company",u.id): target=u.id;game.Opening.mark(game.s,"chance")
 else:
  var actor=b.unit(selected)
  if actor!=null:
   var route=b.path(actor,x,y,true)
   battle_view.preview=route.path
 battle_view.selected=selected
 battle_view.highlight_target=target
 battle_view.redraw()
 refresh_crew()
 show_panel()

func battle_action(kind: String,p: Dictionary={}) -> void:
 close_radial()
 var previous_phase=game.battle.t.phase
 if game.battle.action(selected,kind,p):
  status("Done: "+kind)
  if kind in ["move","attack"]: game.Opening.mark(game.s,kind)
  if kind in ["guard","defence_mode"]: game.Opening.mark(game.s,"defence")
 else: status(game.battle.error)
 destination={}
 if target!="" and (game.battle.unit(target)==null or game.battle.unit(target).person.hp<=0 or not game.battle.known("company",target)): target=""
 if battle_view!=null: battle_view.preview=[]
 if previous_phase!=game.battle.t.phase:
  if not game.battle.t.log.is_empty(): status(game.battle.t.log.back())
  rebuild()
 else: refresh()

func close_radial() -> void:
 if is_instance_valid(battle_radial) and battle_radial.visible: battle_radial.dismiss()

func open_battle_radial(x: int,y: int,point: Vector2,right_click: bool=false) -> void:
 if game==null or game.battle==null or tab!="sector" or PC.modal(self): return
 pause_desktop()
 var b=game.battle
 if right_click:
  var unit=b.at(x,y)
  if unit!=null and unit.team=="company": target="";destination={};refresh()
  else: tactical_cell(x,y)
 var global_point=battle_view.get_global_transform()*point
 battle_radial.open_at(global_point,Vector2i(x,y))

func tactical_panel() -> void:
 var b=game.battle
 var beginner=game.Opening.stage(game.s)=="FIRST_TACTICAL_ENCOUNTER" and not advanced_controls
 tutorial_panel()
 if b.t.phase=="deployment":
  deployment_panel()
  return
 button(side,"Toggle roofs",func():battle_view.show_roofs=not battle_view.show_roofs;battle_view.redraw())
 label(side,"Fog: dark is unexplored; dim is remembered terrain.")
 label(side,"FIELD · "+game.s.sectors[game.s.encounter.sector].name+" · "+b.t.get("layout","legacy"))
 if b.t.phase=="exploration":
  label(side,"EXPLORATION · local pulses %d" % b.t.exploration.elapsed)
  label(side,"Movement and Wait / scout advance patrols. Either side detecting opponents starts combat immediately. Positions and remaining AP carry across; the world clock stays paused.")
 else:
  label(side,"BATTLE · round %d · %s\n%s" % [b.t.round,b.t.turn,b.outcome()])
  label(side,"Quiet rounds: %d/3 before exploration may resume" % b.t.quiet_rounds)
  if b.t.quiet_rounds>=3: button(side,"Resume exploration",run_command.bind("explore",{}))
 for u in ([] if Desktop.enabled() else b.t.units):
  if u.team=="company" and u.person.hp>0: button(side,("● " if selected==u.id else "")+u.person.name+" · %d AP / %d HP" % [u.ap,u.person.hp],func():selected=u.id;target="";destination={};battle_view.selected=selected;game.Opening.mark(game.s,"select");refresh())
 var u=b.unit(selected)
 if u==null: return
 if u.role=="cart":
  label(side,"Provision cart · %d HP. A living driver must remain within two tiles." % u.person.hp)
  if not destination.is_empty(): button(side,"Confirm movement",battle_action.bind("move",destination.duplicate()))
  return
 label(side,"%s · %s · %s\nAP %d · Fatigue %d · Morale %d\nBleeding %d · %s · Ammo %d" % [u.person.name,u.stance,u.mode,u.ap,u.person.fatigue,u.person.morale,u.person.bleeding,Data.weapon(u.person),Data.ammo(u.person)])
 if target!="":
  var enemy=b.unit(target)
  label(side,"Target %s · HP %d\nRange %d · Hit %d%% · aim %d\nAttack cost %d AP · defence may negate hit" % [enemy.person.name,enemy.person.hp,b.distance(u,enemy),b.hit_chance(u,enemy,aim),aim,b.Combat.cost(u,aim)])
  label(side,"Directional cover against this attack: %d" % b.directional_cover(u,enemy))
  button(side,"Aim + (max 3)",func():aim=(aim+1)%4;show_panel())
  if not beginner and Data.WEAPONS[Data.weapon(u.person)].reach>0: button(side,"Attack style: "+u.get("attack_style","normal"),func():var values=b.Combat.ATTACKS.keys();battle_action("attack_style",{"value":values[(values.find(u.get("attack_style","normal"))+1)%values.size()]}))
  if not beginner: button(side,"Aim at: "+u.get("aim_location","auto"),func():var values=b.Combat.LOCATIONS;battle_action("aim_location",{"value":values[(values.find(u.get("aim_location","auto"))+1)%values.size()]}))
  if not beginner and Data.WEAPONS[Data.weapon(u.person)].reach>0:
   var charge=b.Combat.charge_preview(b,u,enemy)
   label(side,"Charge: %d movement + %d strike AP · %d%% contact chance · %d visible reaction threats" % [charge.movement,charge.strike,charge.hit,charge.reactions])
   var charge_button=button(side,"Charge target · movement + power strike",battle_action.bind("charge",{"target":target}))
   charge_button.disabled=b.distance(u,enemy)<2 or b.distance(u,enemy)>6 or charge.movement<=0 or charge.movement+charge.strike>u.ap
  if not beginner and Data.shield(u.person): button(side,"Shield bash · 5 AP",battle_action.bind("bash",{"target":target}))
  button(side,"Confirm attack",battle_action.bind("attack",{"target":target,"aim":aim}))
 elif not destination.is_empty():
  var route=b.path(u,destination.x,destination.y,true)
  var cell=b.Visibility.cell(b,destination.x,destination.y)
  if b.t.phase=="exploration" or route.path.any(func(index):return b.Visibility.level(b,int(index)%int(b.t.width),int(index)/int(b.t.width))<2):
   label(side,"Estimated route %d AP of steps · local time advances\nUnseen ground is provisional. Stops on contact, obstruction or insufficient AP." % route.cost)
  else:
   label(side,"Tile %d:%d · move cost %d AP\nRemaining %d · %s\nElevation %d · Cover %d · Concealment %d" % [destination.x,destination.y,route.cost,u.ap-maxi(0,route.cost),cell.kind.capitalize(),cell.elevation,cell.cover,cell.conceal])
  for placement in b.t.ground:
   if b.Visibility.level(b,placement.x,placement.y)==2 and placement.x==destination.x and placement.y==destination.y: label(side,"Ground: "+Data.item_label(placement.item))
  button(side,"Confirm movement",battle_action.bind("move",destination.duplicate()))
  if b.t.get("peaceful",false):
   for build_kind in ["barricade","palisade","gate","torch"]: button(side,"Build "+build_kind+" · 8 AP",battle_action.bind("build",{"x":destination.x,"y":destination.y,"kind":build_kind}))
  for formation_style in ([] if beginner else ["line","column","wedge"]): button(side,"Order "+formation_style+" formation",battle_action.bind("formation",{"x":destination.x,"y":destination.y,"style":formation_style}))
  var withdrawal=b.Combat.risk(b,u,destination.x,destination.y)
  label(side,"Visible melee reactions: %d · deliberate disengage %d AP. Unseen or ranged threats may still react." % [withdrawal.threats.size(),withdrawal.disengage_ap])
  if b.t.phase=="combat": button(side,"Disengage to tile",battle_action.bind("disengage",destination.duplicate()))
  if cell.door and b.Visibility.level(b,destination.x,destination.y)==2: button(side,"Open / close door · 3 AP",battle_action.bind("door",destination.duplicate()))
 button(side,"Cancel selection",func():target="";destination={};battle_view.preview=[];refresh())
 if beginner:
  if game.battle.t.phase=="combat":
   button(side,"Prepare defence · 2 AP",battle_action.bind("defence_mode",{"value":"shield" if Data.shield(u.person) else "brace"}))
   button(side,"Guard / disengagement reaction",battle_action.bind("guard",{}))
  if Data.WEAPONS[Data.weapon(u.person)].reach==0: button(side,"Reload",battle_action.bind("reload",{}))
  if u.person.bleeding>0: button(side,"First aid self · 5 AP",battle_action.bind("aid",{}))
  button(side,"Show advanced combat controls",func():advanced_controls=true;show_panel())
  for line in b.t.log.slice(maxi(0,b.t.log.size()-3)): label(side,line)
  return
 if u.get("protecting","")!="": label(side,"Protecting an adjacent ally: each frontal interception needs another 3 AP and shield condition.")
 label(side,"Defence: %s · shield condition %d%%\nInjuries: %s" % [u.get("defence_mode","balanced"),Data.equipped(u.person,"shield").get("condition",0),Data.injury_summary(u.person)])
 for defence in b.Combat.DEFENCES: button(side,"Defence "+defence+" · 2 AP",battle_action.bind("defence_mode",{"value":defence}))
 if target!="":
  for entry in u.person.inventory:
   if entry.kind in ["stone","dagger","javelin"]: button(side,"Throw "+Data.item_label(entry)+" · 6 AP",battle_action.bind("throw",{"item":entry.id,"target":target}))
 button(side,"Reload",battle_action.bind("reload",{}))
 for value in ["stand","crouch","prone"]: button(side,value.capitalize()+" · 2 AP",battle_action.bind("stance",{"value":value}))
 for value in ["walk","run","cautious"]: button(side,value.capitalize(),battle_action.bind("mode",{"value":value}))
 button(side,"Turn 45° · 1 AP",battle_action.bind("turn",{}))
 if b.t.phase=="combat": button(side,"Guard / disengagement reaction",battle_action.bind("guard",{}))
 button(side,"Rally nearby allies · 4 AP",battle_action.bind("rally",{}))
 for ally in b.t.units:
  if ally.team!=u.team or ally.id==u.id or ally.person.hp<=0 or b.distance(u,ally)>1: continue
  if ally.role=="cart": button(side,"Repair "+ally.person.name+" · 5 AP + tool",battle_action.bind("repair_cart",{"target":ally.id}))
  else: button(side,"Aid "+ally.person.name+" · 5 AP",battle_action.bind("aid",{"target":ally.id}))
  if Data.shield(u.person): button(side,"Protect "+ally.person.name+" · 3 AP",battle_action.bind("protect",{"target":ally.id}))
 button(side,"First aid self · 5 AP",battle_action.bind("aid",{}))
 button(side,"Loot adjacent · 3 AP",battle_action.bind("loot",{}))
 for text in b.t.log.slice(maxi(0,b.t.log.size()-6)): label(side,text)

func ask(text: String,callback: Callable) -> void:
 confirm.dialog_text=text
 for connection in confirm.confirmed.get_connections(): confirm.confirmed.disconnect(connection.callable)
 confirm.confirmed.connect(callback,CONNECT_ONE_SHOT)
 confirm.popup_centered(Vector2i(500,200))

func _process(delta: float) -> void:
 if Desktop.enabled():
  PC.pan(self,delta)
  var paused=background_paused or PC.modal(self) or tab=="settings"
  if is_instance_valid(battle_view): battle_view.viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED if paused else SubViewport.UPDATE_WHEN_VISIBLE
  if paused: return
 if title_visible: return
 if game!=null and game.battle!=null and game.battle.t.phase=="exploration" and game.battle.t.exploration.get("running",false):
  timer+=delta
  if timer>=0.4:
   timer=0
   var previous=game.battle.t.phase
   game.battle.Exploration.advance(game.battle,1)
   if game.battle.t.phase!=previous: rebuild()
   else: refresh()
  return
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
 if Desktop.enabled() and is_instance_valid(ui):
  if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
   background_paused=true;pause_desktop();Engine.max_fps=15
   if is_instance_valid(battle_view): battle_view.viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
  elif what==NOTIFICATION_APPLICATION_FOCUS_IN:
   background_paused=false;Engine.max_fps=desktop.frame_limit
   if is_instance_valid(battle_view): battle_view.viewport.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE
 if what==NOTIFICATION_APPLICATION_PAUSED and game!=null:
  auto_minutes=0
  if game.battle!=null and game.battle.t.has("exploration"): game.battle.t.exploration.running=false
  call_deferred("rebuild")
  game.save_to(game.autosave_path)

func contracts_panel() -> void:
 label(side,"CONTRACT BOARD · selected squad: "+squad)
 if not Campaign.World.applies(game.s): button(side,"Request new postings",run_command.bind("post_jobs",{}))
 else: label(side,"After a withdrawal, paid farm-road rounds at Harth can support provisions and wages. No free recovery is provided.")
 label(side,"Finish before the listed deadline. Road work reposts one day after closing.")
 for j in game.s.jobs:
  if Campaign.World.applies(game.s):
   label(side,"%s · %s\n%d crowns · %s" % [j.name,j.status,j.reward,game.s.sectors[j.sector].name])
   if j.get("opening_contract",false): label(side,"The opening contract imposes no campaign deadline. Drive off the dockside bandits in a real encounter.")
   elif j.get("recovery_work",false): label(side,"Accept at Harth, check the farmland, then return. Progress %d/2. Paid once on completion; the existing one-day repost delay applies." % j.step)
  else:
   label(side,"%s · %s · %s\n%d crowns · sector %d:%d\nDeadline day %d, %02d:%02d" % [j.name,j.type,j.status,j.reward,int(j.sector)%16+1,int(j.sector/16)+1,int(j.deadline/1440)+1,int(j.deadline%1440/60),int(j.deadline%60)])
   label(side,game.Contracts.describe(j))
  if j.squad!="": label(side,"Assigned: "+j.squad)
  if j.reason!="": label(side,j.reason)
  if j.status=="available": button(side,"Accept "+j.name,run_command.bind("accept",{"id":j.id,"squad":squad}))
  elif j.type in ["escort","patrol"] and j.status in ["paid","failed"] and game.s.time>=j.finished+1440:
   button(side,"Repost "+j.name,run_command.bind("repost",{"id":j.id}))

func deployment_panel() -> void:
 var b=game.battle
 for entry_side in b.t.get("entry_zones",{}): button(side,"Approach from "+entry_side,run_command.bind("entry",{"direction":entry_side}))
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

func operations_panel() -> void:
 label(side,"FIELD OPERATIONS")
 var q=game.s.squads.get(squad,{})
 if q.is_empty(): return
 label(side,q.name+" · "+game.s.sectors[q.sector].name)
 button(side,"Visit sector peacefully",run_command.bind("visit",{"squad":squad}))
 var transport=q.get("transport",{"horses":0,"carts":0})
 label(side,"Horses %d · carts %d. Horse: 120 crowns; cart: 160 crowns. One horse per member enables mounted travel; carts reduce pack burden." % [transport.horses,transport.carts])
 for asset in ["horses","carts"]:
  button(side,"Buy "+asset,run_command.bind("transport",{"asset":asset,"squad":squad}))
  button(side,"Sell "+asset,run_command.bind("transport",{"asset":asset,"squad":squad,"sell":true}))
 label(side,"LOCAL PRISONERS")
 for g in game.s.groups:
  for prisoner in g.fighters:
   if prisoner.get("captured",false) and prisoner.hp>0 and not prisoner.get("released",false) and prisoner.get("captured_sector",g.sector)==q.sector:
    label(side,prisoner.name+" · detained")
    for choice in ["release","ransom","recruit"]: button(side,choice.capitalize()+" "+prisoner.name,run_command.bind("prisoner",{"id":prisoner.id,"choice":choice,"squad":squad}))

func opening_action(kind: String,p: Dictionary={}) -> void:
 if game.command(kind,p): last_message="Selection updated";rebuild()
 else: last_message=game.error;opening_screen()

func opening_screen() -> void:
 auto_minutes=0;clear();map_view=null;battle_view=null
 var root=VBoxContainer.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.add_child(root)
 label(root,"THE FALL OF GREYWAKE · Mainland tavern · Pre-voyage company")
 label(root,"%d crowns remaining · %d / 6 aboard · Choose at least TWO mercenaries. Hiring fees are charged now; wages are daily." % [game.s.funds,game.s.squads.first.members.size()])
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(scroll)
 var rows=VBoxContainer.new();rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(rows)
 label(rows,"SELECTED COMPANY · refundable before departure")
 for id in game.s.squads.first.members:
  var m=game.s.mercs[id]
  button(rows,"Remove "+m.name+" · refund "+str(m.fee),opening_action.bind("cancel_opening_hire",{"id":id}))
 for row in game.s.recruitment.templates:
  var box=VBoxContainer.new();rows.add_child(box)
  label(box,"%s · %s · Fee %d · Wage %d/day%s" % [row.name,row.tier.capitalize(),row.fee,row.wage," · repeatable" if row.repeatable else " · unique"])
  var details=[]
  for key in Data.Skills.ATTRIBUTES+Data.Skills.ALL: details.append(key.capitalize()+" "+str(row.attributes.get(key,row.skills.get(key,0))))
  label(box," · ".join(details))
  label(box,"Equipment: "+row.weapon+", "+row.armour+(", shield" if row.get("shield",false) else "")+("; carried "+", ".join(row.get("secondary_weapons",[])) if not row.get("secondary_weapons",[]).is_empty() else "")+("; "+Data.ammo_kind_for(row.weapon) if row.get("ammo_quantity",0)>0 else ""))
  var taken=not row.repeatable and game.s.mercs["greywake-named-"+row.id].hired
  var hire=button(box,"Hire "+row.name,opening_action.bind("recruit_template" if row.repeatable else "hire",{"template":row.id,"id":"greywake-named-"+row.id,"squad":"first"}))
  hire.disabled=taken or game.s.funds<row.fee or game.s.squads.first.members.size()>=6
 var controls=HBoxContainer.new();root.add_child(controls)
 button(controls,"Save selection",opening_action.bind("save",{"path":save_slot}))
 button(controls,"Load selection",opening_action.bind("load",{"path":save_slot}))
 var depart=button(controls,"Depart for Dock Town",opening_action.bind("embark",{}))
 depart.disabled=game.s.squads.first.members.size()<2
 message=label(root,last_message)

func harbour_panel() -> void:
 var shipping=Campaign.Shipping;var sh=game.s.shipping
 if Campaign.World.applies(game.s):
  var illustration=TextureRect.new();illustration.texture=preload("res://ui/greywake_art.gd").harbour_image(game.s)
  illustration.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;illustration.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
  illustration.custom_minimum_size=Vector2(0,150);illustration.mouse_filter=Control.MOUSE_FILTER_IGNORE;side.add_child(illustration)
 label(side,"DOCK TOWN · MAINLAND RECRUITMENT")
 label(side,"Harbour access: "+("open" if shipping.accessible(game.s) else "blockaded"))
 label(side,"Next scheduled ship: "+shipping.timestamp(sh.next_arrival_at)+"\nHiring requires a stationary squad at Dock Town. Resolve any tactical encounter first.")
 for v in sh.vessels:
  if v.status=="scheduled": continue
  label(side,v.id+" · "+v.status)
  if v.status in ["departed","turned_back","cancelled"]: continue
  if v.status=="offshore":
   label(side,"MAINLAND VESSEL WAITING OFFSHORE\nDock Town · waiting until "+shipping.timestamp(v.offshore_deadline)+"\nPassenger identities are unavailable while the harbour is sealed.")
   continue
  label(side,"Recruitment closes: "+shipping.timestamp(v.recruitment_deadline))
  for o in v.offers:
   label(side,"%s · fee %d · wage %d/day · %s" % [o.name,o.fee,o.wage,o.status])
   var stats=[]
   for key in Data.Skills.ATTRIBUTES+Data.Skills.ALL: stats.append(key.capitalize()+" "+str(o.preview.attributes.get(key,o.preview.skills.get(key,0))))
   label(side," · ".join(stats))
   label(side,"Equipment: "+o.preview.weapon+", "+o.preview.armour+(", shield" if o.preview.get("shield",false) else "")+("; "+str(o.preview.ammo_quantity)+" "+Data.ammo_kind_for(o.preview.weapon) if o.preview.get("ammo_quantity",0)>0 else "")+("; carried "+", ".join(o.preview.get("secondary_weapons",[])) if not o.preview.get("secondary_weapons",[]).is_empty() else ""))
   var hire=button(side,"Hire passenger "+o.name,run_command.bind("hire_offer",{"offer":o.id,"squad":squad}))
   var q=game.s.squads[squad]
   hire.disabled=o.status!="available" or not shipping.accessible(game.s) or game.s.time>=v.recruitment_deadline or game.s.funds<o.fee or game.battle!=null or not game.s.encounter.is_empty() or q.sector!=shipping.dock(game.s) or not q.route.is_empty()
 for line in game.s.log:
  if "OFFSHORE" in line or "HARBOUR REOPENED" in line or "REINFORCEMENTS LOST" in line or "MAINLAND VESSEL ARRIVED" in line: label(side,line)

func _unhandled_key_input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo: return
 if Desktop.enabled() and PC.typing(self): return
 if Desktop.enabled() and event.keycode in [KEY_ENTER,KEY_SPACE] and get_viewport().gui_get_focus_owner() is Button: return
 if title_visible:
  if event.keycode==KEY_ESCAPE: menu();get_viewport().set_input_as_handled()
  return
 if game==null: return
 var stage=Campaign.Opening.stage(game.s)
 if Campaign.Opening.locked(game.s):
  if event.keycode==KEY_ENTER and stage=="EMPLOYER_BRIEFING": opening_execute("opening_next",{})
  elif event.keycode in [KEY_ESCAPE,KEY_SPACE] and stage in ["BOAT_CROSSING","EMPLOYER_BRIEFING"]: opening_execute("opening_skip",{})
  elif event.keycode==KEY_ESCAPE and stage=="TAVERN_RECRUITMENT": tavern_selected="";rebuild()
  elif event.keycode==KEY_ESCAPE and stage=="COMPANY_CONFIRMATION": opening_execute("opening_back",{})
  elif Desktop.enabled() and event.keycode==KEY_ENTER and stage=="COMPANY_CONFIRMATION": opening_execute("opening_depart",{})
  elif Desktop.enabled() and event.keycode==KEY_ENTER and stage in ["GREYWAKE_ARRIVAL","DOCKSIDE_CONTRACT"]: opening_execute("opening_next",{})
  else: return
  get_viewport().set_input_as_handled();return
 if Desktop.enabled(): return
 if event.keycode==KEY_ESCAPE:
  target="";destination={};get_viewport().gui_release_focus()
  if battle_view!=null: battle_view.preview=[]
  refresh();get_viewport().set_input_as_handled()
 elif event.keycode==KEY_SPACE and game.battle!=null and game.battle.t.phase=="combat":
  var focus=get_viewport().gui_get_focus_owner()
  if focus!=null and (focus is Button or focus is LineEdit or focus is TextEdit): return
  if game.battle.end_turn(): game.Opening.mark(game.s,"turn");refresh()
  else: status(game.battle.error)
  get_viewport().set_input_as_handled()

func island_panel() -> void:
 var cell=game.s.sectors[sector];var q=game.s.squads[squad]
 label(side,cell.name.to_upper())
 label(side,cell.terrain.capitalize()+" · "+(cell.owner if cell.known else "Not yet observed"))
 label(side,"Company: "+game.s.sectors[q.sector].name+" · "+str(q.members.size())+" fighters")
 if not game.s.encounter.is_empty():
  label(side,"Hostile contact · campaign time paused")
  button(side,"Deploy company",run_command.bind("enter",{}))
 elif not q.members.is_empty():
  var route=game.strategic_path(q.sector,sector,q);var eta=0
  for id in route: eta+=game.travel_cost(q,id)
  if q.sector!=sector:
   label(side,"Journey estimate: %d min across %d sectors" % [eta,route.size()])
   var go=button(side,"Travel to "+cell.name,run_command.bind("route",{"squad":squad,"sector":sector}));go.disabled=route.is_empty() or not q.route.is_empty()
  else:
   if not game.hostile_at(sector):
    if cell.facility=="garrison" and cell.owner=="nobles": label(side,"Fortress approach · entry is unavailable in this opening.")
    else: button(side,"Visit "+cell.name,run_command.bind("visit",{"squad":squad}))
 if sector==game.Shipping.dock(game.s):
  var intro=game.s.jobs.filter(func(j):return j.id==game.Opening.INTRO_JOB)
  if not intro.is_empty() and intro[0].status in ["available","active"]:
   label(side,"DOCKSIDE TROUBLE · %d crowns\nBandits are extorting workers near the warehouses. Prepare, deploy or return later." % intro[0].reward)
   var fight=button(side,"Deal with Dockside Trouble",run_command.bind("dockside_start",{}))
   fight.disabled=q.sector!=sector or not q.route.is_empty() or not game.Contracts.capable(game,q)
  elif game.hostile_at(sector) and q.sector==sector and not q.route.is_empty(): label(side,"Return here to recover the occupied harbour.")
  button(side,"Recruitment harbour",func():change_tab("harbour"))
  label(side,"Mainland vessels: "+game.Shipping.timestamp(game.s.shipping.next_arrival_at)+" · harbour "+("open" if game.Shipping.accessible(game.s) else "blockaded"))
 if not game.s.result.is_empty(): label(side,"Last encounter: "+game.s.result.outcome+" · survivors "+str(game.s.result.survivors))

func tutorial_panel() -> void:
 var key=game.Opening.lesson(game.s,game.battle)
 if key=="": return
 label(side,"FIRST ENCOUNTER · "+game.Opening.LESSONS[key])
 button(side,"Next tip",run_command.bind("tutorial_next",{}))
 button(side,"Hide tutorial",run_command.bind("tutorial_dismiss",{}))

func _input(event: InputEvent) -> void:
 if opening_transition:
  get_viewport().set_input_as_handled();return
 if Desktop.enabled() and event is InputEventKey and PC.key_input(self,event):
  get_viewport().set_input_as_handled();return
 if Desktop.enabled() and event is InputEventKey and PC.typing(self): return
 if title_visible or game==null or confirm.visible: return
 var stage=Campaign.Opening.stage(game.s)
 if event is InputEventKey and event.pressed and not event.echo:
  if (stage=="EMPLOYER_BRIEFING" and event.keycode in [KEY_ENTER,KEY_SPACE,KEY_ESCAPE]) or (stage=="BOAT_CROSSING" and event.keycode in [KEY_SPACE,KEY_ESCAPE]) or (stage in ["TAVERN_RECRUITMENT","COMPANY_CONFIRMATION"] and event.keycode==KEY_ESCAPE) or (Desktop.enabled() and stage in ["COMPANY_CONFIRMATION","GREYWAKE_ARRIVAL","DOCKSIDE_CONTRACT"] and event.keycode==KEY_ENTER):
   if not (Desktop.enabled() and event.keycode==KEY_ENTER and get_viewport().gui_get_focus_owner() is Button): _unhandled_key_input(event)
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT:
  if Desktop.enabled() and game.battle!=null and tab=="sector" and is_instance_valid(battle_view) and battle_view.get_global_rect().has_point(event.position): return
  if stage=="TAVERN_RECRUITMENT": tavern_selected="";rebuild()
  elif stage=="COMPANY_CONFIRMATION": opening_execute("opening_back",{})
  elif not Campaign.Opening.locked(game.s):
   cancel_preview()
  get_viewport().set_input_as_handled()

func apply_desktop_theme() -> void:
 if not Desktop.enabled(): return
 if base_theme!=null: base_theme.default_font_size=round(17*desktop.ui_scale)
 if island_theme!=null: island_theme.default_font_size=round(17*desktop.ui_scale)

func pause_desktop() -> void:
 close_radial()
 auto_minutes=0;timer=0;pan_keys.clear()
 if game!=null and game.battle!=null and game.battle.t.phase=="exploration": game.battle.t.exploration.running=false

func cache_views() -> void:
 if not Desktop.enabled() or game==null: return
 if is_instance_valid(map_view) and map_view.is_inside_tree() and map_view.campaign==game: view_memory[str(game.get_instance_id())+"/map"]={"zoom":map_view.zoom,"offset":map_view.offset}
 if is_instance_valid(battle_view) and battle_view.is_inside_tree() and battle_view.battle==game.battle: view_memory[str(game.get_instance_id())+"/battle"]={"position":battle_view.camera.position,"zoom":battle_view.camera.size,"roofs":battle_view.show_roofs}

func restore_view(view,kind: String) -> void:
 if not Desktop.enabled(): return
 var key=str(game.get_instance_id())+"/"+kind
 if not view_memory.has(key): return
 var state=view_memory[key]
 if kind=="map": view.zoom=state.zoom;view.offset=state.offset
 else: view.camera.position=state.position;view.camera.size=state.zoom;view.show_roofs=state.roofs

func fighters() -> Array:
 if game==null or game.battle==null: return []
 return game.battle.t.units.filter(func(unit):return unit.team=="company" and unit.person.hp>0)

func select_fighter(index: int) -> void:
 close_radial()
 var available=fighters()
 if index<0 or index>=available.size(): return
 selected=available[index].id;cancel_pending_only();tab="sector"
 get_viewport().gui_release_focus();game.Opening.mark(game.s,"select");refresh()

func cycle_fighter(step: int) -> void:
 var available=fighters()
 if available.is_empty(): return
 var index=0
 for i in range(available.size()):
  if available[i].id==selected: index=i;break
 select_fighter(posmod(index+step,available.size()))

func refresh_crew() -> void:
 if not is_instance_valid(crew): return
 if is_instance_valid(battle_hud): battle_hud.refresh_roster();return
 for child in crew.get_children(): crew.remove_child(child);child.queue_free()
 var available=fighters()
 for i in range(available.size()):
  var unit=available[i];var name=unit.person.name.get_slice(" · ",0)
  if unit.id.begins_with("greywake-recruit-"): name="#"+unit.id.trim_prefix("greywake-recruit-")
  var choice=button(crew,"%d · %s\n%d/%d HP · %d AP" % [i+1,name,unit.person.hp,unit.person.max_hp,unit.ap],select_fighter.bind(i))
  choice.custom_minimum_size=Vector2(165,58);choice.tooltip_text=unit.person.name+" · "+Data.weapon(unit.person)
  choice.toggle_mode=true;choice.button_pressed=unit.id==selected

func cancel_preview() -> void:
 close_radial()
 target="";destination={};get_viewport().gui_release_focus()
 if is_instance_valid(battle_view): battle_view.preview=[]
 refresh()

func end_player_turn() -> void:
 close_radial()
 if game==null or game.battle==null or game.battle.t.phase!="combat": return
 cancel_pending_only()
 if game.battle.end_turn(): game.Opening.mark(game.s,"turn");status("Enemy turn resolved")
 else: status(game.battle.error)
 refresh()

func cancel_pending_only() -> void:
 target="";destination={}
 if is_instance_valid(battle_view): battle_view.preview=[]

func confirm_preview() -> void:
 if game==null or game.battle==null: return
 if game.battle.t.phase=="deployment":
  if not destination.is_empty(): run_command("deploy",{"id":selected,"x":destination.x,"y":destination.y})
  else: run_command("confirm_deployment")
 elif game.battle.outcome()!="ongoing": run_command("resolve")
 elif target!="": battle_action("attack",{"target":target,"aim":aim})
 elif not destination.is_empty(): battle_action("move",destination.duplicate())

func update_context_dock() -> void:
 if not is_instance_valid(action_dock) or game==null or game.battle==null: return
 action_dock.visible=tab=="sector"
 var battle=game.battle;var actor=battle.unit(selected)
 var active=actor!=null and battle.t.phase=="combat" and battle.outcome()=="ongoing"
 reload_button.disabled=not active or Data.WEAPONS[Data.weapon(actor.person)].reach!=0 or actor.person.get("loaded",false) or Data.ammo(actor.person)<=0 if actor!=null else true
 guard_button.disabled=not active or actor.get("guard",false) if actor!=null else true
 primary_button.disabled=false
 primary_button.text="Confirm ["+desktop.key_name("confirm")+"]"
 if battle.outcome()!="ongoing": preview_caption.text=battle.outcome().capitalize()+" · Resolve to keep the result";return
 if actor==null: primary_button.disabled=true;preview_caption.text="Select a fighter";return
 if battle.t.phase=="deployment": preview_caption.text="Review positions · Enter confirms placement or begins combat";return
 if target!="":
  var enemy=battle.unit(target)
  if enemy==null or not battle.known("company",target): primary_button.disabled=true;preview_caption.text="Select a visible target";return
  preview_caption.text="ATTACK · %d%% hit · %d AP · %d AP available" % [battle.hit_chance(actor,enemy,aim),battle.Combat.cost(actor,aim),actor.ap]
 elif not destination.is_empty():
  var route=battle.path(actor,destination.x,destination.y,true)
  if route.path.is_empty() or route.cost<0: primary_button.disabled=true;preview_caption.text="No legal previewed route to this destination"
  else: preview_caption.text="MOVE · %d AP estimated · %d AP available · stops on contact" % [route.cost,actor.ap]
 else: primary_button.disabled=true;preview_caption.text="Select a destination or opponent · "+desktop.key_name("next_unit")+" cycles fighters"

func restore_sidebar_after_layout(split: Container) -> void:
 await get_tree().process_frame
 if is_instance_valid(split) and split.is_inside_tree() and split is HSplitContainer: split.split_offset=sidebar_offset
