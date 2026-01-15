note
	description: "[
		Base class for GLSL code generation.
		
		Provides primitives for building GLSL shader source code:
		- Indented code emission
		- Function definition helpers
		- Common GLSL type helpers
		
		Inherit from this class to create specialized GLSL builders.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	GLSL_BUILDER

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize the builder.
		do
			create output.make (2048)
			indent_level := 0
			indent_string := "%T"  -- Tab
		ensure
			output_created: output /= Void
		end

feature -- Access

	output: STRING
			-- Generated GLSL source code.

	to_string: STRING
			-- Return the generated code.
		do
			Result := output.twin
		end

feature -- Code Emission

	emit (a_code: STRING)
			-- Emit code without newline.
		require
			code_not_void: a_code /= Void
		do
			emit_indent
			output.append (a_code)
		end

	emit_line (a_code: STRING)
			-- Emit code with newline.
		require
			code_not_void: a_code /= Void
		do
			emit_indent
			output.append (a_code)
			output.append_character ('%N')
		end

	emit_raw (a_code: STRING)
			-- Emit code without indent or newline.
		require
			code_not_void: a_code /= Void
		do
			output.append (a_code)
		end

	emit_raw_line (a_code: STRING)
			-- Emit code with newline but no indent.
		require
			code_not_void: a_code /= Void
		do
			output.append (a_code)
			output.append_character ('%N')
		end

	newline
			-- Emit empty line.
		do
			output.append_character ('%N')
		end

feature -- Indentation

	indent
			-- Increase indentation level.
		do
			indent_level := indent_level + 1
		end

	dedent
			-- Decrease indentation level.
		require
			has_indentation: is_indented
		do
			indent_level := indent_level - 1
		end

	is_indented: BOOLEAN
			-- Is there current indentation?
		do
			Result := indent_level > 0
		end

feature -- Function Helpers

	emit_function_start (a_name: STRING; a_return_type: STRING; a_params: STRING)
			-- Emit function declaration start.
		require
			name_not_empty: not a_name.is_empty
			return_type_not_empty: not a_return_type.is_empty
		do
			emit_line (a_return_type + " " + a_name + "(" + a_params + ") {")
			indent
		end

	emit_function_end
			-- Emit function end.
		require
			has_indentation: is_indented
		do
			dedent
			emit_line ("}")
		end

	emit_return (a_value: STRING)
			-- Emit return statement.
		require
			value_not_void: a_value /= Void
		do
			emit_line ("return " + a_value + ";")
		end

feature -- Variable Helpers

	emit_local (a_type: STRING; a_name: STRING; a_value: STRING)
			-- Emit local variable declaration with initialization.
		require
			type_not_empty: not a_type.is_empty
			name_not_empty: not a_name.is_empty
			value_not_void: a_value /= Void
		do
			emit_line (a_type + " " + a_name + " = " + a_value + ";")
		end

	emit_assignment (a_name: STRING; a_value: STRING)
			-- Emit assignment statement.
		require
			name_not_empty: not a_name.is_empty
			value_not_void: a_value /= Void
		do
			emit_line (a_name + " = " + a_value + ";")
		end

feature -- GLSL Type Helpers

	vec2 (x, y: REAL_64): STRING
			-- Create vec2 literal.
		do
			Result := "vec2(" + format_float (x) + ", " + format_float (y) + ")"
		end

	vec3 (x, y, z: REAL_64): STRING
			-- Create vec3 literal.
		do
			Result := "vec3(" + format_float (x) + ", " + format_float (y) + ", " + format_float (z) + ")"
		end

	vec4 (x, y, z, w: REAL_64): STRING
			-- Create vec4 literal.
		do
			Result := "vec4(" + format_float (x) + ", " + format_float (y) + ", " + format_float (z) + ", " + format_float (w) + ")"
		end

	format_float (a_value: REAL_64): STRING
			-- Format float for GLSL (always with decimal point).
		local
			l_str: STRING
		do
			l_str := a_value.out
			if not l_str.has ('.') then
				l_str.append (".0")
			end
			Result := l_str
		end

feature -- Comment Helpers

	emit_comment (a_comment: STRING)
			-- Emit single-line comment.
		require
			comment_not_void: a_comment /= Void
		do
			emit_line ("// " + a_comment)
		end

	emit_block_comment (a_comment: STRING)
			-- Emit block comment.
		require
			comment_not_void: a_comment /= Void
		do
			emit_line ("/* " + a_comment + " */")
		end

feature {NONE} -- Implementation

	indent_level: INTEGER
			-- Current indentation level.

	indent_string: STRING
			-- String used for one level of indentation.

	emit_indent
			-- Emit current indentation.
		local
			i: INTEGER
		do
			from i := 1 until i > indent_level loop
				output.append (indent_string)
				i := i + 1
			end
		end

end
