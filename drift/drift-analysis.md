# Drift Analysis: simple_sdf

Generated: 2026-01-24
Method: `ec.exe -flatshort` vs `specs/*.md` + `research/*.md`

## Specification Sources

| Source | Files | Lines |
|--------|-------|-------|
| specs/*.md | 8 | 685 |
| research/*.md | 0 | 0 |

## Classes Analyzed

| Class | Spec'd Features | Actual Features | Drift |
|-------|-----------------|-----------------|-------|
| SIMPLE_SDF | 21 | 41 | +20 |

## Feature-Level Drift

### Specified, Implemented ✓
- `default_create` ✓

### Specified, NOT Implemented ✗
- `add_smooth_union` ✗
- `is_empty` ✗
- `is_unit_vector` ✗
- `is_zero_vector` ✗
- `make_default` ✗
- `make_zero` ✗
- `max_distance` ✗
- `max_steps` ✗
- `op_intersection` ✗
- `op_subtraction` ✗
- ... and 10 more

### Implemented, NOT Specified
- `Io`
- `Operating_environment`
- `Ops`
- `author`
- `box`
- `capsule`
- `capsule_vertical`
- `conforms_to`
- `copy`
- `cube`
- ... and 30 more

## Summary

| Category | Count |
|----------|-------|
| Spec'd, implemented | 1 |
| Spec'd, missing | 20 |
| Implemented, not spec'd | 40 |
| **Overall Drift** | **HIGH** |

## Conclusion

**simple_sdf** has high drift. Significant gaps between spec and implementation.
