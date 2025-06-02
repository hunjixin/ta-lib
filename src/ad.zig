const std = @import("std");
const MyError = @import("./lib.zig").MyError;

// The AD function calculates the Accumulation/Distribution Line (ADL) for a given DataFrame.
// Formula: ADL = SUM(((2 * Close - High - Low) / (High - Low)) * Volume)
// This is a cumulative indicator that uses the relationship between the stock's price and volume
// to determine the flow of money into or out of a stock over time.
pub fn AD(high: []const f64, low: []const f64, close: []const f64, volume: []const f64, allocator: std.mem.Allocator) ![]f64 {
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

    const high = [_]f64{ 10.0, 12.0, 14.0 };
    const low = [_]f64{ 5.0, 6.0, 7.0 };
    const close = [_]f64{ 7.0, 10.0, 12.0 };
    const volume = [_]f64{ 1000.0, 1500.0, 2000.0 };
    const adColumn = try AD(&high, &low, &close, &volume, gpa);
    defer gpa.free(adColumn);

    try std.testing.expect(adColumn.len == 3);
    try std.testing.expectApproxEqAbs(-200, adColumn[0], 1e-9);
    try std.testing.expectApproxEqAbs(300, adColumn[1], 1e-9);
    try std.testing.expectApproxEqAbs(1157.1428571428571, adColumn[2], 1e-9);
}
