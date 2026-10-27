extends Control
const Art=preload("res://ui/greywake_art.gd")
const ArrivalMap=preload("res://ui/greywake_map.gd")
const ICONS=preload("res://ui/asset_icons.gd")
const TAVERN=preload("res://assets/greywake/scenes/03_tavern_recruitment_1920x1080.png")
const EMPLOYER=preload("res://assets/greywake/scenes/02_hooded_employer_1920x1080.png")
const VOYAGE=preload("res://assets/greywake/scenes/04_boat_crossing_1920x1080.png")
const TITLE=preload("res://assets/greywake/scenes/01_title_atmosphere_1920x1080.png")
const DOCK=preload("res://assets/greywake/scenes/06_dock_town_1920x1080.png")
var app
var mode="opening"
var elapsed=0.0
var canvas: Control
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 if mode=="title": title()
 else: opening()
func panel_style(decorated: bool=false) -> StyleBox:
 if decorated: return Art.panel()
 var style=StyleBoxFlat.new();style.bg_color=Color("202523");style.bg_color.a=.97
 style.border_color=Color("a48a5b");style.set_border_width_all(1);style.set_content_margin_all(14)
 return style
func frame(parent: Node,decorated: bool=false) -> VBoxContainer:
 var shell=PanelContainer.new();shell.mouse_filter=MOUSE_FILTER_PASS;shell.add_theme_stylebox_override("panel",panel_style(decorated));parent.add_child(shell)
 shell.size_flags_horizontal=SIZE_EXPAND_FILL
 var box=VBoxContainer.new();box.add_theme_constant_override("separation",7);shell.add_child(box);return box
func text(parent: Node,value: String,font_size: int=18) -> Label:
 var l=app.label(parent,value);l.add_theme_font_size_override("font_size",round(font_size*app.desktop.ui_scale) if app.Desktop.enabled() else font_size);l.add_theme_color_override("font_color",Color("e2d4b2"));return l
func action(parent: Node,value: String,callback: Callable) -> Button:
 var b=app.button(parent,value,callback);Art.apply_button(b);b.custom_minimum_size.y=44 if OS.has_feature("android") else 36
 b.add_theme_color_override("font_hover_color",Color("ffe9ad"))
 if app.Desktop.enabled(): app.desktop.style_button(b)
 return b
func plate(texture: Texture2D) -> void:
 var bg=TextureRect.new();bg.texture=texture;bg.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;bg.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);bg.mouse_filter=MOUSE_FILTER_IGNORE;add_child(bg)
 var shade=ColorRect.new();shade.color=Color(0,0,0,.22);shade.mouse_filter=MOUSE_FILTER_IGNORE
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
func root_box() -> VBoxContainer:
 var margin=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for k in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+k,18)
 add_child(margin);var v=VBoxContainer.new();v.add_theme_constant_override("separation",10);margin.add_child(v);return v
func title() -> void:
 plate(TITLE)
 var root=root_box();root.add_spacer(false)
 text(root,"THE BROKEN MARCHES",34);text(root,"The Fall of Greywake",25)
 text(root,"A company of your choosing. An island under a baron.",17)
 var shell=HBoxContainer.new();root.add_child(shell)
 var box=frame(shell);box.custom_minimum_size.x=410;box.size_flags_horizontal=SIZE_SHRINK_BEGIN
 action(box,"New Game",app.start_greywake)
 action(box,"New Greywake campaign",app.start_greywake)
 var resume=action(box,"Continue",app.continue_greywake);resume.disabled=not FileAccess.file_exists("user://greywake.json") and not FileAccess.file_exists("user://greywake-autosave.json")
 action(box,"Settings",app.title_settings)
 action(box,"Exit",func():get_tree().quit())
 var legacy=frame(shell);legacy.custom_minimum_size.x=330;legacy.size_flags_horizontal=SIZE_SHRINK_BEGIN
 text(legacy,"ORIGINAL CAMPAIGN",17)
 action(legacy,"New campaign",app.start_original)
 action(legacy,"Load campaign",app.load_original.bind("user://campaign.json"))
 action(legacy,"Continue autosave",app.load_original.bind("user://autosave.json"))
 if FileAccess.file_exists("user://greywake.json"): action(legacy,"Load Greywake campaign",app.open_greywake.bind("user://greywake.json"))
 if FileAccess.file_exists("user://greywake-autosave.json"): action(legacy,"Continue Greywake autosave",app.open_greywake.bind("user://greywake-autosave.json"))
 root.add_spacer(false)
func toolbar(root: VBoxContainer) -> void:
 var bar=HBoxContainer.new();root.add_child(bar)
 action(bar,"Save",app.opening_execute.bind("save",{"path":app.save_slot}))
 action(bar,"Load",app.opening_execute.bind("load",{"path":app.save_slot}))
 action(bar,"Main menu",func():app.game.command("save",{"path":app.save_slot});app.menu())
 text(root,app.last_message,15)
