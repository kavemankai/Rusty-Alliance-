extends RefCounted
# Shared image/name selection treatment; presentation state only.
static func apply(button: Button,selected: bool) -> void:
 var faint=StyleBoxFlat.new()
 faint.bg_color=Color(.04,.065,.065,.38)
 faint.border_color=Color(.80,.69,.42,.30)
 faint.set_border_width_all(1);faint.set_corner_radius_all(4)
 faint.set_content_margin_all(5)
 var hover=faint.duplicate()
 hover.bg_color=Color(.21,.18,.11,.42)
 hover.border_color=Color(.88,.77,.50,.65)
 hover.shadow_color=Color(.92,.72,.32,.13);hover.shadow_size=5
 var active=hover.duplicate()
 active.border_color=Color(.95,.80,.46,.92)
 active.shadow_color=Color(.96,.75,.33,.25);active.shadow_size=9
 active.bg_color=Color(.23,.19,.10,.52)
 var focus=StyleBoxFlat.new()
 focus.bg_color=Color(0,0,0,0);focus.border_color=Color(.98,.87,.61,.85)
 focus.set_border_width_all(2);focus.set_corner_radius_all(4)
 button.toggle_mode=true
 button.set_pressed_no_signal(selected)
 button.add_theme_stylebox_override("normal",active if selected else faint)
 button.add_theme_stylebox_override("hover",active if selected else hover)
 button.add_theme_stylebox_override("pressed",active)
 button.add_theme_stylebox_override("hover_pressed",active)
 button.add_theme_stylebox_override("focus",focus)
