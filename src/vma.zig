//! Vulkan Memory Allocator (VMA) Zig Bindings
//!
//! Easy-to-use Zig bindings for AMD's Vulkan Memory Allocator library.
//! Compatible with Zig 0.14+ and vulkan-zig.
//!
//! VMA simplifies GPU memory management by providing:
//! - Automatic memory type selection
//! - Memory pooling and sub-allocation
//! - Defragmentation support
//! - Statistics and debugging aids
//!
//! ## Basic Usage
//! ```zig
//! const vma = @import("vma");
//!
//! // Create allocator
//! var allocator = try vma.Allocator.create(.{
//!     .vulkan_api_version = vk.API_VERSION_1_3,
//!     .physical_device = physical_device,
//!     .device = device,
//!     .instance = instance,
//! });
//! defer allocator.destroy();
//!
//! // Create a buffer with automatic memory allocation
//! const result = try allocator.createBuffer(
//!     .{ .size = 1024, .usage = .{ .vertex_buffer_bit = true } },
//!     .{ .usage = .auto },
//! );
//! defer allocator.destroyBuffer(result.buffer, result.allocation);
//! ```

const std = @import("std");
const vk = @import("vulkan");

// ============================================================================
// C Bindings (extern declarations for VMA functions)
// ============================================================================

const VmaAllocator = *opaque {};
const VmaAllocation = *opaque {};
const VmaPool = *opaque {};
const VmaDefragmentationContext = *opaque {};
const VmaVirtualBlock = *opaque {};
const VmaVirtualAllocation = u64;

extern fn vmaCreateAllocator(pCreateInfo: *const VmaAllocatorCreateInfo, pAllocator: *VmaAllocator) vk.Result;
extern fn vmaDestroyAllocator(allocator: VmaAllocator) void;
extern fn vmaGetAllocatorInfo(allocator: VmaAllocator, pAllocatorInfo: *VmaAllocatorInfo) void;
extern fn vmaGetPhysicalDeviceProperties(allocator: VmaAllocator, ppPhysicalDeviceProperties: **const vk.PhysicalDeviceProperties) void;
extern fn vmaGetMemoryProperties(allocator: VmaAllocator, ppPhysicalDeviceMemoryProperties: **const vk.PhysicalDeviceMemoryProperties) void;
extern fn vmaGetMemoryTypeProperties(allocator: VmaAllocator, memoryTypeIndex: u32, pFlags: *vk.MemoryPropertyFlags) void;
extern fn vmaSetCurrentFrameIndex(allocator: VmaAllocator, frameIndex: u32) void;
extern fn vmaCalculateStatistics(allocator: VmaAllocator, pStats: *VmaTotalStatistics) void;
extern fn vmaGetHeapBudgets(allocator: VmaAllocator, pBudgets: [*]VmaBudget) void;

extern fn vmaFindMemoryTypeIndex(allocator: VmaAllocator, memoryTypeBits: u32, pAllocationCreateInfo: *const VmaAllocationCreateInfo, pMemoryTypeIndex: *u32) vk.Result;
extern fn vmaFindMemoryTypeIndexForBufferInfo(allocator: VmaAllocator, pBufferCreateInfo: *const vk.BufferCreateInfo, pAllocationCreateInfo: *const VmaAllocationCreateInfo, pMemoryTypeIndex: *u32) vk.Result;
extern fn vmaFindMemoryTypeIndexForImageInfo(allocator: VmaAllocator, pImageCreateInfo: *const vk.ImageCreateInfo, pAllocationCreateInfo: *const VmaAllocationCreateInfo, pMemoryTypeIndex: *u32) vk.Result;

extern fn vmaCreatePool(allocator: VmaAllocator, pCreateInfo: *const VmaPoolCreateInfo, pPool: *VmaPool) vk.Result;
extern fn vmaDestroyPool(allocator: VmaAllocator, pool: VmaPool) void;
extern fn vmaGetPoolStatistics(allocator: VmaAllocator, pool: VmaPool, pPoolStats: *VmaStatistics) void;
extern fn vmaCalculatePoolStatistics(allocator: VmaAllocator, pool: VmaPool, pPoolStats: *VmaDetailedStatistics) void;
extern fn vmaCheckPoolCorruption(allocator: VmaAllocator, pool: VmaPool) vk.Result;
extern fn vmaGetPoolName(allocator: VmaAllocator, pool: VmaPool, ppName: *?[*:0]const u8) void;
extern fn vmaSetPoolName(allocator: VmaAllocator, pool: VmaPool, pName: ?[*:0]const u8) void;

