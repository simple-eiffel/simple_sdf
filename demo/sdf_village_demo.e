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

			-- One-liner API: create and run
			create sdf.make_village ("Medieval Village", 1920, 1080)
			sdf.run
		end

end
