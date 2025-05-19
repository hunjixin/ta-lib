const std = @import("std");
const Column = @import("./lib.zig").Column;
const DataFrame = @import("./lib.zig").DataFrame;
const MyError = @import("./lib.zig").MyError;

pub fn AD(df: *DataFrame(f64), allocator: std.mem.Allocator) !Column(f64) {
    //const len = try df.getColumnData("Close");
    const high = try df.getColumnData("High");
    const low = try df.getColumnData("Low");
    const close = try df.getColumnData("Close");
    const volume = try df.getColumnData("Volume");

    if (!(high.len == low.len and low.len == close.len and close.len == volume.len)) {
        return MyError.RowColumnMismatch;
    }

    var adColumn = try Column(f64).init(allocator, "AD");
    var ad: f64 = 0.0;

    for (0..close.len) |i| {
        const h = high[i];
        const l = low[i];
        const c = close[i];
        const v = volume[i];

        const range = h - l;
        const clv = if (range != 0.0) (2.0 * c - h - l) / range else 0.0;

        ad += clv * v;
        try adColumn.push(ad);
    }

    return adColumn;
}

test "AD calculation works correctly" {
    const gpa = std.testing.allocator;

    var df = try DataFrame(f64).init(gpa);
    defer df.deinit();

    try df.addColumnWithData("High", &[_]f64{ 10.0, 12.0, 14.0 });
    try df.addColumnWithData("Low", &[_]f64{ 5.0, 6.0, 7.0 });
    try df.addColumnWithData("Close", &[_]f64{ 7.0, 10.0, 12.0 });
    try df.addColumnWithData("Volume", &[_]f64{ 1000.0, 1500.0, 2000.0 });

    var adColumn = try AD(&df, gpa);
    defer adColumn.deinit();

    try std.testing.expect(adColumn.len() == 3);
    std.debug.print("AD values: {}\n", .{adColumn.get(1)});
    try std.testing.expect(std.math.approxEqAbs(f64, adColumn.get(0), -200, 1e-9));
    try std.testing.expect(std.math.approxEqAbs(f64, adColumn.get(1), 300, 1e-9));
    try std.testing.expect(std.math.approxEqAbs(f64, adColumn.get(2), 1157.1428571428571, 1e-9));
}

test "AD handles row-column mismatch" {
    const gpa = std.testing.allocator;

    var df = try DataFrame(f64).init(gpa);
    defer df.deinit();

    try df.addColumnWithData("High", &[_]f64{ 10.0, 12.0 });
    try df.addColumnWithData("Low", &[_]f64{ 5.0, 6.0 });
    try df.addColumnWithData("Close", &[_]f64{ 7.0, 10.0 });
    try df.addColumnWithData("Volume", &[_]f64{1000.0}); // Mismatched length

    const result = AD(&df, gpa);
    try std.testing.expectError(MyError.RowColumnMismatch, result);
}

test "AD handles division by zero gracefully" {
    const gpa = std.testing.allocator;

    var df = try DataFrame(f64).init(gpa);
    defer df.deinit();

    try df.addColumnWithData("High", &[_]f64{ 10.0, 10.0, 10.0 });
    try df.addColumnWithData("Low", &[_]f64{ 10.0, 10.0, 10.0 }); // High == Low
    try df.addColumnWithData("Close", &[_]f64{ 10.0, 10.0, 10.0 });
    try df.addColumnWithData("Volume", &[_]f64{ 1000.0, 1500.0, 2000.0 });

    var adColumn = try AD(&df, gpa);
    defer adColumn.deinit();

    try std.testing.expect(adColumn.len() == 3);
    try std.testing.expect(adColumn.get(0) == 0.0);
    try std.testing.expect(adColumn.get(1) == 0.0);
    try std.testing.expect(adColumn.get(2) == 0.0);
}
