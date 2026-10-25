extends RefCounted
const Campaign=preload("res://sim/campaign.gd")
const Field=preload("res://tests/exploration_cases.gd")
const Records=preload("res://sim/records.gd")
static func erase_family(path: String) -> void:
 for suffix in ["",".bak",".tmp",".bak.tmp",".checkpoint",".survived"]:
  if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
static func put(path: String,raw: String) -> void:
 var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(raw);f.close()
static func run(test) -> void:
 var c=Campaign.new();var path="user://hardening-cases.json"
 erase_family(path)
 test.check(c.command("assignment",{"id":"mara","value":"training"}) and Records.Assignment.decode(c.s.mercs.mara.assignment_record).kind=="training","Assignment command stores a typed actor/task/location/time record")
 test.check(Records.Event.decode({"id":1,"at":10,"kind":"arrival","payload":{}})==null and Records.Transaction.decode({"time":0,"amount":1.5,"reason":"x","balance":2})==null,"Typed records reject missing event payload and fractional transactions")
 var mutations=[[["mercs","mara","inventory"],null],[["mercs","mara","injuries"],[{"location":"legs","severity":{},"treated":false}]],[["mercs","mara","equipment"],[]],[["mercs","mara","hp"],1.5],[["mercs","mara","max_hp"],0],[["mercs","mara","assignment_record","actor"],"oswin"],[["mercs","mara","inventory",0,"quantity"],-1],[["mercs","mara","inventory",0,"condition"],101],[["events",0,"payload"],[]],[["events",0,"kind"],"invented"],[["events",0,"id"],0],[["events",0,"at"],-1],[["ledger",0,"balance"],999],[["ledger",0,"reason"],null],[["pending_encounters"],null],[["squads","first","members"],{}],[["squads","first","sector"],256],[["squads","first","route"],[255]],[["groups",0,"positions"],[]],[["groups",0,"fighters"],[null]],[["sectors",0,"id"],3],[["sectors",0,"levies"],[null]],[["sectors",0,"supplies"],null],[["factions","bandits","resources"],-1],[["funds"],null],[["version"],99]]
 var original=JSON.stringify(c.s)
 for mutation in mutations:
  var detached=c.s.duplicate(true);var cursor=detached;var keys=mutation[0]
  for i in range(keys.size()-1): cursor=cursor[keys[i]]
  cursor[keys[-1]]=mutation[1]
  put(path,JSON.stringify(detached))
  test.check(not c.load_from(path) and JSON.stringify(c.s)==original,"Malformed save is rejected without changing live campaign: "+str(keys))
 erase_family(path)
 var field=Field.field();field.command("confirm_deployment")
 test.check(field.save_to(path),"Active battle with typed records saves before corruption probes")
 var active=field.s.duplicate(true)
 var probes=[[["battle","units",0,"person"],null],[["battle","tiles",0,"cost"],"bad"],[["battle","knowledge","company"],[null]],[["battle","noise"],[null]],[["battle","units",0,"x"],0.5],[["battle","ground"],[null]],[["battle","fog","company"],null],[["battle","exploration"],[]]]
 for mutation in probes:
  erase_family(path);var detached=active.duplicate(true);var cursor=detached;var keys=mutation[0]
  for i in range(keys.size()-1): cursor=cursor[keys[i]]
  cursor[keys[-1]]=mutation[1]
  put(path,JSON.stringify(detached))
  test.check(not c.load_from(path) and JSON.stringify(c.s)==original,"Malformed tactical save is rejected: "+str(keys))
 # Interrupted writes must preserve the last committed state, including backups.
 for stage in ["partial_write","after_temp","backup_write","after_backup"]:
  erase_family(path);c=Campaign.new();test.check(c.save_to(path),"Recovery fixture commits: "+stage)
  var committed=JSON.stringify(c.s);c.record(7,"Pending test payment");c.save_fault=stage
  test.check(not c.save_to(path),"Injected interruption reports failure: "+stage)
  var loaded=Campaign.new()
  test.check(loaded.load_from(path) and JSON.stringify(loaded.s)==committed,"Interrupted write keeps previous committed campaign: "+stage)
  # Kill a separate engine process at the same filesystem checkpoint.
  var output=[]
  var code=OS.execute(OS.get_executable_path(),["--headless","--path",ProjectSettings.globalize_path("res://"),"--script","tests/crash_writer.gd","--","--stage="+stage,"--save="+path],output,true)
  test.check(FileAccess.get_file_as_string(path+".checkpoint")==stage and not FileAccess.file_exists(path+".survived") and loaded.load_from(path) and JSON.stringify(loaded.s)==committed,"Process termination recovers committed campaign: "+stage)
 erase_family(path);c=Campaign.new();c.save_to(path);var older=JSON.stringify(c.s)
 c.record(9,"New committed payment");c.save_to(path);put(path,"{truncated")
 test.check(c.load_from(path) and JSON.stringify(c.s)==older and c.recovery_source==path+".bak","Truncated current file restores verified prior backup")
 erase_family(path);c=Campaign.new();c.save_fault="after_temp";c.save_to(path)
 test.check(c.load_from(path) and c.recovery_source==path+".tmp","First-save interruption can recover a fully validated temporary file")
 erase_family(path)