extern fn vmaAllocateMemory(allocator: VmaAllocator, pVkMemoryRequirements: *const vk.MemoryRequirements, pCreateInfo: *const VmaAllocationCreateInfo, pAllocation: *VmaAllocation, pAllocationInfo: ?*VmaAllocationInfo) vk.Result;
extern fn vmaAllocateMemoryPages(allocator: VmaAllocator, pVkMemoryRequirements: [*]const vk.MemoryRequirements, pCreateInfo: [*]const VmaAllocationCreateInfo, allocationCount: usize, pAllocations: [*]VmaAllocation, pAllocationInfo: ?[*]VmaAllocationInfo) vk.Result;
extern fn vmaAllocateMemoryForBuffer(allocator: VmaAllocator, buffer: vk.Buffer, pCreateInfo: *const VmaAllocationCreateInfo, pAllocation: *VmaAllocation, pAllocationInfo: ?*VmaAllocationInfo) vk.Result;
extern fn vmaAllocateMemoryForImage(allocator: VmaAllocator, image: vk.Image, pCreateInfo: *const VmaAllocationCreateInfo, pAllocation: *VmaAllocation, pAllocationInfo: ?*VmaAllocationInfo) vk.Result;
extern fn vmaFreeMemory(allocator: VmaAllocator, allocation: VmaAllocation) void;
extern fn vmaFreeMemoryPages(allocator: VmaAllocator, allocationCount: usize, pAllocations: [*]const VmaAllocation) void;

extern fn vmaGetAllocationInfo(allocator: VmaAllocator, allocation: VmaAllocation, pAllocationInfo: *VmaAllocationInfo) void;
extern fn vmaSetAllocationUserData(allocator: VmaAllocator, allocation: VmaAllocation, pUserData: ?*anyopaque) void;
extern fn vmaSetAllocationName(allocator: VmaAllocator, allocation: VmaAllocation, pName: ?[*:0]const u8) void;
extern fn vmaGetAllocationMemoryProperties(allocator: VmaAllocator, allocation: VmaAllocation, pFlags: *vk.MemoryPropertyFlags) void;

extern fn vmaMapMemory(allocator: VmaAllocator, allocation: VmaAllocation, ppData: *?*anyopaque) vk.Result;
extern fn vmaUnmapMemory(allocator: VmaAllocator, allocation: VmaAllocation) void;
extern fn vmaFlushAllocation(allocator: VmaAllocator, allocation: VmaAllocation, offset: vk.DeviceSize, size: vk.DeviceSize) vk.Result;
extern fn vmaInvalidateAllocation(allocator: VmaAllocator, allocation: VmaAllocation, offset: vk.DeviceSize, size: vk.DeviceSize) vk.Result;
extern fn vmaFlushAllocations(allocator: VmaAllocator, allocationCount: u32, allocations: [*]const VmaAllocation, offsets: ?[*]const vk.DeviceSize, sizes: ?[*]const vk.DeviceSize) vk.Result;
extern fn vmaInvalidateAllocations(allocator: VmaAllocator, allocationCount: u32, allocations: [*]const VmaAllocation, offsets: ?[*]const vk.DeviceSize, sizes: ?[*]const vk.DeviceSize) vk.Result;
extern fn vmaCopyMemoryToAllocation(allocator: VmaAllocator, pSrcHostPointer: *const anyopaque, dstAllocation: VmaAllocation, dstAllocationLocalOffset: vk.DeviceSize, size: vk.DeviceSize) vk.Result;
extern fn vmaCopyAllocationToMemory(allocator: VmaAllocator, srcAllocation: VmaAllocation, srcAllocationLocalOffset: vk.DeviceSize, pDstHostPointer: *anyopaque, size: vk.DeviceSize) vk.Result;

extern fn vmaCheckCorruption(allocator: VmaAllocator, memoryTypeBits: u32) vk.Result;

extern fn vmaBeginDefragmentation(allocator: VmaAllocator, pInfo: *const VmaDefragmentationInfo, pContext: *VmaDefragmentationContext) vk.Result;
extern fn vmaEndDefragmentation(allocator: VmaAllocator, context: VmaDefragmentationContext, pStats: ?*VmaDefragmentationStats) void;
extern fn vmaBeginDefragmentationPass(allocator: VmaAllocator, context: VmaDefragmentationContext, pPassInfo: *VmaDefragmentationPassMoveInfo) vk.Result;
extern fn vmaEndDefragmentationPass(allocator: VmaAllocator, context: VmaDefragmentationContext, pPassInfo: *VmaDefragmentationPassMoveInfo) vk.Result;

