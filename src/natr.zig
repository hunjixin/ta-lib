const std = @import("std");
const TRange = @import("lib.zig").TRange;
const Sma = @import("lib.zig").Sma;

pub fn Natr(
    inHigh: []const f64,
    inLow: []const f64,
    inClose: []const f64,
    inTimePeriod: usize,
    allocator: std.mem.Allocator,
) ![]f64 {
    const len = inHigh.len;
    var outReal = try allocator.alloc(f64, len);
    @memset(outReal, 0);
    const inTimePeriodF: f64 = @floatFromInt(inTimePeriod);

    if (inTimePeriod < 1) {
        return outReal;
    }

    if (inTimePeriod <= 1) {
        return TRange(inHigh, inLow, inClose, allocator);
    }

    const tr = try TRange(inHigh, inLow, inClose, allocator);
    defer allocator.free(tr);
    const prevATRTemp = try Sma(tr, inTimePeriod, allocator);
    defer allocator.free(prevATRTemp);

    var prevATR = prevATRTemp[inTimePeriod];
    outReal[inTimePeriod] = if (inClose[inTimePeriod] != 0) (100 * prevATR / inClose[inTimePeriod]) else 0.0;

    var today = inTimePeriod + 1;
    for (inTimePeriod + 1..len) |i| {
        prevATR *= inTimePeriodF - 1.0;
        prevATR += tr[today];
        prevATR /= inTimePeriodF;
        outReal[i] = if (inClose[today] != 0) (100 * prevATR / inClose[today]) else 0.0;
        today += 1;
    }
    return outReal;
}

test "Natr basic test" {
    const allocator = std.testing.allocator;

    const highs = [_]f64{ 13.27, 15.84, 11.46, 16.92, 14.15, 10.58, 18.33, 12.71, 17.49, 9.94, 19.02, 11.88, 13.63, 14.91, 16.47, 12.39, 15.02, 10.73, 17.76, 13.05 };
    const lows = [_]f64{ 11.12, 13.91, 10.08, 15.44, 12.77, 9.86, 16.50, 11.62, 15.88, 8.94, 17.11, 10.55, 12.41, 13.59, 14.89, 10.94, 13.31, 9.21, 15.61, 11.82 };
    const closes = [_]f64{ 12.20, 14.65, 10.90, 16.30, 13.60, 10.15, 17.40, 12.10, 16.73, 9.40, 18.15, 11.11, 13.02, 14.20, 15.69, 11.60, 14.30, 10.01, 16.80, 12.51 };

    const result = try Natr(
        &highs,
        &lows,
        &closes,
        10,
        allocator,
    );
    defer allocator.free(result);

    const expected = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32.09917355371901, 54.03600360036005, 43.4336405529954, 37.172915492957756, 31.7252938177183, 42.7149029310345, 33.57647458741259, 48.25466812587413, 30.489661020595243, 40.831628667577945 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}
