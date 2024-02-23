extends HBoxContainer

@export var address := ""
@export var enable := false

func _ready() -> void:
    $CheckBox.button_pressed = enable
    $TextEdit.text = address

func _process(_delta: float) -> void:
    enable = $CheckBox.button_pressed
    address = $TextEdit.text
