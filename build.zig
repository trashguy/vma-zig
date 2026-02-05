const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Vulkan registry path - users must provide this or we try to find it
    const registry = b.option(
        std.Build.LazyPath,
        "registry",
        "Path to the Vulkan registry (vk.xml). Usually at $VULKAN_SDK/share/vulkan/registry/vk.xml",
    ) orelse findVulkanRegistry(b);

    // Get vulkan-zig dependency with registry path
    const vkzig_dep = b.dependency("vulkan-zig", .{
        .registry = registry,
    });

    // Generate the VMA implementation C++ file
    const wf = b.addWriteFiles();
    const vma_cpp = wf.add("vk_mem_alloc.cpp",
        \\#define VMA_IMPLEMENTATION
        \\#define VMA_STATIC_VULKAN_FUNCTIONS 0
        \\#define VMA_DYNAMIC_VULKAN_FUNCTIONS 1
        \\#include "vk_mem_alloc.h"
    );

    // Create a module for the VMA C++ library
    const vma_lib_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    // Add VMA C++ source
    vma_lib_module.addCSourceFile(.{ .file = vma_cpp });
    vma_lib_module.addIncludePath(b.path("."));
    vma_lib_module.linkSystemLibrary("stdc++", .{});

    // Link Vulkan
    if (target.result.os.tag == .windows) {
        vma_lib_module.linkSystemLibrary("vulkan-1", .{});
    } else {
        vma_lib_module.linkSystemLibrary("vulkan", .{});
    }

    // Create VMA C++ static library
    const vma_lib = b.addLibrary(.{
        .linkage = .static,
        .name = "vma",
        .root_module = vma_lib_module,
    });

    b.installArtifact(vma_lib);

    // Create Zig module for VMA bindings
    const vma_module = b.addModule("vma", .{
        .root_source_file = b.path("src/vma.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "vulkan", .module = vkzig_dep.module("vulkan-zig") },
        },
    });

    // Link the VMA library to the module
    vma_module.linkLibrary(vma_lib);

    // Tests
    const test_module = b.createModule(.{
        .root_source_file = b.path("src/vma.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "vulkan", .module = vkzig_dep.module("vulkan-zig") },
        },
    });

    const tests = b.addTest(.{
        .root_module = test_module,
    });

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);
}

/// Try to find the Vulkan registry (vk.xml) in standard locations
fn findVulkanRegistry(b: *std.Build) std.Build.LazyPath {
    // Try VULKAN_SDK environment variable first
    if (b.graph.env_map.get("VULKAN_SDK")) |sdk_path| {
        const registry_path = std.fs.path.join(b.allocator, &.{ sdk_path, "share", "vulkan", "registry", "vk.xml" }) catch @panic("OOM");
        if (std.fs.cwd().access(registry_path, .{})) |_| {
            return .{ .cwd_relative = registry_path };
        } else |_| {}
    }

    // Try common Linux paths
    const common_paths = [_][]const u8{
        "/usr/share/vulkan/registry/vk.xml",
        "/usr/local/share/vulkan/registry/vk.xml",
    };

    for (common_paths) |path| {
        if (std.fs.cwd().access(path, .{})) |_| {
            return .{ .cwd_relative = path };
        } else |_| {}
    }

    @panic(
        \\Could not find Vulkan registry (vk.xml).
        \\Please provide the path using -Dregistry=<path>
        \\
        \\Common locations:
        \\  Linux: /usr/share/vulkan/registry/vk.xml
        \\  Vulkan SDK: $VULKAN_SDK/share/vulkan/registry/vk.xml
        \\
        \\Install vulkan-headers or Vulkan SDK to get vk.xml
    );
}
