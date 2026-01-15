note
	description: "[
		Simple demo showing SDF_QUICK usage.

		This entire file is ~20 lines vs. the 360-line full demo.
		SDF_QUICK handles all Vulkan, windowing, camera controls, and cleanup.
	]"

class
	SDF_QUICK_DEMO

create
	make

feature

	make
			-- Run demo with one-liner API.
		local
			sdf: SDF_QUICK
		do
			print ("SDF_QUICK Demo%N")
			print ("==============%N%N")

			-- That's it! One line to create, one line to run.
			create sdf.make_village ("Medieval Village", 1920, 1080)
			sdf.run
		end

end
