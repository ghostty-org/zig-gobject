const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const version = b.option([]const u8, "version", "version number");

    const zig_gobject_dep = b.dependency(
        "zig_gobject",
        .{},
    );

    const translate_gir_exe = zig_gobject_dep.artifact("translate-gir");

    const translate_gir_run = b.addRunArtifact(translate_gir_exe);

    const output = translate_gir_run.addPrefixedOutputDirectoryArg("--output-dir=", "bindings");

    translate_gir_run.addPrefixedDirectoryArg("--gir-fixes-dir=", b.path("gir-fixes"));
    {
        const gir_fixes_path = b.pathFromRoot("gir-fixes");
        var gir_fixes_dir = std.fs.openDirAbsolute(gir_fixes_path, .{ .iterate = true }) catch unreachable;
        var it = gir_fixes_dir.iterate();
        while (it.next() catch unreachable) |entry| {
            switch (entry.kind) {
                .file => {
                    if (std.mem.eql(u8, std.fs.path.extension(entry.name), ".xslt"))
                        translate_gir_run.addFileInput(b.path(b.fmt("gir-fixes/{s}", .{entry.name})));
                },
                else => {},
            }
        }
    }

    translate_gir_run.addPrefixedDirectoryArg("--gir-fixes-dir=", zig_gobject_dep.path("gir-fixes"));
    translate_gir_run.addPrefixedDirectoryArg("--bindings-dir=", zig_gobject_dep.path("binding-overrides"));
    translate_gir_run.addPrefixedDirectoryArg("--extensions-dir=", zig_gobject_dep.path("extensions"));

    if (std.posix.getenv("GIR_PATH")) |gir_path| {
        var it = std.mem.splitScalar(u8, gir_path, ':');
        while (it.next()) |path| {
            translate_gir_run.addPrefixedDirectoryArg("--gir-dir=", std.Build.LazyPath{ .cwd_relative = path });
        }
    }

    translate_gir_run.addArg("Adw-1");
    translate_gir_run.addArg("GLib-2.0");
    translate_gir_run.addArg("GObject-2.0");
    translate_gir_run.addArg("Gdk-4.0");
    translate_gir_run.addArg("GdkWayland-4.0");
    translate_gir_run.addArg("GdkX11-4.0");
    translate_gir_run.addArg("Gio-2.0");
    translate_gir_run.addArg("Gsk-4.0");
    translate_gir_run.addArg("Gtk-4.0");
    translate_gir_run.addArg("Pango-1.0");

    b.installDirectory(.{
        .source_dir = output,
        .install_dir = .{ .custom = "" },
        .install_subdir = if (version) |v|
            b.fmt("ghostty-gobject-{s}-{s}", .{ builtin.zig_version_string, v })
        else
            b.fmt("ghostty-gobject-{s}", .{builtin.zig_version_string}),
    });
}
