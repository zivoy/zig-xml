const std = @import("std");
// const deps = @import("./deps.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.option(std.builtin.OptimizeMode, "mode", "") orelse .Debug;
    const disable_llvm = b.option(bool, "disable_llvm", "use the non-llvm zig codegen") orelse false;

    const tracer = b.dependency("tracer", .{ .mode = mode });

    const mod = b.addModule("xml", .{
        .root_source_file = b.path("mod.zig"),
        .target = target,
        .optimize = mode,
    });
    mod.addImport("tracer", tracer.module("tracer"));

    {
        const exe = b.addExecutable(.{
            .name = "bench",
            .root_module = b.createModule(.{
                .root_source_file = b.path("main.zig"),
                .target = target,
                .optimize = mode,
                .imports = &.{
                    .{ .name = "xml", .module = mod },
                },
            }),
        });
        exe.use_llvm = !disable_llvm;
        exe.use_lld = !disable_llvm;
        exe.linkLibC();

        const run_exe = b.addRunArtifact(exe);
        if (b.args) |args| {
            run_exe.addArgs(args);
        }

        const run_step = b.step("run", "Run benchmark");
        run_step.dependOn(&run_exe.step);
    }

    const unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("test.zig"),
            .target = target,
            .optimize = mode,

            .imports = &.{
                .{ .name = "xml", .module = mod },
            },
        }),
    });
    unit_tests.use_llvm = !disable_llvm;
    unit_tests.use_lld = !disable_llvm;

    const run_unit_tests = b.addRunArtifact(unit_tests);
    run_unit_tests.has_side_effects = true;

    const test_step = b.step("test", "Run all library tests");
    test_step.dependOn(&run_unit_tests.step);
}
