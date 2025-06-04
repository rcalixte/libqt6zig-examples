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

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    _ = qapplication.New(@intCast(argc), argv);

    const model = qabstractlistmodel.New();

    qabstractlistmodel.OnColumnCount(model, onColumnCount);
    qabstractlistmodel.OnRowCount(model, onRowCount);
    qabstractlistmodel.OnData(model, onData);

    const listview = qlistview.New2();
    defer qlistview.QDelete(listview);

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
            defer qcolor.QDelete(color);
            return qcolor.ToQVariant(color);
        } else {
            const color = qcolor.New5(255, 0, 0);
            defer qcolor.QDelete(color);
            return qcolor.ToQVariant(color);
        },
        qnamespace_enums.ItemDataRole.BackgroundRole => if (@mod(qmodelindex.Row(index), 2) == 0) {
            const color = qcolor.New5(255, 255, 255);
            defer qcolor.QDelete(color);
            return qcolor.ToQVariant(color);
        } else {
            const color = qcolor.New5(80, 80, 80);
            defer qcolor.QDelete(color);
            return qcolor.ToQVariant(color);
        },
        qnamespace_enums.ItemDataRole.DisplayRole => {
            var buf: [16]u8 = undefined;
            const str = std.fmt.bufPrintZ(&buf, "this is row {d}", .{qmodelindex.Row(index)}) catch @panic("failed to bufPrintZ");
            return qvariant.New11(str);
        },
        else => return qvariant.New(),
    }
}