extern fn vmaBindBufferMemory(allocator: VmaAllocator, allocation: VmaAllocation, buffer: vk.Buffer) vk.Result;
extern fn vmaBindBufferMemory2(allocator: VmaAllocator, allocation: VmaAllocation, allocationLocalOffset: vk.DeviceSize, buffer: vk.Buffer, pNext: ?*const anyopaque) vk.Result;
extern fn vmaBindImageMemory(allocator: VmaAllocator, allocation: VmaAllocation, image: vk.Image) vk.Result;
extern fn vmaBindImageMemory2(allocator: VmaAllocator, allocation: VmaAllocation, allocationLocalOffset: vk.DeviceSize, image: vk.Image, pNext: ?*const anyopaque) vk.Result;

extern fn vmaCreateBuffer(allocator: VmaAllocator, pBufferCreateInfo: *const vk.BufferCreateInfo, pAllocationCreateInfo: *const VmaAllocationCreateInfo, pBuffer: *vk.Buffer, pAllocation: *VmaAllocation, pAllocationInfo: ?*VmaAllocationInfo) vk.Result;
extern fn vmaCreateBufferWithAlignment(allocator: VmaAllocator, pBufferCreateInfo: *const vk.BufferCreateInfo, pAllocationCreateInfo: *const VmaAllocationCreateInfo, minAlignment: vk.DeviceSize, pBuffer: *vk.Buffer, pAllocation: *VmaAllocation, pAllocationInfo: ?*VmaAllocationInfo) vk.Result;
extern fn vmaCreateAliasingBuffer(allocator: VmaAllocator, allocation: VmaAllocation, pBufferCreateInfo: *const vk.BufferCreateInfo, pBuffer: *vk.Buffer) vk.Result;
extern fn vmaCreateAliasingBuffer2(allocator: VmaAllocator, allocation: VmaAllocation, allocationLocalOffset: vk.DeviceSize, pBufferCreateInfo: *const vk.BufferCreateInfo, pBuffer: *vk.Buffer) vk.Result;
extern fn vmaDestroyBuffer(allocator: VmaAllocator, buffer: vk.Buffer, allocation: VmaAllocation) void;

extern fn vmaCreateImage(allocator: VmaAllocator, pImageCreateInfo: *const vk.ImageCreateInfo, pAllocationCreateInfo: *const VmaAllocationCreateInfo, pImage: *vk.Image, pAllocation: *VmaAllocation, pAllocationInfo: ?*VmaAllocationInfo) vk.Result;
extern fn vmaCreateAliasingImage(allocator: VmaAllocator, allocation: VmaAllocation, pImageCreateInfo: *const vk.ImageCreateInfo, pImage: *vk.Image) vk.Result;
extern fn vmaCreateAliasingImage2(allocator: VmaAllocator, allocation: VmaAllocation, allocationLocalOffset: vk.DeviceSize, pImageCreateInfo: *const vk.ImageCreateInfo, pImage: *vk.Image) vk.Result;
extern fn vmaDestroyImage(allocator: VmaAllocator, image: vk.Image, allocation: VmaAllocation) void;

extern fn vmaCreateVirtualBlock(pCreateInfo: *const VmaVirtualBlockCreateInfo, pVirtualBlock: *VmaVirtualBlock) vk.Result;
extern fn vmaDestroyVirtualBlock(virtualBlock: VmaVirtualBlock) void;
extern fn vmaIsVirtualBlockEmpty(virtualBlock: VmaVirtualBlock) vk.Bool32;
extern fn vmaGetVirtualAllocationInfo(virtualBlock: VmaVirtualBlock, allocation: VmaVirtualAllocation, pVirtualAllocInfo: *VmaVirtualAllocationInfo) void;
extern fn vmaVirtualAllocate(virtualBlock: VmaVirtualBlock, pCreateInfo: *const VmaVirtualAllocationCreateInfo, pAllocation: *VmaVirtualAllocation, pOffset: ?*vk.DeviceSize) vk.Result;
extern fn vmaVirtualFree(virtualBlock: VmaVirtualBlock, allocation: VmaVirtualAllocation) void;
extern fn vmaClearVirtualBlock(virtualBlock: VmaVirtualBlock) void;
extern fn vmaSetVirtualAllocationUserData(virtualBlock: VmaVirtualBlock, allocation: VmaVirtualAllocation, pUserData: ?*anyopaque) void;
extern fn vmaGetVirtualBlockStatistics(virtualBlock: VmaVirtualBlock, pStats: *VmaStatistics) void;
extern fn vmaCalculateVirtualBlockStatistics(virtualBlock: VmaVirtualBlock, pStats: *VmaDetailedStatistics) void;

// ============================================================================
// C Struct Definitions
// ============================================================================

