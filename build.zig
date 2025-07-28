const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addLibrary(.{
        .name = "x11-headers",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });
    lib.addCSourceFile(.{ .file = b.addWriteFiles().add("empty.c", "") });

    // contains only GLX headers!
    lib.installHeadersDirectory(b.path("GL"), "GL", .{});
    lib.installHeadersDirectory(b.path("X11"), "X11", .{});
    lib.installHeadersDirectory(b.path("xcb"), "xcb", .{});
    lib.installHeadersDirectory(b.path("xkbcommon"), "xkbcommon", .{});

    b.installArtifact(lib);
}
