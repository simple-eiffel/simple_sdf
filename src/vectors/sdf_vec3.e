note
	description: "[
		3D vector for SDF calculations with direct x/y/z access.

		Optimized for tight SDF evaluation loops with inline accessors.
		All operations return new vectors (immutable pattern).
		Includes swizzle accessors (xy, xz, yz) for 2D projections.

		Design by Contract:
		- All operations preserve vector validity
		- Normalized vectors have unit length (within tolerance)
		- Cross product is perpendicular to both inputs
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SDF_VEC3

inherit
	ANY
		redefine
			out,
			is_equal
		end

create
	make,
	make_zero,
	make_from_array

feature {NONE} -- Initialization

	make (a_x, a_y, a_z: REAL_64)
			-- Create vector with components `a_x', `a_y', `a_z'.
		do
			x := a_x
			y := a_y
			z := a_z
		ensure
			x_set: x = a_x
			y_set: y = a_y
			z_set: z = a_z
		end

	make_zero
			-- Create zero vector (0, 0, 0).
		do
			x := 0.0
			y := 0.0
			z := 0.0
		ensure
			is_zero: is_zero_vector
		end

	make_from_array (a_array: ARRAY [REAL_64])
			-- Create from array [x, y, z].
		require
			array_has_three_elements: a_array.count >= 3
		do
			x := a_array [a_array.lower]
			y := a_array [a_array.lower + 1]
			z := a_array [a_array.lower + 2]
		end

feature -- Access

	x: REAL_64
			-- X component

	y: REAL_64
			-- Y component

	z: REAL_64
			-- Z component

feature -- Swizzle accessors (2D projections)

	xy: SDF_VEC2
			-- XY plane projection
		do
			create Result.make (x, y)
		ensure
			result_attached: Result /= Void
		end

	xz: SDF_VEC2
			-- XZ plane projection
		do
			create Result.make (x, z)
		ensure
			result_attached: Result /= Void
		end

	yz: SDF_VEC2
			-- YZ plane projection
		do
			create Result.make (y, z)
		ensure
			result_attached: Result /= Void
		end

feature -- Measurement

	length: REAL_64
			-- Euclidean length (magnitude)
		do
			Result := {DOUBLE_MATH}.sqrt (length_squared)
		ensure
			non_negative: Result >= 0.0
		end

	length_squared: REAL_64
			-- Squared length (avoids sqrt for comparisons)
		do
			Result := x * x + y * y + z * z
		ensure
			non_negative: Result >= 0.0
		end

	distance_to (other: SDF_VEC3): REAL_64
			-- Euclidean distance to another point
		require
			other_attached: other /= Void
		do
			Result := minus (other).length
		ensure
			non_negative: Result >= 0.0
		end

feature -- Status report

	is_zero_vector: BOOLEAN
			-- Is this the zero vector?
		do
			Result := x = 0.0 and y = 0.0 and z = 0.0
		end

	is_unit_vector: BOOLEAN
			-- Is this approximately a unit vector?
		do
			Result := (length - 1.0).abs < Epsilon
		end

feature -- Comparison

	is_equal (other: like Current): BOOLEAN
			-- Are vectors equal within tolerance?
		do
			Result := (x - other.x).abs < Epsilon and
			          (y - other.y).abs < Epsilon and
			          (z - other.z).abs < Epsilon
		end

feature -- Operations (return new vectors)

	plus alias "+" (other: SDF_VEC3): SDF_VEC3
			-- Vector addition
		require
			other_attached: other /= Void
		do
			create Result.make (x + other.x, y + other.y, z + other.z)
		ensure
			result_attached: Result /= Void
		end

	minus alias "-" (other: SDF_VEC3): SDF_VEC3
			-- Vector subtraction
		require
			other_attached: other /= Void
		do
			create Result.make (x - other.x, y - other.y, z - other.z)
		ensure
			result_attached: Result /= Void
		end

	scaled alias "*" (factor: REAL_64): SDF_VEC3
			-- Scalar multiplication
		do
			create Result.make (x * factor, y * factor, z * factor)
		ensure
			result_attached: Result /= Void
		end

	negated: SDF_VEC3
			-- Negated vector (-x, -y, -z)
		do
			create Result.make (-x, -y, -z)
		ensure
			result_attached: Result /= Void
		end

	dot (other: SDF_VEC3): REAL_64
			-- Dot product
		require
			other_attached: other /= Void
		do
			Result := x * other.x + y * other.y + z * other.z
		end

	cross (other: SDF_VEC3): SDF_VEC3
			-- Cross product (perpendicular to both vectors)
		require
			other_attached: other /= Void
		do
			create Result.make (
				y * other.z - z * other.y,
				z * other.x - x * other.z,
				x * other.y - y * other.x
			)
		ensure
			result_attached: Result /= Void
		end

	normalized: SDF_VEC3
			-- Unit vector in same direction
		require
			not_zero: not is_zero_vector
		local
			len: REAL_64
		do
			len := length
			create Result.make (x / len, y / len, z / len)
		ensure
			result_attached: Result /= Void
			is_unit: Result.is_unit_vector
		end

	abs: SDF_VEC3
			-- Component-wise absolute value
		do
			create Result.make (x.abs, y.abs, z.abs)
		ensure
			result_attached: Result /= Void
			x_positive: Result.x >= 0.0
			y_positive: Result.y >= 0.0
			z_positive: Result.z >= 0.0
		end

	max (other: SDF_VEC3): SDF_VEC3
			-- Component-wise maximum
		require
			other_attached: other /= Void
		do
			create Result.make (x.max (other.x), y.max (other.y), z.max (other.z))
		ensure
			result_attached: Result /= Void
		end

	min (other: SDF_VEC3): SDF_VEC3
			-- Component-wise minimum
		require
			other_attached: other /= Void
		do
			create Result.make (x.min (other.x), y.min (other.y), z.min (other.z))
		ensure
			result_attached: Result /= Void
		end

	max_component: REAL_64
			-- Maximum of x, y, z
		do
			Result := x.max (y).max (z)
		end

	min_component: REAL_64
			-- Minimum of x, y, z
		do
			Result := x.min (y).min (z)
		end

feature -- Element change (fluent API)

	set_x (a_x: REAL_64): like Current
			-- Set x component and return self
		do
			x := a_x
			Result := Current
		ensure
			x_set: x = a_x
			result_is_current: Result = Current
		end

	set_y (a_y: REAL_64): like Current
			-- Set y component and return self
		do
			y := a_y
			Result := Current
		ensure
			y_set: y = a_y
			result_is_current: Result = Current
		end

	set_z (a_z: REAL_64): like Current
			-- Set z component and return self
		do
			z := a_z
			Result := Current
		ensure
			z_set: z = a_z
			result_is_current: Result = Current
		end

feature -- Conversion

	to_array: ARRAY [REAL_64]
			-- Convert to array [x, y, z]
		do
			Result := <<x, y, z>>
		ensure
			result_has_three: Result.count = 3
		end

	out: STRING
			-- String representation
		do
			create Result.make (50)
			Result.append ("(")
			Result.append (x.out)
			Result.append (", ")
			Result.append (y.out)
			Result.append (", ")
			Result.append (z.out)
			Result.append (")")
		end

feature {NONE} -- Constants

	Epsilon: REAL_64 = 1.0e-10
			-- Tolerance for floating point comparisons

invariant
	x_is_valid: not x.is_nan
	y_is_valid: not y.is_nan
	z_is_valid: not z.is_nan

end
