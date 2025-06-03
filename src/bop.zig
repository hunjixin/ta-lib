const std = @import("std");
const MyError = @import("./lib.zig").MyError;

/// Calculates the Balance of Power (BOP) indicator for the given prices.
///
/// The Balance of Power (BOP) is a technical analysis indicator that measures the strength of buyers versus sellers
/// by comparing the distance between the close and open prices to the distance between the high and low prices.
///
/// Formula:
///     BOP = (Close - Open) / (High - Low)
///
/// - `open`: The open price of the asset.
/// - `high`: The high price of the asset.
/// - `low`: The low price of the asset.
/// - `close`: The closing price of the asset.
/// - `allocator`: Allocator to use for the result array.
///
/// Returns an array of f64 values representing the BOP for each row.
/// Returns an error if memory allocation fails or if required columns are missing.
pub fn Bop(open: []const f64, high: []const f64, low: []const f64, close: []const f64, allocator: std.mem.Allocator) ![]f64 {
    if (!(high.len == low.len and low.len == close.len and close.len == open.len)) {
        return MyError.RowColumnMismatch;
    }

    var outs = try allocator.alloc(f64, high.len);
    errdefer allocator.free(outs);
    for (0..close.len) |i| {
        const range = high[i] - low[i];
        outs[i] = if (range > 0.00000000000001) (close[i] - open[i]) / range else 0.0;
    }

    return outs;
}

test "Bop calculation works correctly" {
    const gpa = std.testing.allocator;

    const high = [_]f64{ 10, 12, 11, 13, 13, 14, 13, 15, 14, 100, 17, 16, 18, 17, 19, 21, 23, 22, 25, 24, 27, 29, 28, 30, 32, 31, 35, 34, 36, 38 };
    const low = [_]f64{ 8, 9, 9, 10, 12, 12, 12, 13, 13, 14, 100, 15, 16, 16, 17, 18, 19, 18, 20, 21, 22, 24, 23, 25, 26, 27, 28, 29, 30, 31 };
    const close = [_]f64{ 8, 9, 9, 10, 12, 12, 12, 13, 13, 14, 100, 15, 16, 16, 17, 19, 20, 21, 23, 22, 24, 26, 25, 27, 29, 28, 32, 33, 34, 35 };
    const open = [_]f64{ 8, 10, 10, 11, 12, 13, 12, 14, 13, 15, 99, 14, 15, 15, 16, 18, 19, 20, 22, 21, 23, 25, 24, 26, 28, 27, 31, 32, 33, 34 };
    const adColumn = try Bop(&open, &high, &low, &close, gpa);
    defer gpa.free(adColumn);

    const expect = [_]f64{
        0,   -0.3333333333333333, -0.5, -0.3333333333333333, 0,                   -0.5,               0,                   -0.5, 0,                   -0.011627906976744186,
        0,   1,                   0.5,  1,                   0.5,                 0.3333333333333333, 0.25,                0.25, 0.2,                 0.3333333333333333,
        0.2, 0.2,                 0.2,  0.2,                 0.16666666666666666, 0.25,               0.14285714285714285, 0.2,  0.16666666666666666, 0.14285714285714285,
    };
    try std.testing.expect(adColumn.len == expect.len);
    for (adColumn, expect) |actual, exp| {
        try std.testing.expectApproxEqAbs(exp, actual, 1e-9);
    }
}
