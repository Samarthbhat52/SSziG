const std = @import("std");
const zon: struct {
    name: enum { SSziG },
    version: []const u8,
    fingerprint: usize,
    minimum_zig_version: []const u8,
    paths: [5][]const u8,
} = @import("build.zig.zon");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const exe = b.addExecutable(.{
        .name = "sszig",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = .ReleaseSafe,
    });

    const options = b.addOptions();
    options.addOption([]const u8, "version", zon.version);
    exe.root_module.addOptions("config", options);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .name = "tests",
        .root_source_file = b.path("src/tests.zig"),
        .target = target,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
