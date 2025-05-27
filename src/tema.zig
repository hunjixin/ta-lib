const std = @import("std");
const MyError = @import("./lib.zig").MyError;
const EMA = @import("./lib.zig").EMA;

/// Calculates the Triple Exponential Moving Average (TEMA) for a given array of prices.
///
/// TEMA is a technical analysis indicator that smooths price data by applying the exponential moving average (EMA) three times.
/// The formula for TEMA is:
///     TEMA = 3 * EMA1 - 3 * EMA2 + EMA3
/// where:
///     EMA1 = EMA(prices, period)
///     EMA2 = EMA(EMA1, period)
///     EMA3 = EMA(EMA2, period)
///
/// Parameters:
/// - prices: Array of input price values (e.g., closing prices).
/// - period: The number of periods to use for the EMA calculations.
/// - allocator: Memory allocator for the result array.
///
/// Returns:
/// - An array of TEMA values corresponding to the input prices.
///
/// Errors:
/// - Returns an error if memory allocation fails or if the input parameters are invalid.
pub fn TEMA(prices: []const f64, period: usize, allocator: std.mem.Allocator) ![]f64 {
    if (period == 0 or prices.len < period * 3 - 2) {
        return error.MyError;
    }

    const firstEMA = try EMA(prices, period, allocator);
    defer allocator.free(firstEMA);

    const secondEMA = try EMA(firstEMA[(period - 1)..], period, allocator);
    defer allocator.free(secondEMA);

    const thirdEMA = try EMA(secondEMA[(period - 1)..], period, allocator);
    defer allocator.free(thirdEMA);

    const out_len = prices.len;
    var outReal = try allocator.alloc(f64, out_len);
    @memset(outReal, 0);

    const outIdx: usize = period * 3 - 3;
    var secondEMAIdx: usize = period * 2 - 2;
    var thirdEMAIdx: usize = period - 1;

    var i = outIdx;
    while (i < out_len) : (i += 1) {
        outReal[i] = thirdEMA[thirdEMAIdx] + (3.0 * firstEMA[i]) - (3.0 * secondEMA[secondEMAIdx]);
        secondEMAIdx += 1;
        thirdEMAIdx += 1;
    }

    return outReal;
}

test "TEMA calculation with valid input" {
    const allocator = std.testing.allocator;
    const prices = [_]f64{
        10,  12,  11,  13,  13,  14,  13,  15,  14,  100,  17, 16, 18, 17, 19,
        1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0,
    };

    const result = try TEMA(prices[0..], 4, allocator);
    defer allocator.free(result);

    try std.testing.expectEqual(result.len, prices.len);
    const expect = [_]f64{
        0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 79.504179200, 37.435748864, 20.040841830, 15.839809229, 14.457669190, 16.333632410, 3.447654406, 0.312311473, 0.846758494, 2.475562250, 4.216972154, 5.771842482, 7.105707988, 8.267550483, 9.318144218, 10.306537996,
    };
    for (expect, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(v, result[i], 1e-9);
    }
}
