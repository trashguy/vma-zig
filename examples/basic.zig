//! Basic VMA Example
//!
//! This example demonstrates basic VMA usage for buffer and image allocation.
//! Note: This requires a valid Vulkan instance, device, etc. to run.

const std = @import("std");
const vk = @import("vulkan");
const vma = @import("vma");

pub fn main() !void {
    std.debug.print("VMA Zig Bindings Example\n", .{});
    std.debug.print("========================\n\n", .{});

    // In a real application, you would:
    // 1. Create a Vulkan instance
    // 2. Select a physical device
    // 3. Create a logical device
    // 4. Then create the VMA allocator

    std.debug.print("To use VMA in your application:\n\n", .{});

    std.debug.print(
        \\1. Create the allocator:
        \\
        \\   var allocator = try vma.Allocator.create(.{{
        \\       .physical_device = physical_device,
        \\       .device = device,
        \\       .instance = instance,
        \\       .vulkan_api_version = vk.API_VERSION_1_3,
        \\   }});
        \\   defer allocator.destroy();
        \\
        \\2. Create a buffer:
        \\
        \\   const result = try allocator.createBuffer(
        \\       .{{
        \\           .size = 1024 * 1024,  // 1 MB
        \\           .usage = .{{ .vertex_buffer_bit = true, .transfer_dst_bit = true }},
        \\           .sharing_mode = .exclusive,
        \\       }},
        \\       .{{ .usage = .auto }},
        \\   );
        \\   defer allocator.destroyBuffer(result.buffer, result.allocation);
        \\
        \\3. Map memory for CPU access:
        \\
        \\   const data = try allocator.mapMemoryTyped(allocation, u8, size);
        \\   defer allocator.unmapMemory(allocation);
        \\   @memcpy(data, src_data);
        \\
    , .{});

    std.debug.print("\nFor more examples, see the README.md\n", .{});
}
