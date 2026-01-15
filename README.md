<p align="center">
  <img src="https://raw.githubusercontent.com/simple-eiffel/claude_eiffel_op_docs/main/artwork/LOGO.png" alt="simple_ library logo" width="400">
</p>

# simple_sdf

**[Documentation](https://simple-eiffel.github.io/simple_sdf/)** | **[GitHub](https://github.com/simple-eiffel/simple_sdf)**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Eiffel](https://img.shields.io/badge/Eiffel-25.02-blue.svg)](https://www.eiffel.org/)
[![Design by Contract](https://img.shields.io/badge/DbC-enforced-orange.svg)]()

Signed Distance Field (SDF) library for geometric primitives, boolean operations, and ray marching.

Part of the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

## Status

**Production** - GPU-accelerated via Vulkan, 63 FPS at 4K resolution

## Overview

SIMPLE_SDF provides a comprehensive toolkit for working with Signed Distance Fields in Eiffel. Create procedural geometry, perform CSG operations, and render with real-time ray marching on CPU or GPU.

## Quick Start

```eiffel
local
    sdf: SIMPLE_SDF
    sphere: SDF_SPHERE
    box: SDF_BOX
    result: SDF_SHAPE
do
    create sdf

    -- Create primitives
    sphere := sdf.sphere (1.0)
    box := sdf.cube (0.8)

    -- Boolean operations
    result := sdf.smooth_union (sphere, box, 0.3)

    -- Query distance at a point
    print (result.distance (sdf.vec3 (0, 0, 0)))
end
```

## Features

- **Geometric Primitives** - Sphere, box, cylinder, torus, plane, and more
- **Boolean Operations** - Union, intersection, difference with smooth blending
- **Transformations** - Translate, rotate, scale any SDF shape
- **Ray Marching** - High-quality rendering with configurable parameters
- **GPU Acceleration** - 63 FPS at 4K via Vulkan compute shaders
- **Multiple Backends** - MiniFB (CPU), Raylib, Vulkan (GPU)

## Installation

1. Set the ecosystem environment variable:
```
SIMPLE_EIFFEL=D:\prod
```

2. Add to ECF:
```xml
<library name="simple_sdf" location="$SIMPLE_EIFFEL/simple_sdf/simple_sdf.ecf"/>
```

## Primitives

```eiffel
sphere := sdf.sphere (1.0)                    -- Sphere
box := sdf.box (2.0, 1.0, 0.5)                -- Box
cube := sdf.cube (1.5)                        -- Cube
cylinder := sdf.cylinder (0.5, 2.0)           -- Cylinder
torus := sdf.torus (1.0, 0.3)                 -- Torus
plane := sdf.plane (sdf.vec3 (0, 1, 0), 0.0)  -- Ground plane
```

## Boolean Operations

```eiffel
-- Sharp operations
combined := sdf.union (a, b)
overlap := sdf.intersection (a, b)
carved := sdf.difference (a, b)

-- Smooth operations (with blend radius)
blended := sdf.smooth_union (a, b, 0.3)
rounded := sdf.smooth_intersection (a, b, 0.2)
filleted := sdf.smooth_difference (a, b, 0.1)
```

## Visualization

Run the demos to see SDF rendering in action:

```batch
# CPU rendering (MiniFB)
ec -batch -config simple_sdf.ecf -target simple_sdf_minifb_demo -finalize -c_compile

# GPU rendering (Vulkan) - 63 FPS at 4K!
ec -batch -config simple_sdf.ecf -target simple_sdf_vulkan_demo -finalize -c_compile
```

### Demo Controls

| Key | Action |
|-----|--------|
| WASD | Move camera |
| Space/Ctrl | Up/Down |
| Arrow Keys | Look around |
| ESC | Exit |

## Performance

Tested on NVIDIA GeForce RTX 5070 Ti:

| Backend | Resolution | FPS |
|---------|------------|-----|
| MiniFB (CPU) | 1920x1080 | 30-40 |
| Vulkan (GPU) | 1920x1080 | 63 |
| Vulkan (GPU) | 3840x2160 | 63 |

## Dependencies

- **simple_vulkan** - For GPU acceleration (optional)
- **simple_minifb** - For CPU visualization (bundled)
- No external Eiffel library dependencies

## License

MIT License