const VmaAllocatorCreateInfo = extern struct {
    flags: AllocatorCreateFlags = .{},
    physicalDevice: vk.PhysicalDevice,
    device: vk.Device,
    preferredLargeHeapBlockSize: vk.DeviceSize = 0,
    pAllocationCallbacks: ?*const vk.AllocationCallbacks = null,
    pDeviceMemoryCallbacks: ?*const VmaDeviceMemoryCallbacks = null,
    pHeapSizeLimit: ?[*]const vk.DeviceSize = null,
    pVulkanFunctions: ?*const VmaVulkanFunctions = null,
    instance: vk.Instance,
    vulkanApiVersion: u32 = vk.API_VERSION_1_0,
    pTypeExternalMemoryHandleTypes: ?[*]const vk.ExternalMemoryHandleTypeFlagsKHR = null,
};

const VmaVulkanFunctions = extern struct {
    vkGetInstanceProcAddr: vk.PfnGetInstanceProcAddr = null,
    vkGetDeviceProcAddr: vk.PfnGetDeviceProcAddr = null,
    vkGetPhysicalDeviceProperties: vk.PfnGetPhysicalDeviceProperties = null,
    vkGetPhysicalDeviceMemoryProperties: vk.PfnGetPhysicalDeviceMemoryProperties = null,
    vkAllocateMemory: vk.PfnAllocateMemory = null,
    vkFreeMemory: vk.PfnFreeMemory = null,
    vkMapMemory: vk.PfnMapMemory = null,
    vkUnmapMemory: vk.PfnUnmapMemory = null,
    vkFlushMappedMemoryRanges: vk.PfnFlushMappedMemoryRanges = null,
    vkInvalidateMappedMemoryRanges: vk.PfnInvalidateMappedMemoryRanges = null,
    vkBindBufferMemory: vk.PfnBindBufferMemory = null,
    vkBindImageMemory: vk.PfnBindImageMemory = null,
    vkGetBufferMemoryRequirements: vk.PfnGetBufferMemoryRequirements = null,
    vkGetImageMemoryRequirements: vk.PfnGetImageMemoryRequirements = null,
    vkCreateBuffer: vk.PfnCreateBuffer = null,
    vkDestroyBuffer: vk.PfnDestroyBuffer = null,
    vkCreateImage: vk.PfnCreateImage = null,
    vkDestroyImage: vk.PfnDestroyImage = null,
    vkCmdCopyBuffer: vk.PfnCmdCopyBuffer = null,
    vkGetBufferMemoryRequirements2KHR: vk.PfnGetBufferMemoryRequirements2KHR = null,
    vkGetImageMemoryRequirements2KHR: vk.PfnGetImageMemoryRequirements2KHR = null,
    vkBindBufferMemory2KHR: vk.PfnBindBufferMemory2KHR = null,
    vkBindImageMemory2KHR: vk.PfnBindImageMemory2KHR = null,
    vkGetPhysicalDeviceMemoryProperties2KHR: vk.PfnGetPhysicalDeviceMemoryProperties2KHR = null,
    vkGetDeviceBufferMemoryRequirements: vk.PfnGetDeviceBufferMemoryRequirements = null,
    vkGetDeviceImageMemoryRequirements: vk.PfnGetDeviceImageMemoryRequirements = null,
};

const VmaDeviceMemoryCallbacks = extern struct {
    pfnAllocate: ?*const fn (VmaAllocator, u32, vk.DeviceMemory, vk.DeviceSize, ?*anyopaque) callconv(.C) void = null,
    pfnFree: ?*const fn (VmaAllocator, u32, vk.DeviceMemory, vk.DeviceSize, ?*anyopaque) callconv(.C) void = null,
    pUserData: ?*anyopaque = null,
};

const VmaAllocatorInfo = extern struct {
    instance: vk.Instance,
    physicalDevice: vk.PhysicalDevice,
    device: vk.Device,
};

const VmaAllocationCreateInfo = extern struct {
    flags: AllocationCreateFlags = .{},
    usage: MemoryUsage = .unknown,
    requiredFlags: vk.MemoryPropertyFlags = .{},
    preferredFlags: vk.MemoryPropertyFlags = .{},
    memoryTypeBits: u32 = 0,
    pool: ?VmaPool = null,
    pUserData: ?*anyopaque = null,
    priority: f32 = 0,
};

const VmaAllocationInfo = extern struct {
    memoryType: u32,
    deviceMemory: vk.DeviceMemory,
    offset: vk.DeviceSize,
    size: vk.DeviceSize,
    pMappedData: ?*anyopaque,
    pUserData: ?*anyopaque,
    pName: ?[*:0]const u8,
};

