note
	description: "[
		Medieval Village Demo - GPU-accelerated SDF ray marching.

		A procedural medieval European village scene featuring:
		- Half-timbered houses with pitched roofs
		- Stone church with steeple
		- Watchtower
		- Village well
		- Trees
		- Cobblestone ground
		- Perimeter wall

		Uses SDF_QUICK for simplified one-liner setup.
		All Vulkan, windowing, camera controls, and cleanup handled automatically.

		Controls:
			WASD - Move camera
			Space/Ctrl - Up/Down
			Arrow keys - Look around
			P - Pause/Resume
			F12 - Screenshot
			ESC - Exit
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SDF_VILLAGE_DEMO

create
	make

feature -- Initialization

	make
			-- Run the Medieval Village demo using SDF_QUICK.
		local
			sdf: SDF_QUICK
		do
			print ("Medieval Village Demo%N")
			print ("=====================%N%N")

			-- Use SDF_QUICK with the village shader
			create sdf.make_with_shader ("Medieval Village", 1920, 1080, "medieval_village.spv")

			-- Position camera outside village looking in
			sdf.set_camera (0.0, 5.0, 35.0)

			sdf.run
		end

end
