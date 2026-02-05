# vma-zig

Look, I needed VMA to work in Zig 0.15, so I had this wrapper vibe coded, so I could do what I actually
needed to do. Probably will maintain, maybe. Let me know

Zig 0.14+ bindings for [Vulkan Memory Allocator (VMA)](https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator).

This is a community-maintained fork updated for modern Zig (0.14/0.15+), using the new build system APIs.

## Features

- Easy-to-use Zig bindings for VMA 3.x
- Automatic memory type selection
- Memory pooling and sub-allocation
- Works with [vulkan-zig](https://github.com/Snektron/vulkan-zig)
- Compatible with Zig 0.14+

## Installation

Add to your `build.zig.zon`:

```zig
.dependencies = .{
    .@"vma-zig" = .{
        .url = "git+https://github.com/trashguy/zig-vma#COMMIT_HASH",
        .hash = "...",
    },
},
```

Then in your `build.zig`:

```zig
const vma_dep = b.dependency("vma-zig", .{
    .target = target,
    .optimize = optimize,
});

// Add the VMA module to your executable
exe.root_module.addImport("vma", vma_dep.module("vma"));

// Link the VMA library
exe.linkLibrary(vma_dep.artifact("vma"));

// Also link Vulkan
exe.linkSystemLibrary("vulkan");
```

## Usage

### Basic Example

```zig
const std = @import("std");
const vk = @import("vulkan");
const vma = @import("vma");

pub fn main() !void {
    // ... Vulkan initialization ...

    // Create VMA allocator
    var allocator = try vma.Allocator.create(.{
        .physical_device = physical_device,
        .device = device,
        .instance = instance,
        .vulkan_api_version = vk.API_VERSION_1_3,
    });
    defer allocator.destroy();

    // Create a vertex buffer
    const buffer_result = try allocator.createBuffer(
        .{
            .size = 1024 * 1024,  // 1 MB
            .usage = .{ .vertex_buffer_bit = true, .transfer_dst_bit = true },
            .sharing_mode = .exclusive,
        },
        .{ .usage = .auto },
    );
    defer allocator.destroyBuffer(buffer_result.buffer, buffer_result.allocation);

    // Create a texture image
    const image_result = try allocator.createImage(
        .{
            .image_type = .@"2d",
            .format = .r8g8b8a8_srgb,
            .extent = .{ .width = 512, .height = 512, .depth = 1 },
            .mip_levels = 1,
            .array_layers = 1,
            .samples = .@"1_bit",
            .tiling = .optimal,
            .usage = .{ .sampled_bit = true, .transfer_dst_bit = true },
            .sharing_mode = .exclusive,
        },
        .{ .usage = .auto },
    );
    defer allocator.destroyImage(image_result.image, image_result.allocation);
}
```

### Memory Mapping

```zig
// Create a staging buffer with CPU access
const staging = try allocator.createBuffer(
    .{
        .size = data_size,
        .usage = .{ .transfer_src_bit = true },
    },
    .{
        .usage = .auto,
        .flags = .{ .host_access_sequential_write = true, .mapped = true },
    },
);
defer allocator.destroyBuffer(staging.buffer, staging.allocation);

// Map and write data
const mapped = try allocator.mapMemoryTyped(staging.allocation, u8, data_size);
defer allocator.unmapMemory(staging.allocation);
@memcpy(mapped, source_data);

// Flush if needed (for non-coherent memory)
try allocator.flushAllocation(staging.allocation, 0, vk.WHOLE_SIZE);
```

### Memory Usage Hints

VMA provides several memory usage hints:

| Usage | Description |
|-------|-------------|
| `.auto` | Let VMA decide (recommended) |
| `.auto_prefer_device` | Prefer GPU memory, allow CPU fallback |
| `.auto_prefer_host` | Prefer CPU memory |
| `.gpu_only` | Device-local only (fastest for GPU) |
| `.cpu_only` | Host-visible only (for staging) |
| `.cpu_to_gpu` | CPU writes, GPU reads (uniforms) |
| `.gpu_to_cpu` | GPU writes, CPU reads (readback) |

## API Reference

### `vma.Allocator`

Main allocator type.

- `create(info)` - Create allocator
- `destroy()` - Destroy allocator
- `createBuffer(buffer_info, alloc_info)` - Create buffer with memory
- `destroyBuffer(buffer, allocation)` - Destroy buffer and free memory
- `createImage(image_info, alloc_info)` - Create image with memory
- `destroyImage(image, allocation)` - Destroy image and free memory
- `mapMemory(allocation)` - Map memory for CPU access
- `mapMemoryTyped(allocation, T, count)` - Map as typed slice
- `unmapMemory(allocation)` - Unmap memory
- `flushAllocation(allocation, offset, size)` - Flush writes to GPU
- `invalidateAllocation(allocation, offset, size)` - Invalidate for CPU reads

### `vma.AllocationCreateInfo`

```zig
.{
    .flags = .{},              // AllocationCreateFlags
    .usage = .auto,            // MemoryUsage
    .required_flags = .{},     // Required VkMemoryPropertyFlags
    .preferred_flags = .{},    // Preferred VkMemoryPropertyFlags
    .memory_type_bits = 0,     // Allowed memory type bits
    .pool = null,              // Custom pool
    .priority = 0,             // Allocation priority (0-1)
}
```

## Requirements

- Zig 0.14.0 or later
- Vulkan SDK installed
- vulkan-zig (automatically fetched as dependency)

## License

MIT License - see [LICENSE](LICENSE)

## Credits

- [VMA](https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator) by AMD
- [vulkan-zig](https://github.com/Snektron/vulkan-zig) by Snektron
- Original [vma-zig](https://github.com/mikastiv/vma-zig) by mikastiv

## Contributing

Contributions welcome! Please open issues or PRs on GitHub.