const VmaPoolCreateInfo = extern struct {
    memoryTypeIndex: u32,
    flags: PoolCreateFlags = .{},
    blockSize: vk.DeviceSize = 0,
    minBlockCount: usize = 0,
    maxBlockCount: usize = 0,
    priority: f32 = 0,
    minAllocationAlignment: vk.DeviceSize = 0,
    pMemoryAllocateNext: ?*anyopaque = null,
};

const VmaStatistics = extern struct {
    blockCount: u32,
    allocationCount: u32,
    blockBytes: vk.DeviceSize,
    allocationBytes: vk.DeviceSize,
};

const VmaDetailedStatistics = extern struct {
    statistics: VmaStatistics,
    unusedRangeCount: u32,
    allocationSizeMin: vk.DeviceSize,
    allocationSizeMax: vk.DeviceSize,
    unusedRangeSizeMin: vk.DeviceSize,
    unusedRangeSizeMax: vk.DeviceSize,
};

const VmaTotalStatistics = extern struct {
    memoryType: [32]VmaDetailedStatistics,
    memoryHeap: [16]VmaDetailedStatistics,
    total: VmaDetailedStatistics,
};

const VmaBudget = extern struct {
    statistics: VmaStatistics,
    usage: vk.DeviceSize,
    budget: vk.DeviceSize,
};

const VmaDefragmentationInfo = extern struct {
    flags: DefragmentationFlags = .{},
    pool: ?VmaPool = null,
    maxBytesPerPass: vk.DeviceSize = 0,
    maxAllocationsPerPass: u32 = 0,
    pfnBreakCallback: ?*const fn (?*anyopaque) callconv(.C) vk.Bool32 = null,
    pBreakCallbackUserData: ?*anyopaque = null,
};

const VmaDefragmentationMove = extern struct {
    operation: DefragmentationMoveOperation,
    srcAllocation: VmaAllocation,
    dstTmpAllocation: VmaAllocation,
};

const VmaDefragmentationPassMoveInfo = extern struct {
    moveCount: u32,
    pMoves: [*]VmaDefragmentationMove,
};

const VmaDefragmentationStats = extern struct {
    bytesMoved: vk.DeviceSize,
    bytesFreed: vk.DeviceSize,
    allocationsMoved: u32,
    deviceMemoryBlocksFreed: u32,
};

const VmaVirtualBlockCreateInfo = extern struct {
    size: vk.DeviceSize,
    flags: VirtualBlockCreateFlags = .{},
    pAllocationCallbacks: ?*const vk.AllocationCallbacks = null,
};

const VmaVirtualAllocationCreateInfo = extern struct {
    size: vk.DeviceSize,
    alignment: vk.DeviceSize = 0,
    flags: VirtualAllocationCreateFlags = .{},
    pUserData: ?*anyopaque = null,
};

const VmaVirtualAllocationInfo = extern struct {
    offset: vk.DeviceSize,
    size: vk.DeviceSize,
    pUserData: ?*anyopaque,
};

// ============================================================================
// Public Flag Types
// ============================================================================

pub const AllocatorCreateFlags = packed struct(u32) {
    externally_synchronized: bool = false,
    khr_dedicated_allocation: bool = false,
    khr_bind_memory2: bool = false,
    ext_memory_budget: bool = false,
    amd_device_coherent_memory: bool = false,
    buffer_device_address: bool = false,
    ext_memory_priority: bool = false,
    _padding: u25 = 0,
};

pub const AllocationCreateFlags = packed struct(u32) {
    dedicated_memory: bool = false,
    never_allocate: bool = false,
    mapped: bool = false,
    user_data_copy_string: bool = false,
    upper_address: bool = false,
    dont_bind: bool = false,
    within_budget: bool = false,
    can_alias: bool = false,
    host_access_sequential_write: bool = false,
    host_access_random: bool = false,
    host_access_allow_transfer_instead: bool = false,
    strategy_min_memory: bool = false,
    strategy_min_time: bool = false,
    strategy_min_offset: bool = false,
    _padding: u18 = 0,
};

pub const PoolCreateFlags = packed struct(u32) {
    ignore_buffer_image_granularity: bool = false,
    linear_algorithm: bool = false,
    _padding: u30 = 0,
};

pub const DefragmentationFlags = packed struct(u32) {
    algorithm_fast: bool = false,
    algorithm_balanced: bool = false,
    algorithm_full: bool = false,
    algorithm_extensive: bool = false,
    _padding: u28 = 0,
};

pub const VirtualBlockCreateFlags = packed struct(u32) {
    linear_algorithm: bool = false,
    _padding: u31 = 0,
};

pub const VirtualAllocationCreateFlags = packed struct(u32) {
    upper_address: bool = false,
    strategy_min_memory: bool = false,
    strategy_min_time: bool = false,
    strategy_min_offset: bool = false,
    _padding: u28 = 0,
};

