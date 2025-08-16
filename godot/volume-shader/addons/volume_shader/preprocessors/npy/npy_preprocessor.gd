@tool
extends Window
class_name NpyPreprocessor

@onready var lineedit_npy_file:LineEdit = %LineEdit_npy_file
@onready var lineedit_outfile:LineEdit = %LineEdit_outfile
@onready var file_dialog_npy_browse:FileDialog = %FileDialog_npy_browse
@onready var file_dialog_save:FileDialog = %FileDialog_save
@onready var option_compression:OptionButton = %OptionButton_compression

func _on_bn_cancel_pressed() -> void:
	queue_free()
	pass # Replace with function body.


func _on_bn_bake_pressed() -> void:
	var npy_loader:NpyLoader = NpyLoader.new()
	var path:String = lineedit_npy_file.text
	if !FileAccess.file_exists(path):
		return
	
	var out_path:String = lineedit_outfile.text
	if out_path == "":
		return
	if !out_path.ends_with(".vol3d"):
		out_path += ".vol3d"
	
	npy_loader.load_file(path)
	
	if npy_loader.valid:
		if npy_loader.shape.size() == 4:
			var progress_dialog:NpyProgressDialog = preload("res://addons/volume_shader/preprocessors/npy/npy_progress_dialog.tscn").instantiate()
			add_child(progress_dialog)
			progress_dialog.popup_centered()
			
			var volume:Vector3i = Vector3i(npy_loader.shape[3], npy_loader.shape[2], npy_loader.shape[1])
			
			var vol_saver:Volume3DSaver = Volume3DSaver.new()
			vol_saver.open(out_path, volume, npy_loader.shape[0], option_compression.selected)
			
			var thread:Thread = Thread.new()
			thread.start(bake_process.bind(npy_loader, progress_dialog, vol_saver))

			while thread.is_alive():
				await get_tree().process_frame
				
			thread.wait_to_finish()
			vol_saver.close()
	

func bake_process(npy_loader:NpyLoader, progress_dialog:NpyProgressDialog, vol_saver:Volume3DSaver):
	print("data shape ", npy_loader.shape)
	
	for page_idx in npy_loader.shape[0]:
		print("baking frame ", page_idx, " / ", npy_loader.shape[0])
		
		progress_dialog.progress = page_idx / float(npy_loader.shape[0])
		
		var image_stack:Array[Image] = npy_loader.load_image_stack(page_idx)
		
		var final_images:Array[Image] = Image3DTools.build_image_stack_mipmaps(image_stack)
		#await get_tree().create_timer(.5).timeout
		
		vol_saver.append_image_stack(final_images)
		#for i in final_images.size():
			#var img_buf:PackedByteArray = final_images[i].save_png_to_buffer()
			
		
		if progress_dialog.cancel_raised:
		#if canceled:
			break
				
	
	progress_dialog.progress = 1
	progress_dialog.queue_free()
	pass # Replace with function body.




func _on_file_dialog_npy_browse_file_selected(path: String) -> void:
	lineedit_npy_file.text = path


func _on_bn_browse_npy_pressed() -> void:
	file_dialog_npy_browse.popup_centered()


func _on_file_dialog_save_file_selected(path: String) -> void:
	lineedit_outfile.text = path
	
func _on_bn_browse_output_pressed() -> void:
	file_dialog_save.popup_centered()
