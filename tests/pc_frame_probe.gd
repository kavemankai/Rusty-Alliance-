extends SceneTree
func _init() -> void: call_deferred("run")
func run() -> void:
 var app=load("res://main.tscn").instantiate();app.desktop.path="user://pc-frame-probe.cfg";root.add_child(app)
 app.start_greywake();app.game.autosave_path="user://pc-frame-probe-auto.json";app.game.command("opening_skip")
 for repeat in range(6): app.game.command("recruit_template",{"template":"militia_spearman"})
 for action in ["opening_confirm","opening_depart","opening_skip","opening_next","opening_next","dockside_start","confirm_deployment"]: app.game.command(action)
 app.rebuild();root.size=Vector2i(1920,1080);root.grab_focus()
 var rows=[]
 var sampler=preload("res://tests/pc_frame_sampler.gd").new();app.add_child(sampler)
 for config in [[true,60],[true,0],[false,60],[false,120]]:
  app.desktop.vsync=config[0];app.desktop.frame_limit=config[1];app.desktop.apply_window(root);app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
  for warmup in range(20): await process_frame
  sampler.start();var start_frames=Engine.get_process_frames();var start=Time.get_ticks_usec()
  for frame in range(60): await process_frame
  var times=sampler.finish();var actual_fps=(Engine.get_process_frames()-start_frames)*1000000.0/(Time.get_ticks_usec()-start)
  times.sort();rows.append({"vsync":config[0],"cap":config[1],"focused":root.has_focus(),"median_ms":times[times.size()/2],"p95_ms":times[int(times.size()*.95)],"vsync_actual":DisplayServer.window_get_vsync_mode(),"actual_process_fps":actual_fps,"engine_fps":Engine.get_frames_per_second(),"samples":times.size()})
 var report={"os_low_processor":OS.low_processor_usage_mode,"low_processor_sleep_usec":OS.low_processor_usage_mode_sleep_usec,"engine_cap":Engine.max_fps,"args":OS.get_cmdline_args(),"time_scale":Engine.time_scale,"screen_hz":DisplayServer.screen_get_refresh_rate(),"configurations":rows,"render_pixels":[app.battle_view.viewport.size.x,app.battle_view.viewport.size.y],"limits":"One shared Windows/NVIDIA host, six-person dockside battle, native 1920x1080 window. No simulation timing changes."}
 var output=FileAccess.open("res://pc-frame-probe-results.json",FileAccess.WRITE);output.store_string(JSON.stringify(report,"  "));output.close();print("PC_FRAME_PROBE: "+JSON.stringify(report))
 app.queue_free();await process_frame;await process_frame;quit()
