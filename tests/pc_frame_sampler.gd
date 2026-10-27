extends Node
# Sample actual process callbacks, not coroutine resume intervals (which can
# span multiple engine frames). Never invokes commands or changes game state.
var active=false
var frames=[]
func _process(delta: float) -> void:
 if active: frames.append(delta*1000.0)
func start() -> void: frames.clear();active=true
func finish() -> Array: active=false;return frames.duplicate()
