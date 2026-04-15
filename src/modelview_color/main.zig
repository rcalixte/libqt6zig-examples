const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const qabstractlistmodel = qt6.qabstractlistmodel;
const qlistview = qt6.qlistview;
const qnamespace_enums = qt6.qnamespace_enums;
const qmodelindex = qt6.qmodelindex;
const qvariant = qt6.qvariant;
const qcolor = qt6.qcolor;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    const model = qabstractlistmodel.New();

    qabstractlistmodel.OnColumnCount(model, onColumnCount);
    qabstractlistmodel.OnRowCount(model, onRowCount);
    qabstractlistmodel.OnData(model, onData);

    const listview = qlistview.New2();
    defer qlistview.Delete(listview);

    qlistview.SetModel(listview, model);
    qlistview.Show(listview);

    _ = qapplication.Exec();
}

fn onRowCount(_: ?*anyopaque, _: ?*anyopaque) callconv(.c) i32 {
    return 1000;
}

fn onColumnCount(_: ?*anyopaque, _: ?*anyopaque) callconv(.c) i32 {
    return 1;
}

fn onData(_: ?*anyopaque, index: ?*anyopaque, role: i32) callconv(.c) C.QVariant {
    switch (role) {
        qnamespace_enums.ItemDataRole.ForegroundRole => if (@mod(qmodelindex.Row(index), 2) == 0) {
            const color = qcolor.New5(0, 0, 0);
            defer qcolor.Delete(color);
            return qcolor.ToQVariant(color);
        } else {
            const color = qcolor.New5(255, 0, 0);
            defer qcolor.Delete(color);
            return qcolor.ToQVariant(color);
        },
        qnamespace_enums.ItemDataRole.BackgroundRole => if (@mod(qmodelindex.Row(index), 2) == 0) {
            const color = qcolor.New5(255, 255, 255);
            defer qcolor.Delete(color);
            return qcolor.ToQVariant(color);
        } else {
            const color = qcolor.New5(80, 80, 80);
            defer qcolor.Delete(color);
            return qcolor.ToQVariant(color);
        },
        qnamespace_enums.ItemDataRole.DisplayRole => {
            var buf: [16]u8 = undefined;
            const str = std.fmt.bufPrint(&buf, "this is row {d}", .{qmodelindex.Row(index)}) catch @panic("failed to bufPrint");
            return qvariant.New24(str);
        },
        else => return qvariant.New(),
    }
}
