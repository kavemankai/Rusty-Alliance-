extends RefCounted
const Desktop=preload("res://ui/desktop.gd")
const CAMERA_KEYS=[KEY_W,KEY_A,KEY_S,KEY_D,KEY_UP,KEY_LEFT,KEY_DOWN,KEY_RIGHT]
static func modal(app) -> bool:
 if is_instance_valid(app.battle_radial) and app.battle_radial.visible: return true
 for child in app.ui.get_children():
  if child is Window and child.visible: return true
 return false
static func typing(app) -> bool:
 var focus=app.get_viewport().gui_get_focus_owner()
 return focus is LineEdit or focus is TextEdit
static func board_active(app) -> bool:
 return app.game!=null and not app.title_visible and app.tab=="sector" and not app.game.Opening.locked(app.game.s) and not modal(app) and not typing(app)
static func key_input(app,event: InputEventKey) -> bool:
 if not event.pressed:
  app.pan_keys.erase(event.keycode);return false
 if event.echo: return false
 if app.binding_action!="":
  if event.keycode==KEY_ESCAPE: app.binding_action="";refresh_settings(app);return true
  var error=app.desktop.bind_key(app.binding_action,event.get_keycode_with_modifiers())
  if error=="": app.binding_action="";refresh_settings(app)
  elif is_instance_valid(app.desktop_feedback): app.desktop_feedback.text=error
  return true
 if modal(app): return false
 if app.desktop.matches("fullscreen",event):
  app.desktop.fullscreen=not app.desktop.fullscreen;app.desktop.apply_window(app.get_window());app.desktop.save_settings();return true
 if app.desktop.matches("help",event): help(app);return true
 if typing(app) or app.title_visible or app.game==null: return false
 if app.desktop.matches("load",event):
  app.pause_desktop();app.ask("Load the saved campaign? Unsaved progress will be replaced.",func():app.run_command("load",{"path":app.save_slot}));return true
 if app.game.Opening.locked(app.game.s):
  if app.desktop.matches("save",event) or (event.ctrl_pressed and event.keycode==KEY_S): app.opening_execute("save",{"path":app.save_slot});return true
  return false
 if event.keycode==KEY_ESCAPE:
  app.pan_keys.clear()
  if app.target!="" or not app.destination.is_empty(): app.cancel_preview()
  elif app.tab=="settings": app.change_tab("sector")
  else: app.change_tab("settings")
  return true
 if app.desktop.matches("save",event) or (event.ctrl_pressed and event.keycode==KEY_S): app.run_command("save");return true
 for action in ["inventory","company","contracts","map"]:
  if app.desktop.matches(action,event): app.change_tab({"inventory":"inventory","company":"company","contracts":"contracts","map":"sector"}[action]);return true
 if not board_active(app): return false
 if event.keycode in CAMERA_KEYS and not event.ctrl_pressed and not event.alt_pressed:
  app.pan_keys[event.keycode]=true;return true
 if app.desktop.matches("reset_camera",event):
  if is_instance_valid(app.battle_view): app.battle_view.reset_camera()
  elif is_instance_valid(app.map_view): app.map_view.reset_camera()
  return true
 if app.desktop.matches("center",event):
  if is_instance_valid(app.battle_view): app.battle_view.center_on(app.selected)
  elif is_instance_valid(app.map_view): app.map_view.center_on(app.game.s.squads[app.squad].sector)
  return true
 if app.game.battle==null: return false
 if event.keycode>=KEY_1 and event.keycode<=KEY_9 and not event.ctrl_pressed and not event.shift_pressed and not event.alt_pressed:
  app.select_fighter(event.keycode-KEY_1);return true
 var focus=app.get_viewport().gui_get_focus_owner()
 if app.desktop.matches("next_unit",event) and focus==null: app.cycle_fighter(1);return true
 if event.keycode==KEY_TAB and event.shift_pressed and focus==null: app.cycle_fighter(-1);return true
 if app.desktop.matches("confirm",event) and focus==null: app.confirm_preview();return true
 if app.desktop.matches("end_turn",event) and focus==null:
  if app.game.battle.t.phase=="combat": app.end_player_turn()
  return true
 if app.desktop.matches("reload",event): app.battle_action("reload");return true
 if app.desktop.matches("guard",event): app.battle_action("guard");return true
 return false