func opening() -> void:
 var stage=app.Campaign.Opening.stage(app.game.s)
 if stage=="TAVERN_RECRUITMENT": tavern();return
 if stage=="DOCKSIDE_CONTRACT":
  var chart=ArrivalMap.new();chart.campaign=app.game;chart.selected=17;chart.squad="first";chart.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(chart)
 else: plate(EMPLOYER if stage=="EMPLOYER_BRIEFING" else (DOCK if stage=="GREYWAKE_ARRIVAL" else VOYAGE))
 var root=root_box();text(root,"THE FALL OF GREYWAKE",23);root.add_spacer(false)
 var box=frame(root);var data=app.Campaign.Opening.content()
 match stage:
  "EMPLOYER_BRIEFING":
   text(box,data.speaker,23);text(box,data.briefing[app.game.s.opening_flow.dialogue_index],22)
   action(box,"Continue briefing",app.opening_execute.bind("opening_next",{}))
   action(box,"Enter tavern",app.opening_execute.bind("opening_skip",{}))
  "COMPANY_CONFIRMATION":
   text(box,"YOUR COMPANY · Confirm departure",25);manifest(box)
   text(box,"Passage is arranged. This commits your chosen company; opening reservations end when you set sail.",17)
   action(box,"Return to tavern",app.opening_execute.bind("opening_back",{}))
   action(box,"Confirm departure",app.opening_execute.bind("opening_depart",{}))
  "BOAT_CROSSING":
   text(box,data.crossing,23)
   action(box,"Skip crossing",app.opening_execute.bind("opening_skip",{}))
  "GREYWAKE_ARRIVAL":
   text(box,data.arrival,25);action(box,"Step ashore",app.opening_execute.bind("opening_next",{}))
  "DOCKSIDE_CONTRACT":
   text(box,data.contract,23);text(box,"You may review the contract, prepare your company or explore before fighting.",17)
   action(box,"Open island map",app.opening_execute.bind("opening_next",{}))
 toolbar(root)
func manifest(parent: Node) -> void:
 var s=app.game.s;var ids=s.squads.first.members;var wages=0;var paid=0
 for id in ids: wages+=s.mercs[id].wage;paid+=s.mercs[id].fee
 text(parent,"COMPANY %d / 6  ·  Hiring fees %d  ·  Remaining %d crowns  ·  Daily wages %d" % [ids.size(),paid,s.funds,wages],18)
 var row=HFlowContainer.new();parent.add_child(row)
 for id in ids:
  var p=s.mercs[id]
  if app.Campaign.Opening.stage(s)=="TAVERN_RECRUITMENT":
   var caption="Remove #"+id.trim_prefix("greywake-recruit-") if id.begins_with("greywake-recruit-") else "Remove "+p.name
   var remove=action(row,caption,app.opening_execute.bind("cancel_opening_hire",{"id":id}))
   remove.clip_text=false;remove.size_flags_horizontal=SIZE_SHRINK_BEGIN
   remove.tooltip_text="Remove "+p.name+" · refund "+str(p.fee)+" crowns"
  else:
   var name_label=text(row,p.name+"  ·  ",16);name_label.autowrap_mode=TextServer.AUTOWRAP_OFF
 if wages>0: text(parent,"Remaining funds cover about %d days of current wages, before provisions and renewal fees." % int(maxi(0,s.funds)/wages),15)
 if wages>0 and s.funds<wages*2: text(parent,"Low reserve: leave enough crowns for provisions, wages and recovery.",16)
