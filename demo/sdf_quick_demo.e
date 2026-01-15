note
	description: "[
		Simple demo showing SDF_QUICK usage.

		SDF_QUICK handles all Vulkan, windowing, camera controls, and cleanup.
		You just provide a shader and run.
	]"

class
	SDF_QUICK_DEMO

create
	make

feature

	make
			-- Run demo with SDF_QUICK.
		local
			sdf: SDF_QUICK
		do
			print ("SDF_QUICK Demo%N")
			print ("==============%N%N")

			-- Create with default shader and run
			create sdf.make_1080p ("SDF Quick Demo")
			sdf.run
		end

end
