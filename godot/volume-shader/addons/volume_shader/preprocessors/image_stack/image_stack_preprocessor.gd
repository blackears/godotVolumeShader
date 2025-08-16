@tool
extends Window
class_name ImageStackPreporcessor

@onready var file_dialog_img_browse:FileDialog = %FileDialog_img_browse
@onready var file_dialog_save:FileDialog = %FileDialog_save
@onready var itemlist_files:ItemList = %ItemList_files
@onready var lineedit_outfile:LineEdit = %LineEdit_outfile

func _on_bn_browse_pressed() -> void:
	file_dialog_img_browse.popup_centered()
	
	pass # Replace with function body.


func _on_file_dialog_img_browse_files_selected(paths: PackedStringArray) -> void:
	for path in paths:
		itemlist_files.add_item(path)
	


func _on_file_dialog_save_file_selected(path: String) -> void:
	lineedit_outfile.text = path
	pass # Replace with function body.


func _on_bn_cancel_pressed() -> void:
	queue_free()


func _on_bn_clear_pressed() -> void:
	itemlist_files.clear()
	pass # Replace with function body.

func _on_bn_bake_pressed() -> void:
	var image:ImageTexture3D = create_image_3d()
	if image:
		var path:String = lineedit_outfile.text
		if !path.ends_with(".res") && !path.ends_with(".tres"):
			path = path + ".res"
		
		ResourceSaver.save(image, path, ResourceSaver.FLAG_COMPRESS)
		pass
	pass

func create_image_3d()->ImageTexture3D:
	var image_stack:Array[Image]
	
	for idx in itemlist_files.item_count:
		var path:String = itemlist_files.get_item_text(idx)
		var img:Image = Image.load_from_file(path)
		if img:
			image_stack.append(img)
	
	var volume_size:Vector3i = Vector3i(image_stack[0].get_width(), image_stack[0].get_height(), image_stack.size())
	
	for i in range(1, image_stack.size() - 1):
		if image_stack[i].get_width() != volume_size.x || image_stack[i].get_height() != volume_size.y:
			#Mismatched image sizes
			return null

	var final_images:Array[Image] = Image3DTools.build_image_stack_mipmaps(image_stack)
	
	var img3d:ImageTexture3D = ImageTexture3D.new()
	var err:Error = img3d.create(Image.FORMAT_RGBAF, volume_size.x, volume_size.y, volume_size.z, true, final_images)
	if err == OK:
		return img3d
	
	return null
	
func _on_close_requested() -> void:
#	hide()
	queue_free()
	pass # Replace with function body.


func _on_bn_browse_output_pressed() -> void:
	file_dialog_save.current_path = lineedit_outfile.text
	file_dialog_save.popup_centered()
	pass # Replace with function body.
