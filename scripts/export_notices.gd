extends SceneTree
func _init() -> void:
 var text="Godot Engine runtime and bundled third-party notices\nGenerated from standard Godot "+Engine.get_version_info().string+".\nThese notices describe engine components, not a licence grant for the game.\n\n"+Engine.get_license_text()+"\n\n"
 for component in Engine.get_copyright_info():
  text+=component.name+"\n"
  for part in component.parts:
   text+="Files: "+", ".join(part.files)+"\nCopyright: "+", ".join(part.copyright)+"\nLicence: "+part.license+"\n"
  text+="\n"
 var licences=Engine.get_license_info()
 for name in licences:
  text+="\n--- "+name+" ---\n"+licences[name]+"\n"
 text+="\n\n"+FileAccess.get_file_as_string("res://scripts/android/runtime-notice.txt")
 var f=FileAccess.open("res://THIRD_PARTY_NOTICES.txt",FileAccess.WRITE);f.store_string(text);f.close()
 print("NOTICES: exported ",licences.size()," bundled licence texts");quit()