static func pan(app,delta: float) -> void:
 if app.pan_keys.is_empty() or not board_active(app): return
 var keys=app.pan_keys
 var direction=Vector2(int(keys.has(KEY_D) or keys.has(KEY_RIGHT))-int(keys.has(KEY_A) or keys.has(KEY_LEFT)),int(keys.has(KEY_S) or keys.has(KEY_DOWN))-int(keys.has(KEY_W) or keys.has(KEY_UP))).normalized()
 if is_instance_valid(app.battle_view): app.battle_view.pan_screen(-direction*delta*600)
 elif is_instance_valid(app.map_view): app.map_view.offset-=direction*delta*500;app.map_view.queue_redraw()
static func help(app) -> void:
 app.pause_desktop()
 var dialog=AcceptDialog.new();dialog.title="PC controls";dialog.dialog_text="Left click: select fighter, target or destination\nMiddle drag / WASD / arrows: pan · Wheel: zoom\nRight click / Escape: cancel preview; Escape again: pause\n1–9: select fighter · Shift+Tab: previous fighter\n"
 for action in Desktop.DEFAULT_KEYS: dialog.dialog_text+=app.desktop.key_name(action)+": "+Desktop.TITLES[action]+"\n"
 dialog.dialog_text+="\nShortcuts act on the same previews and AP rules as the buttons.\nKeyboard shortcuts are suspended while typing or a dialog is open.\nBindings and display options can be changed in Settings."
 app.ui.add_child(dialog);dialog.popup_centered(Vector2i(650,620));dialog.confirmed.connect(func():dialog.queue_free())
static func refresh_settings(app) -> void:
 if app.title_visible: app.title_settings()
 else: app.show_panel()
static func settings(app,parent: Node) -> void:
 app.label(parent,"PC DISPLAY & CONTROLS")
 app.button(parent,"Fullscreen: "+("On" if app.desktop.fullscreen else "Off"),func():app.desktop.fullscreen=not app.desktop.fullscreen;apply(app))
 app.button(parent,"VSync: "+("On" if app.desktop.vsync else "Off"),func():app.desktop.vsync=not app.desktop.vsync;apply(app))
 app.button(parent,"Frame limit: "+("Unlimited" if app.desktop.frame_limit==0 else str(app.desktop.frame_limit)+" FPS"),func():var values=[30,60,120,0];app.desktop.frame_limit=values[(values.find(app.desktop.frame_limit)+1)%4];apply(app))
 app.button(parent,"UI size: %d%%" % round(app.desktop.ui_scale*100),func():var values=[.9,1.0,1.15,1.3];app.desktop.ui_scale=values[(values.find(app.desktop.ui_scale)+1)%4];apply(app,true))
 app.button(parent,"Battle resolution: %d%%" % round(app.desktop.render_scale*100),func():var values=[.5,.75,1.0,1.25];app.desktop.render_scale=values[(values.find(app.desktop.render_scale)+1)%4];apply(app))
 app.button(parent,"Controls help",func():help(app))
 if app.game!=null and not app.title_visible: app.button(parent,"Developer inspector",func():app.change_tab("debug"))
 app.desktop_feedback=app.label(parent,"WASD/arrows pan. Escape cancels a binding change.")
 if app.binding_action!="": app.desktop_feedback.text="Press a new key for "+Desktop.TITLES[app.binding_action]+". Escape cancels."
 for action in Desktop.DEFAULT_KEYS:
  app.button(parent,Desktop.TITLES[action]+" key: "+app.desktop.key_name(action),func():app.binding_action=action;refresh_settings(app))
 app.button(parent,"Restore PC defaults",func():app.desktop.keys=Desktop.DEFAULT_KEYS.duplicate();app.desktop.ui_scale=1.0;app.desktop.render_scale=1.0;app.desktop.frame_limit=60;app.desktop.vsync=true;app.desktop.fullscreen=false;app.binding_action="";apply(app,true))
static func apply(app,rebuild: bool=false) -> void:
 app.desktop.apply_window(app.get_window());app.desktop.save_settings();app.apply_desktop_theme()
 if is_instance_valid(app.battle_view): app.battle_view.render_scale=app.desktop.render_scale;app.battle_view.update_render_size()
 if rebuild and not app.title_visible: app.rebuild()
 else: refresh_settings(app)
