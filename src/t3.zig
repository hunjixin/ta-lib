const std = @import("std");
const MyError = @import("./lib.zig").MyError;

/// T3 - Triple Exponential Moving Average (T3)
/// Formula: T3 = c1*E6 + c2*E5 + c3*E4 + c4*E3
/// where E1..E6 are 6 sequential EMAs of the input, and c1..c4 are coefficients based on vFactor.
pub fn T3(
    prices: []const f64,
    inTimePeriod: usize,
    inVFactor: f64,
    allocator: std.mem.Allocator,
) ![]f64 {
    if (inTimePeriod < 1 or prices.len < 6 * (inTimePeriod - 1) + 1) {
        return MyError.InvalidInput;
    }

    const lookbackTotal = 6 * (inTimePeriod - 1);
    const outLen = prices.len;
    var outReal = try allocator.alloc(f64, outLen);
    errdefer allocator.free(outReal);
    @memset(outReal, 0);

    const k = 2.0 / (@as(f64, @floatFromInt(inTimePeriod)) + 1.0);
    const oneMinusK = 1.0 - k;

    // Initialize Ema buffers
    var today: usize = 0;
    var tempReal = prices[today];
    today += 1;
    // Calculate first Ema (E1) seed
    var i = inTimePeriod - 1;
    while (i > 0) : (i -= 1) {
        tempReal += prices[today];
        today += 1;
    }
    var e1 = tempReal / @as(f64, @floatFromInt(inTimePeriod));
    tempReal = e1;
    // Calculate E1 for next inTimePeriod-1 values, accumulate for E2 seed
    i = inTimePeriod - 1;
    while (i > 0) : (i -= 1) {
        e1 = (k * prices[today]) + (oneMinusK * e1);
        tempReal += e1;
        today += 1;
    }
    var e2 = tempReal / @as(f64, @floatFromInt(inTimePeriod));
    tempReal = e2;
    // Calculate E2 for next inTimePeriod-1 values, accumulate for E3 seed
    i = inTimePeriod - 1;
    while (i > 0) : (i -= 1) {
        e1 = (k * prices[today]) + (oneMinusK * e1);
        e2 = (k * e1) + (oneMinusK * e2);
        tempReal += e2;
        today += 1;
    }
    var e3 = tempReal / @as(f64, @floatFromInt(inTimePeriod));
    tempReal = e3;
    // Calculate E3 for next inTimePeriod-1 values, accumulate for E4 seed
    i = inTimePeriod - 1;
    while (i > 0) : (i -= 1) {
        e1 = (k * prices[today]) + (oneMinusK * e1);
        e2 = (k * e1) + (oneMinusK * e2);
        e3 = (k * e2) + (oneMinusK * e3);
        tempReal += e3;
        today += 1;
    }
    var e4 = tempReal / @as(f64, @floatFromInt(inTimePeriod));
    tempReal = e4;
    // Calculate E4 for next inTimePeriod-1 values, accumulate for E5 seed
    i = inTimePeriod - 1;
    while (i > 0) : (i -= 1) {
        e1 = (k * prices[today]) + (oneMinusK * e1);
        e2 = (k * e1) + (oneMinusK * e2);
        e3 = (k * e2) + (oneMinusK * e3);
        e4 = (k * e3) + (oneMinusK * e4);
        tempReal += e4;
        today += 1;
    }
    var e5 = tempReal / @as(f64, @floatFromInt(inTimePeriod));
    tempReal = e5;
    // Calculate E5 for next inTimePeriod-1 values, accumulate for E6 seed
    i = inTimePeriod - 1;
    while (i > 0) : (i -= 1) {
        e1 = (k * prices[today]) + (oneMinusK * e1);
        e2 = (k * e1) + (oneMinusK * e2);
        e3 = (k * e2) + (oneMinusK * e3);
        e4 = (k * e3) + (oneMinusK * e4);
        e5 = (k * e4) + (oneMinusK * e5);
        tempReal += e5;
        today += 1;
    }
    var e6 = tempReal / @as(f64, @floatFromInt(inTimePeriod));

    // Advance E1..E6 to the start index
    while (today <= lookbackTotal) : (today += 1) {
        e1 = (k * prices[today]) + (oneMinusK * e1);
        e2 = (k * e1) + (oneMinusK * e2);
        e3 = (k * e2) + (oneMinusK * e3);
        e4 = (k * e3) + (oneMinusK * e4);
        e5 = (k * e4) + (oneMinusK * e5);
        e6 = (k * e5) + (oneMinusK * e6);
    }

    // Calculate T3 coefficients
    const v = inVFactor;
    const v2 = v * v;
    const c1 = -(v2 * v);
    const c2 = 3.0 * (v2 - c1);
    const c3 = -6.0 * v2 - 3.0 * (v - c1);
    const c4 = 1.0 + 3.0 * v - c1 + 3.0 * v2;

    var out_idx = lookbackTotal;
    if (out_idx < outReal.len)
        outReal[out_idx] = c1 * e6 + c2 * e5 + c3 * e4 + c4 * e3;
    out_idx += 1;

    // Main loop: calculate T3 for each price after lookback
    while (today < prices.len) : (today += 1) {
        e1 = (k * prices[today]) + (oneMinusK * e1);
        e2 = (k * e1) + (oneMinusK * e2);
        e3 = (k * e2) + (oneMinusK * e3);
        e4 = (k * e3) + (oneMinusK * e4);
        e5 = (k * e4) + (oneMinusK * e5);
        e6 = (k * e5) + (oneMinusK * e6);
        if (out_idx < outReal.len)
            outReal[out_idx] = c1 * e6 + c2 * e5 + c3 * e4 + c4 * e3;
        out_idx += 1;
    }

    return outReal;
}

test "T3 calculation with valid input" {
    const allocator = std.testing.allocator;
    const prices = [_]f64{
        10,  12,  11,  13,  13,  14,  13,  15,  14,  100,  17, 16, 18, 17, 19,
        1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0,
    };

    const result = try T3(prices[0..], 4, 0.2, allocator);
    defer allocator.free(result);

    try std.testing.expectEqual(result.len, prices.len);
    const expect = [_]f64{ 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 10.798545227, 8.624698573, 7.263307017, 6.583227246, 6.430510258, 6.663624058, 7.167164914 };
    for (expect, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(v, result[i], 1e-9);
    }
}
