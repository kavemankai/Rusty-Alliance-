extends SceneTree
func _init() -> void:
 var stage="";var path=""
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--stage="): stage=arg.trim_prefix("--stage=")
  if arg.begins_with("--save="): path=arg.trim_prefix("--save=")
 if not path.begins_with("user://hardening-"): quit(2);return
 var c=preload("res://sim/campaign.gd").new()
 if not c.load_from(path): quit(3);return
 c.record(11,"Uncommitted subprocess payment");c.save_fault=stage
 if c.save_to(path): quit(4);return
 var marker=FileAccess.open(path+".checkpoint",FileAccess.WRITE);marker.store_string(stage);marker.close()
 OS.kill(OS.get_process_id())
 marker=FileAccess.open(path+".survived",FileAccess.WRITE);marker.store_string("unexpected survival");marker.close()
 quit(91)
