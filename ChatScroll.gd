## https://www.youtube.com/watch?v=UtlwA4LU2II
extends ScrollContainer

@onready var scrollbar = self.get_v_scroll_bar()

func _ready() -> void:
	scrollbar.connect("changed", handle_scrollbar_changed)

func handle_scrollbar_changed():
	self.scroll_vertical = scrollbar.max_value