pub const MemoryUsage = enum(u32) {
    unknown = 0,
    gpu_only = 1,
    cpu_only = 2,
    cpu_to_gpu = 3,
    gpu_to_cpu = 4,
    cpu_copy = 5,
    gpu_lazily_allocated = 6,
    auto = 7,
    auto_prefer_device = 8,
    auto_prefer_host = 9,
};

pub const DefragmentationMoveOperation = enum(u32) {
    copy = 0,
    ignore = 1,
    destroy = 2,
};

// ============================================================================
// Error Type
// ============================================================================

pub const Error = error{
    OutOfHostMemory,
    OutOfDeviceMemory,
    InitializationFailed,
    DeviceLost,
    MemoryMapFailed,
    LayerNotPresent,
    ExtensionNotPresent,
    FeatureNotPresent,
    IncompatibleDriver,
    TooManyObjects,
    FormatNotSupported,
    FragmentedPool,
    Unknown,
    OutOfPoolMemory,
    InvalidExternalHandle,
    Fragmentation,
    InvalidOpaqueCaptureAddress,
};

fn checkResult(result: vk.Result) Error!void {
    return switch (result) {
        .success => {},
        .error_out_of_host_memory => error.OutOfHostMemory,
        .error_out_of_device_memory => error.OutOfDeviceMemory,
        .error_initialization_failed => error.InitializationFailed,
        .error_device_lost => error.DeviceLost,
        .error_memory_map_failed => error.MemoryMapFailed,
        .error_layer_not_present => error.LayerNotPresent,
        .error_extension_not_present => error.ExtensionNotPresent,
        .error_feature_not_present => error.FeatureNotPresent,
        .error_incompatible_driver => error.IncompatibleDriver,
        .error_too_many_objects => error.TooManyObjects,
        .error_format_not_supported => error.FormatNotSupported,
        .error_fragmented_pool => error.FragmentedPool,
        .error_unknown => error.Unknown,
        .error_out_of_pool_memory => error.OutOfPoolMemory,
        .error_invalid_external_handle => error.InvalidExternalHandle,
        .error_fragmentation => error.Fragmentation,
        .error_invalid_opaque_capture_address => error.InvalidOpaqueCaptureAddress,
        else => error.Unknown,
    };
}

// ============================================================================
// Main Allocator Type
// ============================================================================

