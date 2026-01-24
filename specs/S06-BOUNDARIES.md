# S06 - Boundaries: simple_sdf

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_sdf
**Date:** 2026-01-23

## Scope Boundaries

### In Scope
- Signed distance field primitives (sphere, box, capsule, cylinder, torus, plane)
- Boolean operations (union, subtraction, intersection)
- Smooth blending operations
- Ray marching for rendering
- Vector mathematics (2D, 3D)
- Scene composition

### Out of Scope
- **Mesh generation** - No marching cubes, dual contouring
- **GPU acceleration** - CPU-only distance evaluation
- **Physics simulation** - No collision response, rigid body
- **Texture mapping** - No material/UV support
- **Animation** - No keyframes, interpolation
- **Serialization** - No save/load scene format
- **Spatial acceleration** - No BVH, octree for complex scenes

## API Boundaries

### Public API (SIMPLE_SDF facade)
- All factory methods
- Distance evaluation helpers
- Scene and ray marcher creation

### Internal API (not exported)
- C external implementations
- Shader compilation
- Platform-specific rendering

## Integration Boundaries

### Input Boundaries
| Input Type | Format | Validation |
|------------|--------|------------|
| Coordinates | REAL_64 | Any value accepted |
| Sizes | REAL_64 | Must be > 0.0 |
| Vectors | SDF_VEC3 | Must be non-void |
| Normals | SDF_VEC3 | Must be unit length |
| Smoothing factor | REAL_64 | Should be >= 0.0 |

### Output Boundaries
| Output Type | Range | Meaning |
|-------------|-------|---------|
| Distance | (-inf, +inf) | Negative = inside, positive = outside |
| Ray hit | BOOLEAN | True if surface found |
| Normal | Unit vector | Surface orientation |

## Performance Boundaries

### Expected Performance
| Operation | Time Complexity | Notes |
|-----------|-----------------|-------|
| Single distance eval | O(1) | Per primitive |
| Scene distance | O(n) | n = number of shapes |
| Ray march | O(s * n) | s = steps, n = shapes |

### Resource Limits
| Resource | Practical Limit | Hard Limit |
|----------|-----------------|------------|
| Shapes per scene | ~100 | Memory |
| Ray march steps | ~500 | Stack overflow |
| Nested operations | ~10 | Readability |

## Extension Points

### Adding New Primitives
1. Inherit from SDF_SHAPE
2. Implement `distance` feature
3. Add factory method to SIMPLE_SDF

### Adding New Operations
1. Add to SDF_OPS class
2. Optionally add smooth variant

## Dependency Boundaries

### External Dependencies
- EiffelBase only
- No external C libraries required for core

### Optional Dependencies
- OpenGL (for demo visualization)
- GLSL shaders (for GPU rendering)