func tavern() -> void:
 var bg=ColorRect.new();bg.color=Color("141c1e");bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(bg)
 var root=root_box();text(root,"THE MAINLAND TAVERN · Choose your company",25)
 var body=HBoxContainer.new();body.size_flags_vertical=SIZE_EXPAND_FILL;root.add_child(body)
 var left=VBoxContainer.new();left.size_flags_horizontal=SIZE_EXPAND_FILL;body.add_child(left)
 canvas=TextureRect.new();canvas.texture=TAVERN;canvas.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;canvas.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 canvas.size_flags_vertical=SIZE_EXPAND_FILL;canvas.custom_minimum_size=Vector2(460,140);left.add_child(canvas)
 canvas.mouse_filter=MOUSE_FILTER_IGNORE
 var choices=GridContainer.new();choices.columns=4;left.add_child(choices)
 var rows=app.game.s.recruitment.templates
 for row in rows:
  var hotspot=Button.new();hotspot.text=row.name;hotspot.name="candidate_"+row.id
  hotspot.tooltip_text="%s · %s · fee %d · wage %d/day. Click to inspect." % [row.name,row.tier,row.fee,row.wage]
  var normal=StyleBoxFlat.new();normal.bg_color=Color(0,0,0,.30);normal.border_color=Color(0.8,.69,.42,.25);normal.set_border_width_all(1)
  var hover=normal.duplicate();hover.bg_color=Color(.45,.34,.14,.6);hover.border_color=Color("e1c581");hover.set_border_width_all(2)
  hotspot.clip_text=true
  hotspot.add_theme_stylebox_override("normal",normal);hotspot.add_theme_stylebox_override("hover",hover);hotspot.add_theme_stylebox_override("focus",hover)
  hotspot.add_theme_font_size_override("font_size",round(14*app.desktop.ui_scale) if app.Desktop.enabled() else 14);hotspot.alignment=HORIZONTAL_ALIGNMENT_CENTER
  choices.add_child(hotspot);hotspot.size_flags_horizontal=SIZE_EXPAND_FILL;hotspot.custom_minimum_size.y=44 if OS.has_feature("android") else 36
  hotspot.pressed.connect(func():app.tavern_selected=row.id;app.rebuild(),CONNECT_DEFERRED)
 var profile_scroll=ScrollContainer.new();profile_scroll.custom_minimum_size.x=370*(app.desktop.ui_scale if app.Desktop.enabled() else 1.0);body.add_child(profile_scroll)
 var profile=frame(profile_scroll,true);profile.custom_minimum_size.x=280
 populate_profile(profile,rows)
 var manifest_box=frame(root);manifest(manifest_box)
 var bar=HBoxContainer.new();root.add_child(bar)
 var sail=action(bar,"Set Sail",app.opening_execute.bind("opening_confirm",{}));sail.disabled=app.game.s.squads.first.members.size()<2
 action(bar,"Save selection",app.opening_execute.bind("save",{"path":app.save_slot}))
 action(bar,"Load selection",app.opening_execute.bind("load",{"path":app.save_slot}))
 text(root,app.last_message,15)
func populate_profile(profile: VBoxContainer,rows: Array) -> void:
 if app.tavern_selected=="":
  text(profile,"Select a recruit in the tavern to inspect their profile.",21);return
 var row=rows[0]
 for candidate in rows:
  if candidate.id==app.tavern_selected: row=candidate
 text(profile,row.name,24);text(profile,row.background.capitalize()+" · "+row.tier.capitalize(),18)
 var portrait=TextureRect.new();portrait.texture=ICONS.get_icon(row.background);portrait.custom_minimum_size=Vector2(72,72);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 portrait.mouse_filter=MOUSE_FILTER_IGNORE
 portrait.tooltip_text="Temporary role illustration; an identity-matched portrait is not supplied.";profile.add_child(portrait)
 text(profile,"Role portrait",13)
 if row.has("biography"): text(profile,row.biography,16)
 var stats=GridContainer.new();stats.columns=2;profile.add_child(stats)
 for key in app.Data.Skills.ATTRIBUTES+app.Data.Skills.ALL:
  var stat=text(stats,key.capitalize()+"  "+str(row.attributes.get(key,row.skills.get(key,0))),16)
  stat.autowrap_mode=TextServer.AUTOWRAP_OFF;stat.custom_minimum_size.x=135*(app.desktop.ui_scale if app.Desktop.enabled() else 1.0)
 var kit=[row.weapon,row.armour]
 if row.get("shield",false): kit.append("shield")
 kit.append_array(row.get("secondary_weapons",[]))
 if row.get("ammo_quantity",0)>0: kit.append(str(row.ammo_quantity)+" "+app.Data.ammo_kind_for(row.weapon))
 text(profile,"Equipment: "+", ".join(kit),16)
 text(profile,"Hiring fee %d crowns · Daily wage %d" % [row.fee,row.wage],18)
 var hired=not row.repeatable and app.game.s.mercs["greywake-named-"+row.id].hired
 var available=app.game.s.funds>=row.fee and app.game.s.squads.first.members.size()<6 and not hired
 text(profile,"Already selected" if hired else ("Affordable" if available else "Insufficient funds or full transport"),16)
 if hired: action(profile,"Remove "+row.name,app.opening_execute.bind("cancel_opening_hire",{"id":"greywake-named-"+row.id}))
 var recruit=action(profile,"Recruit "+row.name,app.opening_execute.bind("recruit_template" if row.repeatable else "hire",{"template":row.id,"id":"greywake-named-"+row.id,"squad":"first"}));recruit.disabled=not available
func _process(delta: float) -> void:
 if mode!="opening" or app.game==null: return
 if app.Campaign.Opening.stage(app.game.s)=="BOAT_CROSSING":
  elapsed+=delta
  if elapsed>=4.5: set_process(false);app.opening_execute("opening_next",{})
