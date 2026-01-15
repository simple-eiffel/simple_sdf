note
	description: "[
		Entry in an SDF scene: shape with operation and blend radius.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SDF_SCENE_ENTRY

create
	make

feature {NONE} -- Initialization

	make (a_shape: SDF_SHAPE; a_operation: INTEGER; a_blend: REAL_64)
			-- Create entry with shape, operation, and blend radius.
		require
			shape_attached: a_shape /= Void
			valid_operation: a_operation >= 1 and a_operation <= 3
			non_negative_blend: a_blend >= 0.0
		do
			shape := a_shape
			operation := a_operation
			blend := a_blend
		ensure
			shape_set: shape = a_shape
			operation_set: operation = a_operation
			blend_set: blend = a_blend
		end

feature -- Access

	shape: SDF_SHAPE
			-- The SDF shape

	operation: INTEGER
			-- Operation type (1=union, 2=subtraction, 3=intersection)

	blend: REAL_64
			-- Blend radius for smooth operations (0 = sharp)

invariant
	shape_attached: shape /= Void
	valid_operation: operation >= 1 and operation <= 3
	non_negative_blend: blend >= 0.0

end
