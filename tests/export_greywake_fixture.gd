extends SceneTree
func _init() -> void:
 var campaign=preload("res://sim/campaign.gd").new()
 if not campaign.configure_new_greywake(preload("res://tests/skills.gd").synthetic_roster()): quit(1);return
 DirAccess.make_dir_recursive_absolute("res://builds")
 if not campaign.save_to("res://builds/greywake-synthetic-android-fixture.json"): quit(1);return
 print("GREYWAKE_FIXTURE: synthetic test-only roster; excluded from player exports")
 quit()
