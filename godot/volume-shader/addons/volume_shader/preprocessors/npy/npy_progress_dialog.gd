@tool
extends Window
class_name NpyProgressDialog

signal cancel_bake

@export var progress:float = 0

@onready var progress_bar:ProgressBar = %ProgressBar

var cancel_raised:bool = false

func _process(delta: float) -> void:
	progress_bar.value = progress
	pass


func _on_bn_cancel_pressed() -> void:
	cancel_bake.emit()
	cancel_raised = true
	pass # Replace with function body.
