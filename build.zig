const std = @import("std");
const Build = std.Build;
const CompileStep = std.Build.Step.Compile;

/// set this to true to link libc
const should_link_libc = false;

const required_zig_version = std.SemanticVersion.parse("0.13.0") catch unreachable;

fn linkObject(b: *Build, obj: *CompileStep) void {
    if (should_link_libc) obj.linkLibC();
    _ = b;

    // Add linking for packages or third party libraries here
}

pub fn build(b: *Build) void {
    if (comptime @import("builtin").zig_version.order(required_zig_version) == .lt) {
        std.debug.print("Warning: Your version of Zig too old. You will need to download a newer build\n", .{});
        std.os.exit(1);
    }

    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    const bench = b.option(bool, "bench", "Print internal benchmarking information [default: false].");
    const build_opts = b.addOptions();
    build_opts.addOption(bool, "bench", bench orelse false);

    const install_all = b.step("install_all", "Install all days");
    const run_all = b.step("run_all", "Run all days");

    const generate = b.step("generate", "Generate stub files from template/template.zig");
    const build_generate = b.addExecutable(.{
        .name = "generate",
        .root_source_file = b.path("template/generate.zig"),
        .target = target,
        .optimize = .ReleaseSafe,
    });

    const run_generate = b.addRunArtifact(build_generate);
    run_generate.setCwd(b.path("")); // This could probably be done in a more idiomatic way
    generate.dependOn(&run_generate.step);

    // Set up an exe for each day
    var has_day: [26]bool = undefined;
    var day: u32 = 1;
    while (day <= 25) : (day += 1) {
        const dayString = b.fmt("day{:0}", .{day});
        const zigFile = b.fmt("src/{s}.zig", .{dayString});

        const inputFileName = b.fmt("src/data/{s}.txt", .{dayString});
        const inputFile = b.path(inputFileName);
        const inputFilePath = inputFile.getPath(b);
        const hasInputFile = if (std.fs.accessAbsolute(inputFilePath, .{})) true else |_| false;
        has_day[day] = hasInputFile;

        const exe = b.addExecutable(.{
            .name = dayString,
            .root_source_file = b.path(zigFile),
            .target = target,
            .optimize = mode,
        });
        linkObject(b, exe);
        exe.root_module.addOptions("opts", build_opts);

        const install_cmd = b.addInstallArtifact(exe, .{});

        const build_test = b.addTest(.{
            .root_source_file = b.path(zigFile),
            .target = target,
            .optimize = mode,
        });
        linkObject(b, build_test);

        const run_test = b.addRunArtifact(build_test);
        const install_test_cmd = b.addInstallArtifact(build_test, .{});

        {
            const step_key = b.fmt("install_{s}", .{dayString});
            const step_desc = b.fmt("Install {s}.exe", .{dayString});
            const install_step = b.step(step_key, step_desc);
            install_step.dependOn(&install_cmd.step);
            install_all.dependOn(&install_cmd.step);
        }

        {
            const step_key = b.fmt("test_{s}", .{dayString});
            const step_desc = b.fmt("Run tests in {s}", .{zigFile});
            const step = b.step(step_key, step_desc);
            step.dependOn(&run_test.step);
        }

        {
            const step_key = b.fmt("install_test_{s}", .{dayString});
            const step_desc = b.fmt("Install tests in {s}", .{zigFile});
            const install_step = b.step(step_key, step_desc);
            install_step.dependOn(&install_test_cmd.step);
        }

        const run_cmd = b.addRunArtifact(exe);
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_desc = b.fmt("Run {s}", .{dayString});
        const run_step = b.step(dayString, run_desc);
        run_step.dependOn(&run_cmd.step);
    }

    // Set up tests for util.zig
    {
        const test_util = b.step("test_util", "Run tests in util.zig");
        const test_cmd = b.addTest(.{
            .root_source_file = b.path("src/util.zig"),
            .target = target,
            .optimize = mode,
        });
        linkObject(b, test_cmd);
        test_util.dependOn(&test_cmd.step);
    }

    // Set up all tests contained in test_all.zig
    const test_all = b.step("test", "Run all tests");
    const all_tests = b.addTest(.{
        .root_source_file = b.path("src/test_all.zig"),
        .target = target,
        .optimize = mode,
    });
    const run_all_tests = b.addRunArtifact(all_tests);
    test_all.dependOn(&run_all_tests.step);

    const all_days = b.addExecutable(.{
        .name = "run_all",
        .root_source_file = b.path("src/run_all.zig"),
        .target = target,
        .optimize = mode,
    });
    build_opts.addOption([26]bool, "has_input", has_day);
    all_days.root_module.addOptions("opts", build_opts);

    const run_all_cmd = b.addRunArtifact(all_days);
    if (b.args) |args| {
        run_all_cmd.addArgs(args);
    }
    run_all.dependOn(&run_all_cmd.step);
    const install_run_all_step = b.step("install_run_all", "Install run all days");
    const install_run_all = b.addInstallArtifact(all_days, .{});
    install_run_all_step.dependOn(&install_run_all.step);
}
