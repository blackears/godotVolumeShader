@tool
extends Node
class_name Image3DTools

static func shrink_mipmap_size(size:Vector3i)->Vector3i:
	return Vector3i(max(1, size.x >> 1), max(1, size.y >> 1), max(1, size.z >> 1))

static func sample_image_stack(image_stack:Array[Image], stack_size:Vector3i, pos:Vector3)->float:
	pos.x = clamp(pos.x, 0, stack_size.x - 1)
	pos.y = clamp(pos.y, 0, stack_size.y - 1)
	pos.z = clamp(pos.z, 0, stack_size.z - 1)
	
	return image_stack[pos.z].get_pixel(pos.x, pos.y).r

static func build_image_stack_mipmaps(image_stack:Array[Image])->Array[Image]:
	var volume_size:Vector3i = Vector3i(image_stack[0].get_width(), image_stack[0].get_height(), image_stack.size())
	
	#Create data buffers
	var num_images:int = volume_size.z
	var mipmap_size:Vector3i = volume_size
	while mipmap_size != Vector3i.ONE:
		mipmap_size = shrink_mipmap_size(mipmap_size)
		num_images += mipmap_size.z
		

	var final_images:Array[Image]
	var baked_data:Array[PackedFloat32Array]
	baked_data.resize(num_images)
	final_images.resize(num_images)

	for i in volume_size.z:
		baked_data[i].resize(volume_size.x * volume_size.y * 4)
	
	mipmap_size = volume_size
	var mipmap_layer_idx:int = volume_size.z
	while mipmap_size != Vector3i.ONE:
		mipmap_size = shrink_mipmap_size(mipmap_size)
		for i in mipmap_size.z:
			baked_data[mipmap_layer_idx + i].resize(mipmap_size.x * mipmap_size.y * 4)
		mipmap_layer_idx += mipmap_size.z

	#Base layer data
	for k in volume_size.z:
		for j in volume_size.y:
			for i in volume_size.x:
				var pix_idx:int = i + j * volume_size.x
				baked_data[k][pix_idx * 4 + 3] = sample_image_stack(image_stack, volume_size, Vector3i(i, j, k))

				var sx0:float = sample_image_stack(image_stack, volume_size, Vector3i(i - 1, j, k))
				var sx1:float = sample_image_stack(image_stack, volume_size, Vector3i(i + 1, j, k))
				var sy0:float = sample_image_stack(image_stack, volume_size, Vector3i(i, j - 1, k))
				var sy1:float = sample_image_stack(image_stack, volume_size, Vector3i(i, j + 1, k))
				var sz0:float = sample_image_stack(image_stack, volume_size, Vector3i(i, j, k - 1))
				var sz1:float = sample_image_stack(image_stack, volume_size, Vector3i(i, j, k + 1))
				
				baked_data[k][pix_idx * 4 + 0] = sx1 - sx0
				baked_data[k][pix_idx * 4 + 1] = sy1 - sy0
				baked_data[k][pix_idx * 4 + 2] = sz1 - sz0

		#print("img volume_size ", volume_size)
		#print("k ", k)
		var img:Image = Image.create_from_data(volume_size.x, volume_size.y, false, 
			Image.FORMAT_RGBAF, baked_data[k].to_byte_array())
		final_images[k] = img
		
		img.save_exr("../../test_image/test_img_" + str(k) + ".exr")
	
	#Create base textures
	mipmap_size = volume_size
	mipmap_layer_idx = 0
	while mipmap_size != Vector3i.ONE:
		var mipmap_size_cur = shrink_mipmap_size(mipmap_size)
		var mipmap_layer_idx_cur = mipmap_layer_idx + mipmap_size.z
		
#		print("-mipmap_size_cur ", mipmap_size_cur)
		
		for k in mipmap_size_cur.z:
			for j in mipmap_size_cur.y:
				for i in mipmap_size_cur.x:
					var sx0 = i * 2
					var sx1 = min(i * 2 + 1, mipmap_size.x - 1)
					var sy0 = j * 2
					var sy1 = min(j * 2 + 1, mipmap_size.y - 1)
					var sz0 = k * 2
					var sz1 = min(k * 2 + 1, mipmap_size.z - 1)
					
					var i00 = (sx0 + sy0 * mipmap_size.x) * 4
					var i01 = (sx0 + sy1 * mipmap_size.x) * 4
					var i10 = (sx1 + sy0 * mipmap_size.x) * 4
					var i11 = (sx1 + sy1 * mipmap_size.x) * 4
					
					for b in 4:
						var v000:float = baked_data[sz0 + mipmap_layer_idx][i00 + b]
						var v001:float = baked_data[sz1 + mipmap_layer_idx][i00 + b]
						var v010:float = baked_data[sz0 + mipmap_layer_idx][i01 + b]
						var v011:float = baked_data[sz1 + mipmap_layer_idx][i01 + b]
						var v100:float = baked_data[sz0 + mipmap_layer_idx][i10 + b]
						var v101:float = baked_data[sz1 + mipmap_layer_idx][i10 + b]
						var v110:float = baked_data[sz0 + mipmap_layer_idx][i11 + b]
						var v111:float = baked_data[sz1 + mipmap_layer_idx][i11 + b]
						
						baked_data[k + mipmap_layer_idx_cur][(i + j * mipmap_size_cur.x) * 4 + b] = (
							v000 + v001 + v010 + v011 + v100 + v101 + v110 + v111) / 8.0

			#print("mipmap mipmap_size_cur ", mipmap_size_cur)
			#print("k + mipmap_layer_idx_cur ", k + mipmap_layer_idx_cur)
			var img:Image = Image.create_from_data(mipmap_size_cur.x, mipmap_size_cur.y, false, 
				Image.FORMAT_RGBAF, baked_data[k + mipmap_layer_idx_cur].to_byte_array())
			final_images[k + mipmap_layer_idx_cur] = img
		
		mipmap_size = mipmap_size_cur
		mipmap_layer_idx = mipmap_layer_idx_cur
	
	
	return final_images
	
	#var img3d:ImageTexture3D = ImageTexture3D.new()
	#var err:Error = img3d.create(Image.FORMAT_RGBAF, volume_size.x, volume_size.y, volume_size.z, true, final_images)
	#if err == OK:
		#return img3d
	#
	#return null
