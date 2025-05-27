const std = @import("std");
const DataFrame = @import("./lib.zig").DataFrame;
const IsZero = @import("./utils.zig").IsZero;

pub fn WillR(df: *const DataFrame(f64), inTimePeriod: usize, allocator: std.mem.Allocator) ![]f64 {
    const len = df.getRowCount();
    var out = try allocator.alloc(f64, len);
    @memset(out, 0);

    const high = try df.getColumnData("high");
    const low = try df.getColumnData("low");
    const close = try df.getColumnData("close");

    for (inTimePeriod - 1..len) |i| {
        var maxHigh: f64 = -std.math.inf(f64);
        var minLow: f64 = std.math.inf(f64);

        for (i + 1 - inTimePeriod..i + 1) |j| {
            maxHigh = @max(maxHigh, high[j]);
            minLow = @min(minLow, low[j]);
        }
        const diff = maxHigh - minLow;
        if (IsZero(diff) or IsZero(maxHigh - close[i])) {
            out[i] = 0;
        } else {
            out[i] = -100 * (maxHigh - close[i]) / diff;
        }
    }
    return out;
}

test "WillR " {
    var allocator = std.testing.allocator;

    // Trend reversals and choppy data: up, down, up, down, flat, up, down, up, down, up
    const highs = [_]f64{ 10, 12, 11, 13, 13, 14, 13, 15, 14, 100, 17, 16, 18, 17, 19 };
    const lows = [_]f64{ 8, 9, 9, 10, 12, 12, 12, 13, 13, 14, 100, 15, 16, 16, 17 };
    const closes = [_]f64{ 9, 11, 10, 12, 13, 13, 13, 14, 14, 100, 16, 16, 17, 17, 18 };

    var df = try DataFrame(f64).init(allocator);
    defer df.deinit();

    try df.addColumnWithData("high", highs[0..]);
    try df.addColumnWithData("low", lows[0..]);
    try df.addColumnWithData("close", closes[0..]);

    const period = 5;
    const adx = try WillR(&df, period, allocator);
    defer allocator.free(adx);

    const expected = [_]f64{ 0, 0, 0, 0, 0, -20, -20, -20, -33.333333333333336, 0, -95.45454545454545, -96.55172413793103, -95.40229885057471, -96.51162790697674, -25 };
    for (adx, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}
