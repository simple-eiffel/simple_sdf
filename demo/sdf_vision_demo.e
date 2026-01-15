note
	description: "[
		SDF Vision Demo - GPU ray marching in simple_vision window.

		Unlike MiniFB demos, this uses EV_APPLICATION event loop
		so the window stays alive even when not focused.

		Controls:
			WASD - Move camera
			Space/Shift - Up/Down
			Arrow keys - Look around
			P - Pause/Resume
			ESC - Exit
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SDF_VISION_DEMO

create
	make

feature -- Initialization

	make
			-- Run the Medieval Village demo in simple_vision window.
		local
			renderer: SDF_VISION_RENDERER
		do
			-- Create and run the vision renderer (pure GUI - no console output)
			create renderer.make ("Medieval Village", 1920, 1080, "medieval_village.spv")

			-- Position camera outside village looking in
			renderer.set_camera (0.0, 5.0, 35.0)

			renderer.run
		end

end