/// VMA Allocator - manages GPU memory allocation
pub const Allocator = struct {
    handle: VmaAllocator,

    const Self = @This();

    /// Configuration for creating a VMA allocator
    pub const CreateInfo = struct {
        flags: AllocatorCreateFlags = .{},
        physical_device: vk.PhysicalDevice,
        device: vk.Device,
        instance: vk.Instance,
        vulkan_api_version: u32 = vk.API_VERSION_1_0,
        preferred_large_heap_block_size: vk.DeviceSize = 0,
        allocation_callbacks: ?*const vk.AllocationCallbacks = null,
    };

    /// Create a new VMA allocator
    pub fn create(info: CreateInfo) Error!Self {
        var handle: VmaAllocator = undefined;
        const create_info = VmaAllocatorCreateInfo{
            .flags = info.flags,
            .physicalDevice = info.physical_device,
            .device = info.device,
            .instance = info.instance,
            .vulkanApiVersion = info.vulkan_api_version,
            .preferredLargeHeapBlockSize = info.preferred_large_heap_block_size,
            .pAllocationCallbacks = info.allocation_callbacks,
        };
        try checkResult(vmaCreateAllocator(&create_info, &handle));
        return .{ .handle = handle };
    }

    /// Destroy the allocator
    pub fn destroy(self: Self) void {
        vmaDestroyAllocator(self.handle);
    }

    /// Get allocator info
    pub fn getInfo(self: Self) VmaAllocatorInfo {
        var info: VmaAllocatorInfo = undefined;
        vmaGetAllocatorInfo(self.handle, &info);
        return info;
    }

    /// Set current frame index for frame-based resource management
    pub fn setCurrentFrameIndex(self: Self, frame_index: u32) void {
        vmaSetCurrentFrameIndex(self.handle, frame_index);
    }

    /// Calculate detailed statistics
    pub fn calculateStatistics(self: Self) VmaTotalStatistics {
        var stats: VmaTotalStatistics = undefined;
        vmaCalculateStatistics(self.handle, &stats);
        return stats;
    }

    // ========================================================================
    // Buffer Operations
    // ========================================================================

    pub const BufferCreateResult = struct {
        buffer: vk.Buffer,
        allocation: Allocation,
        allocation_info: ?AllocationInfo = null,
    };

    /// Create a buffer with automatic memory allocation
    pub fn createBuffer(
        self: Self,
        buffer_info: vk.BufferCreateInfo,
        alloc_info: AllocationCreateInfo,
    ) Error!BufferCreateResult {
        var buffer: vk.Buffer = undefined;
        var allocation: VmaAllocation = undefined;
        var info: VmaAllocationInfo = undefined;

        const vma_alloc_info = VmaAllocationCreateInfo{
            .flags = alloc_info.flags,
            .usage = alloc_info.usage,
            .requiredFlags = alloc_info.required_flags,
            .preferredFlags = alloc_info.preferred_flags,
            .memoryTypeBits = alloc_info.memory_type_bits,
            .pool = if (alloc_info.pool) |p| p.handle else null,
            .pUserData = alloc_info.user_data,
            .priority = alloc_info.priority,
        };

        try checkResult(vmaCreateBuffer(
            self.handle,
            &buffer_info,
            &vma_alloc_info,
            &buffer,
            &allocation,
            &info,
        ));

        return .{
            .buffer = buffer,
            .allocation = .{ .handle = allocation },
            .allocation_info = AllocationInfo.fromC(info),
        };
    }

    /// Destroy a buffer and free its memory
    pub fn destroyBuffer(self: Self, buffer: vk.Buffer, allocation: Allocation) void {
        vmaDestroyBuffer(self.handle, buffer, allocation.handle);
    }

    // ========================================================================
    // Image Operations
    // ========================================================================

    pub const ImageCreateResult = struct {
        image: vk.Image,
        allocation: Allocation,
        allocation_info: ?AllocationInfo = null,
    };

    /// Create an image with automatic memory allocation
    pub fn createImage(
        self: Self,
        image_info: vk.ImageCreateInfo,
        alloc_info: AllocationCreateInfo,
    ) Error!ImageCreateResult {
        var image: vk.Image = undefined;
        var allocation: VmaAllocation = undefined;
        var info: VmaAllocationInfo = undefined;

        const vma_alloc_info = VmaAllocationCreateInfo{
            .flags = alloc_info.flags,
            .usage = alloc_info.usage,
            .requiredFlags = alloc_info.required_flags,
            .preferredFlags = alloc_info.preferred_flags,
            .memoryTypeBits = alloc_info.memory_type_bits,
            .pool = if (alloc_info.pool) |p| p.handle else null,
            .pUserData = alloc_info.user_data,
            .priority = alloc_info.priority,
        };

        try checkResult(vmaCreateImage(
            self.handle,
            &image_info,
            &vma_alloc_info,
            &image,
            &allocation,
            &info,
        ));

        return .{
            .image = image,
            .allocation = .{ .handle = allocation },
            .allocation_info = AllocationInfo.fromC(info),
        };
    }

    /// Destroy an image and free its memory
    pub fn destroyImage(self: Self, image: vk.Image, allocation: Allocation) void {
        vmaDestroyImage(self.handle, image, allocation.handle);
    }

    // ========================================================================
    // Memory Mapping
    // ========================================================================

    /// Map memory for CPU access
    pub fn mapMemory(self: Self, allocation: Allocation) Error!*anyopaque {
        var data: ?*anyopaque = null;
        try checkResult(vmaMapMemory(self.handle, allocation.handle, &data));
        return data orelse return error.MemoryMapFailed;
    }

    /// Map memory as a typed slice
    pub fn mapMemoryTyped(self: Self, allocation: Allocation, comptime T: type, count: usize) Error![]T {
        const ptr = try self.mapMemory(allocation);
        const typed_ptr: [*]T = @ptrCast(@alignCast(ptr));
        return typed_ptr[0..count];
    }

    /// Unmap previously mapped memory
    pub fn unmapMemory(self: Self, allocation: Allocation) void {
        vmaUnmapMemory(self.handle, allocation.handle);
    }

    /// Flush mapped memory to make CPU writes visible to GPU
    pub fn flushAllocation(self: Self, allocation: Allocation, offset: vk.DeviceSize, size: vk.DeviceSize) Error!void {
        try checkResult(vmaFlushAllocation(self.handle, allocation.handle, offset, size));
    }

    /// Invalidate mapped memory to make GPU writes visible to CPU
    pub fn invalidateAllocation(self: Self, allocation: Allocation, offset: vk.DeviceSize, size: vk.DeviceSize) Error!void {
        try checkResult(vmaInvalidateAllocation(self.handle, allocation.handle, offset, size));
    }

    // ========================================================================
    // Raw Memory Allocation
    // ========================================================================

    /// Allocate memory directly (without creating a buffer/image)
    pub fn allocateMemory(
        self: Self,
        memory_requirements: vk.MemoryRequirements,
        alloc_info: AllocationCreateInfo,
    ) Error!struct { allocation: Allocation, info: AllocationInfo } {
        var allocation: VmaAllocation = undefined;
        var info: VmaAllocationInfo = undefined;

        const vma_alloc_info = VmaAllocationCreateInfo{
            .flags = alloc_info.flags,
            .usage = alloc_info.usage,
            .requiredFlags = alloc_info.required_flags,
            .preferredFlags = alloc_info.preferred_flags,
            .memoryTypeBits = alloc_info.memory_type_bits,
            .pool = if (alloc_info.pool) |p| p.handle else null,
            .pUserData = alloc_info.user_data,
            .priority = alloc_info.priority,
        };

        try checkResult(vmaAllocateMemory(
            self.handle,
            &memory_requirements,
            &vma_alloc_info,
            &allocation,
            &info,
        ));

        return .{
            .allocation = .{ .handle = allocation },
            .info = AllocationInfo.fromC(info),
        };
    }

    /// Free previously allocated memory
    pub fn freeMemory(self: Self, allocation: Allocation) void {
        vmaFreeMemory(self.handle, allocation.handle);
    }

    /// Get information about an allocation
    pub fn getAllocationInfo(self: Self, allocation: Allocation) AllocationInfo {
        var info: VmaAllocationInfo = undefined;
        vmaGetAllocationInfo(self.handle, allocation.handle, &info);
        return AllocationInfo.fromC(info);
    }

    /// Set allocation name for debugging
    pub fn setAllocationName(self: Self, allocation: Allocation, name: ?[*:0]const u8) void {
        vmaSetAllocationName(self.handle, allocation.handle, name);
    }

    // ========================================================================
    // Pool Operations
    // ========================================================================

    /// Create a memory pool
    pub fn createPool(self: Self, info: PoolCreateInfo) Error!Pool {
        var pool: VmaPool = undefined;
        const create_info = VmaPoolCreateInfo{
            .memoryTypeIndex = info.memory_type_index,
            .flags = info.flags,
            .blockSize = info.block_size,
            .minBlockCount = info.min_block_count,
            .maxBlockCount = info.max_block_count,
            .priority = info.priority,
            .minAllocationAlignment = info.min_allocation_alignment,
        };
        try checkResult(vmaCreatePool(self.handle, &create_info, &pool));
        return .{ .handle = pool };
    }

    /// Destroy a memory pool
    pub fn destroyPool(self: Self, pool: Pool) void {
        vmaDestroyPool(self.handle, pool.handle);
    }
};

