const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const cwd = std.fs.cwd();
    var allocator = std.heap.page_allocator;

    //run unit test
    var srcDir = cwd.openDir("src", .{ .iterate = true }) catch {
        std.log.err("⚠️ cannot open 'src/'", .{});
        return;
    };
    defer srcDir.close();

    const runTests = b.step("test", "Run all unit tests");
    var iter = srcDir.iterate();
    while (try iter.next()) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.name, ".zig")) continue;

        const pathBuf = try std.fs.path.join(allocator, &[_][]const u8{ "src", entry.name });
        defer allocator.free(pathBuf);

        const testModule = b.createModule(.{
            .root_source_file = b.path(pathBuf),
            .target = target,
            .optimize = optimize,
            .error_tracing = true,
        });
        const testCompiled = b.addTest(.{ .name = entry.name, .root_module = testModule });
        const testRun = b.addRunArtifact(testCompiled);
        runTests.dependOn(&testRun.step);
    }

    //lib module
    const libModule = b.createModule(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
        .error_tracing = true,
    });

    var integratestModule = b.createModule(.{
        .root_source_file = b.path("tests/main.zig"),
        .target = target,
        .optimize = optimize,
        .error_tracing = true,
    });

    integratestModule.addImport("ta_lib", libModule);
    const integratestCompiled = b.addExecutable(.{ .name = "integratest", .root_module = integratestModule });
    const integratestRun = b.addRunArtifact(integratestCompiled);
    const installStep = b.addInstallArtifact(integratestCompiled, .{});
    runTests.dependOn(&installStep.step);
    runTests.dependOn(&integratestRun.step);

    //run examples
    var exampleDir = cwd.openDir("examples", .{ .iterate = true }) catch {
        std.log.err("⚠️ cannot open 'examples/'", .{});
        return;
    };
    defer exampleDir.close();

    const runExamples = b.step("examples", "Run all examples");
    var exampleIter = exampleDir.iterate();
    while (try exampleIter.next()) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.name, ".zig")) continue;

        const pathBuf = try std.fs.path.join(allocator, &[_][]const u8{ "examples", entry.name });
        defer allocator.free(pathBuf);

        var exampleModule = b.createModule(.{
            .root_source_file = b.path(pathBuf),
            .target = target,
            .optimize = optimize,
            .error_tracing = true,
        });

        exampleModule.addImport("ta_lib", libModule);
        const exampleCompiled = b.addExecutable(.{ .name = entry.name, .root_module = exampleModule });
        const testRun = b.addRunArtifact(exampleCompiled);
        runExamples.dependOn(&testRun.step);
    }
}
