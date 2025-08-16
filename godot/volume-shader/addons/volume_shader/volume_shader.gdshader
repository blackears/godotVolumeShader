/*
* MIT License
*
* Copyright (c) 2025 Mark McKay
* https://github.com/blackears/godot_volume_layers
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

shader_type spatial;
render_mode unshaded, cull_front;

const int MAX_EXCLUSION_PLANES = 4;

uniform sampler3D texture_volume : source_color,filter_linear_mipmap,repeat_disable;
uniform sampler2D gradient: filter_linear_mipmap,repeat_disable;
//uniform float zoom = 2;
uniform float bounding_radius = 1;
//uniform vec3 aabb_size;
uniform int layers = 200;
//uniform float opacity = 1;
uniform float gamma = 1;
uniform bool flip_normals = false;
//uniform float color_scalar = 1;
uniform int num_exclusion_planes = 0;
uniform vec4[MAX_EXCLUSION_PLANES] exclusion_planes;
//uniform vec3 light_position = vec3(0, 0, 0);

varying vec3 pos_local;
varying vec3 pos_world;
//varying float view_radius;
varying float model_radius;

void vertex() {
	pos_local = VERTEX;
	pos_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
//	view_radius = length(MODELVIEW_MATRIX * vec4(aabb_size, 0.0));
//	view_radius = length(MODELVIEW_MATRIX * vec4(1, 1, 1, 0.0));
	model_radius = length(MODEL_MATRIX * vec4(1, 1, 1, 0.0));
	
}

vec3 isect_plane(vec3 view_origin, vec3 view_dir, vec3 plane_point, vec3 plane_dir)
{
	float s = dot((plane_point - view_origin), plane_dir) / dot(view_dir, plane_dir);
	return s * view_dir + view_origin;
}

//https://graemephi.github.io/posts/calculating-lod/
float calc_mipmap_lod(vec2 tex_size, vec2 uv) {
	vec2 dx = dFdx(tex_size * uv);
	vec2 dy = dFdy(tex_size * uv);
	
	float d = max(length(dx), length(dy));
	float lod = max(0.0, log2(d));
	return lod;
}

float calc_mipmap_lod(vec3 tex_size, vec3 uvw) {
	vec3 dx = dFdx(tex_size * uvw);
	vec3 dy = dFdy(tex_size * uvw);
	
	float d = max(length(dx), length(dy));
	float lod = max(0.0, log2(d));
	return lod;
}


void fragment() {
	vec3 model_origin_world = NODE_POSITION_WORLD;
	vec3 plane_norm = normalize(CAMERA_POSITION_WORLD - model_origin_world);
	
	vec4 total_col = vec4(0, 0, 0, 0);
	
	vec3 light_pos_view = vec3(0, 0, 0);
	vec3 light_pos_world = (INV_VIEW_MATRIX * vec4(light_pos_view, 1)).xyz;

	float gap_size = 1.0 / float(layers + 1);
	
	for (int layer_idx = 0; layer_idx < layers; ++layer_idx)
	{
		float layer_frac = float(layer_idx + 1) / float(layers + 1);
		layer_frac = layer_frac * 2.0 - 1.0;
//		vec3 plane_origin = model_origin_world + plane_norm * (layer_frac - .5) * 2.0;
		vec3 plane_origin = model_origin_world + model_radius * plane_norm * (-layer_frac);
		
		vec3 p_world = isect_plane(CAMERA_POSITION_WORLD, pos_world - CAMERA_POSITION_WORLD, plane_origin, plane_norm);
		
		bool plane_test_passed = true;
		for (int i = 0; i < min(num_exclusion_planes, MAX_EXCLUSION_PLANES); ++i)
		{
			if (dot(vec4(p_world, -1.0), exclusion_planes[i]) > 0.0) {
				plane_test_passed = false;
				break;
			}
		}
		if (!plane_test_passed)
			continue;
		
		mat4 inv_model_mtx = inverse(MODEL_MATRIX);
		vec3 p_local = (inv_model_mtx * vec4(p_world, 1.0)).xyz;
		
		vec3 tex_sample_pt = (p_local + vec3(.5, .5, .5));
		vec4 vol_sample = texture(texture_volume, tex_sample_pt);
		if (vol_sample.a <= 0.001)
			continue;
		if (tex_sample_pt.x < 0.0 || tex_sample_pt.x > 1.0 
			|| tex_sample_pt.y < 0.0 || tex_sample_pt.y > 1.0 
			|| tex_sample_pt.z < 0.0 || tex_sample_pt.z > 1.0)
			continue;
		
		//ivec3 vol_tex_size = textureSize(texture_volume, 0);
		//vec3 vol_cell_step = 1.0 / vec3(vol_tex_size);
		//float volume_grad = 
			//texture(texture_volume, tex_sample_pt + vec3(vol_cell_step.x, 0, 0)).r;
		
		
		vec3 world_grad = MODEL_NORMAL_MATRIX * vol_sample.rgb;
		vec3 world_norm = normalize(flip_normals ? world_grad : -world_grad);
		
		vec3 light_offset = normalize(CAMERA_POSITION_WORLD - p_world);
		float illuminate = max(dot(light_offset, world_norm), 0);
		
		
		vec4 layer_col = texture(gradient, vec2(pow(vol_sample.a, gamma), 0)).rbga;
		layer_col.xyz *= illuminate;


		total_col.rgb = (total_col.rgb) + (1.0 - total_col.a) * layer_col.a * layer_col.rgb;
		total_col.a = total_col.a + (1.0 - total_col.a) * layer_col.a;
		if (total_col.a >= 1.0) {
			break;
		}
	}
		
	ALBEDO = total_col.xyz;
	ALPHA = total_col.a;
}
