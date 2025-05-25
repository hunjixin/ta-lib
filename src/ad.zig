const std = @import("std");
const Column = @import("./lib.zig").Column;
const DataFrame = @import("./lib.zig").DataFrame;
const MyError = @import("./lib.zig").MyError;

// The AD function calculates the Accumulation/Distribution Line (ADL) for a given DataFrame.
// Formula: ADL = SUM(((2 * Close - High - Low) / (High - Low)) * Volume)
// This is a cumulative indicator that uses the relationship between the stock's price and volume
// to determine the flow of money into or out of a stock over time.
pub fn AD(df: *const DataFrame(f64), allocator: std.mem.Allocator) ![]f64 {
    const high = try df.getColumnData("high");
    const low = try df.getColumnData("low");
    const close = try df.getColumnData("close");
    const volume = try df.getColumnData("volume");

    if (!(high.len == low.len and low.len == close.len and close.len == volume.len)) {
        return MyError.RowColumnMismatch;
    }

    var ads = try allocator.alloc(f64, high.len);
    var ad: f64 = 0.0;

    for (0..close.len) |i| {
        const h = high[i];
        const l = low[i];
        const c = close[i];
        const v = volume[i];

        const range = h - l;
        const clv = if (range != 0.0) (2.0 * c - h - l) / range else 0.0;

        ad += clv * v;
        ads[i] = ad;
    }

    return ads;
}

test "AD calculation works correctly" {
    const gpa = std.testing.allocator;

    var df = try DataFrame(f64).init(gpa);
    defer df.deinit();

    try df.addColumnWithData("high", &[_]f64{ 10.0, 12.0, 14.0 });
    try df.addColumnWithData("low", &[_]f64{ 5.0, 6.0, 7.0 });
    try df.addColumnWithData("close", &[_]f64{ 7.0, 10.0, 12.0 });
    try df.addColumnWithData("volume", &[_]f64{ 1000.0, 1500.0, 2000.0 });

    const adColumn = try AD(&df, gpa);
    defer gpa.free(adColumn);

    try std.testing.expect(adColumn.len == 3);
    try std.testing.expect(std.math.approxEqAbs(f64, adColumn[0], -200, 1e-9));
    try std.testing.expect(std.math.approxEqAbs(f64, adColumn[1], 300, 1e-9));
    try std.testing.expect(std.math.approxEqAbs(f64, adColumn[2], 1157.1428571428571, 1e-9));
}

test "AD handles row-column mismatch" {
    const gpa = std.testing.allocator;

    var df = try DataFrame(f64).init(gpa);
    defer df.deinit();

    try df.addColumnWithData("high", &[_]f64{ 10.0, 12.0 });
    try df.addColumnWithData("low", &[_]f64{ 5.0, 6.0 });
    try df.addColumnWithData("close", &[_]f64{ 7.0, 10.0 });
    try df.addColumnWithData("volume", &[_]f64{1000.0}); // Mismatched length

    const result = AD(&df, gpa);
    try std.testing.expectError(MyError.RowColumnMismatch, result);
}

test "AD handles division by zero gracefully" {
    const gpa = std.testing.allocator;

    var df = try DataFrame(f64).init(gpa);
    defer df.deinit();

    try df.addColumnWithData("high", &[_]f64{ 10.0, 10.0, 10.0 });
    try df.addColumnWithData("low", &[_]f64{ 10.0, 10.0, 10.0 }); // High == Low
    try df.addColumnWithData("close", &[_]f64{ 10.0, 10.0, 10.0 });
    try df.addColumnWithData("volume", &[_]f64{ 1000.0, 1500.0, 2000.0 });

    const adColumn = try AD(&df, gpa);
    defer gpa.free(adColumn);

    try std.testing.expect(adColumn.len == 3);
    try std.testing.expect(adColumn[0] == 0.0);
    try std.testing.expect(adColumn[1] == 0.0);
    try std.testing.expect(adColumn[2] == 0.0);
}