// ============================================================================
// Helper Types
// ============================================================================

/// Allocation handle
pub const Allocation = struct {
    handle: VmaAllocation,
};

/// Memory pool handle
pub const Pool = struct {
    handle: VmaPool,
};

/// Allocation creation parameters
pub const AllocationCreateInfo = struct {
    flags: AllocationCreateFlags = .{},
    usage: MemoryUsage = .auto,
    required_flags: vk.MemoryPropertyFlags = .{},
    preferred_flags: vk.MemoryPropertyFlags = .{},
    memory_type_bits: u32 = 0,
    pool: ?Pool = null,
    user_data: ?*anyopaque = null,
    priority: f32 = 0,
};

/// Pool creation parameters
pub const PoolCreateInfo = struct {
    memory_type_index: u32,
    flags: PoolCreateFlags = .{},
    block_size: vk.DeviceSize = 0,
    min_block_count: usize = 0,
    max_block_count: usize = 0,
    priority: f32 = 0,
    min_allocation_alignment: vk.DeviceSize = 0,
};

/// Information about an allocation
pub const AllocationInfo = struct {
    memory_type: u32,
    device_memory: vk.DeviceMemory,
    offset: vk.DeviceSize,
    size: vk.DeviceSize,
    mapped_data: ?*anyopaque,
    user_data: ?*anyopaque,
    name: ?[*:0]const u8,

    fn fromC(info: VmaAllocationInfo) AllocationInfo {
        return .{
            .memory_type = info.memoryType,
            .device_memory = info.deviceMemory,
            .offset = info.offset,
            .size = info.size,
            .mapped_data = info.pMappedData,
            .user_data = info.pUserData,
            .name = info.pName,
        };
    }
};

// ============================================================================
// Tests
// ============================================================================

test "flag types are correct size" {
    try std.testing.expectEqual(@sizeOf(AllocatorCreateFlags), 4);
    try std.testing.expectEqual(@sizeOf(AllocationCreateFlags), 4);
    try std.testing.expectEqual(@sizeOf(PoolCreateFlags), 4);
    try std.testing.expectEqual(@sizeOf(DefragmentationFlags), 4);
}
