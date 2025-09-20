const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) !void {
    const minisign_key_ = std.posix.getenv("MINISIGN_KEY");
    const minisign_password_ = std.posix.getenv("MINISIGN_PASSWORD");
    const date = b.option([]const u8, "date", "date") orelse "1970-01-01";
    const run_number = b.option([]const u8, "run-number", "run-rumber") orelse "0";
    const run_attempt = b.option([]const u8, "run-attempt", "run-attempt") orelse "0";
    const version = b.fmt("{s}-{s}-{s}", .{ date, run_number, run_attempt });

    const gobject_codegen_dep = b.dependency(
        "gobject_codegen",
        .{},
    );

    const translate_gir_exe = gobject_codegen_dep.artifact("translate-gir");

    const translate_gir_run = b.addRunArtifact(translate_gir_exe);

    const bindings = translate_gir_run.addPrefixedOutputDirectoryArg("--output-dir=", "bindings");

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

    translate_gir_run.addPrefixedDirectoryArg("--gir-fixes-dir=", gobject_codegen_dep.path("gir-fixes"));
    translate_gir_run.addPrefixedDirectoryArg("--bindings-dir=", gobject_codegen_dep.path("binding-overrides"));
    translate_gir_run.addPrefixedDirectoryArg("--extensions-dir=", gobject_codegen_dep.path("extensions"));

    const gir_files = b.addWriteFiles();

    if (std.posix.getenv("GIR_PATH")) |gir_paths| {
        var gir_path_iterator = std.mem.splitScalar(u8, gir_paths, ':');
        while (gir_path_iterator.next()) |gir_path| {
            var gir_dir = try std.fs.cwd().openDir(gir_path, .{ .iterate = true });
            defer gir_dir.close();
            var gir_dir_iterator = gir_dir.iterate();
            while (try gir_dir_iterator.next()) |entry| {
                const ext = std.fs.path.extension(entry.name);

                if (!std.mem.eql(u8, ext, ".gir")) continue;

                _ = gir_files.addCopyFile(
                    std.Build.LazyPath{ .cwd_relative = b.pathJoin(&.{ gir_path, entry.name }) },
                    entry.name,
                );
            }
        }
    }

    translate_gir_run.addPrefixedDirectoryArg(
        "--gir-dir=",
        gir_files.getDirectory(),
    );

    translate_gir_run.addArg("Adw-1");
    translate_gir_run.addArg("GLib-2.0");
    translate_gir_run.addArg("GObject-2.0");
    translate_gir_run.addArg("Gdk-4.0");
    translate_gir_run.addArg("GdkWayland-4.0");
    translate_gir_run.addArg("GdkX11-4.0");
    translate_gir_run.addArg("GExiv2-0.10");
    translate_gir_run.addArg("Gio-2.0");
    translate_gir_run.addArg("Gsk-4.0");
    translate_gir_run.addArg("Gtk-4.0");
    translate_gir_run.addArg("Panel-1");
    translate_gir_run.addArg("Pango-1.0");
    translate_gir_run.addArg("Rsvg-2.0");
    translate_gir_run.addArg("Xdp-1.0");
    translate_gir_run.addArg("XdpGtk4-1.0");

    var artifacts: std.ArrayList(std.Build.LazyPath) = .empty;
    var files_to_sign: std.ArrayList(struct { name: []const u8, lp: std.Build.LazyPath }) = .empty;

    {
        const gobject_output = b.addWriteFiles();
        _ = gobject_output.addCopyDirectory(bindings, b.fmt("ghostty-gobject-{s}", .{version}), .{});

        b.installDirectory(.{
            .source_dir = gobject_output.getDirectory(),
            .install_dir = .{ .custom = "" },
            .install_subdir = "",
        });

        const create_gobject_tar = b.addSystemCommand(&.{
            "tar",
            "--create",
            "--dereference",
            "--mtime=1970-01-01-T00:00:00+00:00",
            "--mode=u=rwX,og=rX",
            "--owner=root:0",
            "--group=root:0",
        });
        create_gobject_tar.addPrefixedDirectoryArg("--directory=", gobject_output.getDirectory());
        const gobject_tar = create_gobject_tar.addPrefixedOutputFileArg("--file=", b.fmt("ghostty-gobject-{s}.tar", .{version}));
        create_gobject_tar.addArg(b.fmt("ghostty-gobject-{s}", .{version}));

        const install_gobject_tarfile = b.addInstallFile(gobject_tar, b.fmt("ghostty-gobject-{s}.tar", .{version}));
        b.getInstallStep().dependOn(&install_gobject_tarfile.step);

        {
            const name = b.fmt("ghostty-gobject-{s}.tar.gz", .{version});
            const create_gobject_targz = b.addSystemCommand(&.{ "gzip", "-c" });
            create_gobject_targz.addFileArg(gobject_tar);
            const stdout = create_gobject_targz.captureStdOut();
            const wf = b.addWriteFiles();
            const gobject_targz = wf.addCopyFile(stdout, name);
            const install_gobject_targz = b.addInstallFile(gobject_targz, name);
            b.getInstallStep().dependOn(&install_gobject_targz.step);
            try files_to_sign.append(b.allocator, .{ .name = name, .lp = gobject_targz });
            try artifacts.append(b.allocator, gobject_targz);
        }

        {
            const name = b.fmt("ghostty-gobject-{s}.tar.zstd", .{version});
            const create_gobject_tarzstd = b.addSystemCommand(&.{ "zstd", "-c" });
            create_gobject_tarzstd.addFileArg(gobject_tar);
            const stdout = create_gobject_tarzstd.captureStdOut();
            const wf = b.addWriteFiles();
            const gobject_tarzstd = wf.addCopyFile(stdout, name);
            const install_gobject_tarzstd = b.addInstallFile(gobject_tarzstd, name);
            b.getInstallStep().dependOn(&install_gobject_tarzstd.step);
            try files_to_sign.append(b.allocator, .{ .name = name, .lp = gobject_tarzstd });
            try artifacts.append(b.allocator, gobject_tarzstd);
        }
    }

    {
        const gir_output = b.addWriteFiles();
        _ = gir_output.addCopyDirectory(gir_files.getDirectory(), b.fmt("ghostty-gir-{s}", .{version}), .{});

        b.installDirectory(.{
            .source_dir = gir_output.getDirectory(),
            .install_dir = .{ .custom = "" },
            .install_subdir = "",
        });

        const create_gir_tar = b.addSystemCommand(&.{
            "tar",
            "--create",
            "--dereference",
            "--mtime=1970-01-01-T00:00:00+00:00",
            "--mode=u=rwX,og=rX",
            "--owner=root:0",
            "--group=root:0",
        });
        create_gir_tar.addPrefixedDirectoryArg("--directory=", gir_output.getDirectory());
        const gir_tar = create_gir_tar.addPrefixedOutputFileArg(
            "--file=",
            b.fmt("ghostty-gir-{s}.tar", .{version}),
        );
        create_gir_tar.addArg(b.fmt("ghostty-gir-{s}", .{version}));

        {
            const name = b.fmt("ghostty-gir-{s}.tar.gz", .{version});
            const create_gir_targz = b.addSystemCommand(&.{ "gzip", "-c" });
            create_gir_targz.addFileArg(gir_tar);
            const stdout = create_gir_targz.captureStdOut();
            const wf = b.addWriteFiles();
            const gir_targz = wf.addCopyFile(stdout, name);
            const install_gir_targz = b.addInstallFile(gir_targz, name);
            b.getInstallStep().dependOn(&install_gir_targz.step);
            try files_to_sign.append(b.allocator, .{ .name = name, .lp = gir_targz });
            try artifacts.append(b.allocator, gir_targz);
        }

        {
            const name = b.fmt("ghostty-gir-{s}.tar.zstd", .{version});
            const create_gir_tarzstd = b.addSystemCommand(&.{ "zstd", "-c" });
            create_gir_tarzstd.addFileArg(gir_tar);
            const stdout = create_gir_tarzstd.captureStdOut();
            const wf = b.addWriteFiles();
            const gir_tarzstd = wf.addCopyFile(stdout, name);
            const install_gir_tarzstd = b.addInstallFile(gir_tarzstd, name);
            b.getInstallStep().dependOn(&install_gir_tarzstd.step);
            try files_to_sign.append(b.allocator, .{ .name = name, .lp = gir_tarzstd });
            try artifacts.append(b.allocator, gir_tarzstd);
        }
    }

    minisign: {
        const wf = b.addWriteFiles();
        const minisign_key = wf.add("minisign.key", b.fmt("\n{s}\n", .{minisign_key_ orelse break :minisign}));
        const minisign_password = wf.add("minisign.password", b.fmt("{s}", .{minisign_password_ orelse break :minisign}));

        for (files_to_sign.items) |item| {
            const name = b.fmt("{s}.minisig", .{item.name});
            const minisign = b.addSystemCommand(&.{ "minisign", "-S" });
            minisign.addArg("-m");
            minisign.addFileArg(item.lp);
            minisign.addArg("-x");
            const minisig = minisign.addOutputFileArg(name);
            minisign.addArg("-s");
            minisign.addFileArg(minisign_key);
            minisign.setStdIn(.{ .lazy_path = minisign_password });
            const install_minisig = b.addInstallFile(minisig, name);
            b.getInstallStep().dependOn(&install_minisig.step);
            try artifacts.append(b.allocator, minisig);
        }
    }

    const gh = b.addSystemCommand(
        &.{
            "gh",
            "release",
            "create",
            version,
            "--latest",
            "--title",
            version,
            "--notes",
            version,
        },
    );
    for (artifacts.items) |lp| {
        gh.addFileArg(lp);
    }
    const release_step = b.step("gh-release", "create a GitHub release");
    release_step.dependOn(&gh.step);
}
