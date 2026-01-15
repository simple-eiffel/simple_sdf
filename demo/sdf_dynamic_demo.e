note
	description: "[
		SDF Dynamic Shader Demo - Runtime GLSL compilation with DSL.

		Demonstrates:
		1. Building SDF scene in Eiffel code
		2. Generating GLSL shader with SDF_GLSL_BUILDER
		3. Compiling to SPIR-V at runtime with SIMPLE_SHADERC
		4. Running the shader on GPU with SIMPLE_VULKAN

		Controls:
			WASD - Move camera
			Space/Shift - Up/Down
			Arrow keys - Look around
			1-3 - Switch scenes
			ESC - Exit
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SDF_DYNAMIC_DEMO

create
	make

feature {NONE} -- Initialization

	make
			-- Run the dynamic shader demo.
		local
			l_sdf: SDF_QUICK
			l_builder: SDF_GLSL_BUILDER
			l_shaderc: SIMPLE_SHADERC
			l_glsl: STRING
			l_spirv: detachable MANAGED_POINTER
			l_shader_dir: STRING
			l_shader_path: STRING
			l_env: EXECUTION_ENVIRONMENT
		do
			print ("SDF Dynamic Shader Demo%N")
			print ("========================%N%N")

			-- Get shader directory
			create l_env
			if attached l_env.item ("SIMPLE_EIFFEL") as se then
				l_shader_dir := se.to_string_8 + "/simple_vulkan/shaders/"
			else
				l_shader_dir := "shaders/"
			end
			l_shader_path := l_shader_dir + "dynamic_scene.spv"

			-- Step 1: Build GLSL using DSL
			print ("1. Generating GLSL shader...%N")
			create l_builder.make
			l_glsl := l_builder.generate_basic_shader (scene_sphere_and_box)
			print ("   Generated " + l_glsl.count.out + " bytes of GLSL%N")

			-- Step 2: Compile to SPIR-V at runtime
			print ("2. Compiling GLSL to SPIR-V...%N")
			create l_shaderc.make
			l_spirv := l_shaderc.compile_compute (l_glsl)

			if attached l_spirv as spv then
				print ("   Compiled to " + spv.count.out + " bytes of SPIR-V%N")

				-- Step 3: Save shader
				print ("3. Saving shader to " + l_shader_path + "%N")
				l_shaderc.save_spirv (spv, l_shader_path)

				-- Step 4: Launch renderer
				print ("4. Launching GPU renderer...%N%N")
				create l_sdf.make_with_shader ("Dynamic SDF Scene", 1280, 720, "dynamic_scene.spv")
				l_sdf.set_camera (0.0, 2.0, 8.0)
				l_sdf.run
			else
				print ("   ERROR: GLSL compilation failed%N")
				print ("   " + l_shaderc.last_error + "%N")
			end

			l_shaderc.dispose
		end

feature {NONE} -- Scene Definitions

	scene_sphere_and_box: STRING
			-- Simple scene with sphere and box.
		do
			Result := "[
    float d = 1e10;
    // Ground plane
    d = opUnion(d, sdPlane(p, vec3(0, 1, 0), 0.0));
    // Sphere
    d = opSmoothUnion(d, sdSphere(p, vec3(0.0, 1.0, 0.0), 1.0), 0.3);
    // Box
    d = opSmoothUnion(d, sdBox(p, vec3(2.5, 0.75, 0.0), vec3(0.75, 0.75, 0.75)), 0.2);
    // Cylinder
    d = opSmoothUnion(d, sdCylinder(p, vec3(-2.5, 0.0, 0.0), 0.5, 1.5), 0.2);
    return d;
			]"
		end

	scene_torus_tower: STRING
			-- Stacked torus scene.
		do
			Result := "[
    float d = 1e10;
    // Ground
    d = opUnion(d, sdPlane(p, vec3(0, 1, 0), 0.0));
    // Stacked toruses
    d = opSmoothUnion(d, sdTorus(p, vec3(0.0, 0.3, 0.0), 1.5, 0.3), 0.2);
    d = opSmoothUnion(d, sdTorus(p, vec3(0.0, 1.0, 0.0), 1.0, 0.25), 0.15);
    d = opSmoothUnion(d, sdTorus(p, vec3(0.0, 1.6, 0.0), 0.6, 0.2), 0.1);
    d = opSmoothUnion(d, sdSphere(p, vec3(0.0, 2.2, 0.0), 0.4), 0.15);
    return d;
			]"
		end

	scene_carved_sphere: STRING
			-- Sphere with carved holes.
		do
			Result := "[
    float d = 1e10;
    // Ground
    d = opUnion(d, sdPlane(p, vec3(0, 1, 0), 0.0));
    // Main sphere
    float sphere = sdSphere(p, vec3(0.0, 1.5, 0.0), 1.5);
    // Carve out cylinders
    float hole1 = sdCylinder(p, vec3(0.0, 1.5, 0.0), 0.4, 2.0);
    float hole2 = sdCylinder(p - vec3(0, 1.5, 0), vec3(0, 0, 0), 0.4, 2.0);  // rotated
    sphere = opSubtraction(sphere, hole1);
    d = opUnion(d, sphere);
    return d;
			]"
		end

end
