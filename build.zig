const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const cwd = std.fs.cwd();
    var allocator = std.heap.page_allocator;

    const rootModule = b.createModule(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
        .error_tracing = true,
    });
    const lib = b.addStaticLibrary(.{ .name = "ta_lib", .root_module = rootModule });

    b.installArtifact(lib);

    var src_dir = cwd.openDir("src", .{ .iterate = true }) catch {
        std.log.err("⚠️ cannot open 'src/'", .{});
        return;
    };
    defer src_dir.close();
    const run_tests = b.step("test", "Run all unit tests");

    var iter = src_dir.iterate();
    while (try iter.next()) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.name, ".zig")) continue;

        const path_buf = try std.fs.path.join(allocator, &[_][]const u8{ "src", entry.name });
        defer allocator.free(path_buf);

        const test_compiled = b.addTest(.{ .name = entry.name, .root_module = rootModule });

        const test_run = b.addRunArtifact(test_compiled);
        run_tests.dependOn(&test_run.step);
    }
}
