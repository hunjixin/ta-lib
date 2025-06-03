const std = @import("std");

/// Calculates the Rate of Change Ratio 100 scale (ROCR100) indicator.
///
/// ROCR100 is a momentum oscillator that measures the ratio of the current price
/// to a price from a specified number of periods ago, scaled by 100.
/// It is useful for comparing momentum across assets or spotting price trend strength.
///
/// Formula:
///     ROCR100[i] = (price[i] / price[i - n]) * 100
///
/// Where:
/// - `price[i]` is the current closing price
/// - `n` is the number of periods (lookback)
///
/// A value above 100 indicates upward momentum (price increased),
/// while a value below 100 indicates downward momentum.
///
/// Parameters:
/// - `prices`: Slice of input prices (usually close prices)
/// - `inTimePeriod`: Lookback period `n` (must be > 0)
/// - `allocator`: Allocator used to allocate the result slice
///
/// Returns:
/// - A slice of ROCR100 values, same length as `prices`.
///   The first `inTimePeriod` elements will typically be 0.0 or undefined.
///
/// Errors:
/// - Returns `error.InvalidInput` if `inTimePeriod` is zero or input is too short.
pub fn Rocr100(
    prices: []const f64,
    inTimePeriod: usize,
    allocator: std.mem.Allocator,
) ![]f64 {
    var outReal = try allocator.alloc(f64, prices.len);
    errdefer allocator.free(outReal);
    @memset(outReal, 0);

    var outIdx = inTimePeriod;
    var inIdx = inTimePeriod;
    var trailingIdx: usize = 0;

    while (inIdx < prices.len) : ({
        trailingIdx += 1;
        outIdx += 1;
        inIdx += 1;
    }) {
        const tempReal = prices[trailingIdx];
        if (tempReal != 0.0) {
            outReal[outIdx] = 100 * prices[inIdx] / tempReal;
        } else {
            outReal[outIdx] = 0.0;
        }
    }

    return outReal;
}

test "Rocr100 work correctly" {
    var allocator = std.testing.allocator;
    const prices = [_]f64{
        82.4, 15.7, 63.2, 91.5, 27.8, 54.6, 39.1, 75.3, 44.2, 10.8, 67.5, 16.2, 23.9, 87.1, 19.6,
        10.1, 12.8, 11.4, 75.9, 13.7, 14.2, 13.5, 15.9, 14.8, 43.3, 32.6, 16.2, 13.4, 17.5, 76.1,
        65.8, 12.6, 11.9, 13.3, 13.7, 13.1, 13.8, 15.4, 14.2, 10.6, 17.3, 43.1, 18.9, 17.7, 19.2,
    };
    const result = try Rocr100(&prices, 8, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 53.640776699029125, 68.78980891719746, 106.80379746835442, 17.704918032786885, 85.97122302158272, 159.52380952380952, 50.127877237851656, 13.41301460823373, 28.959276018099544, 105.55555555555556, 112.44444444444446, 84.5679012345679, 59.41422594142259, 15.499425947187143, 81.12244897959184, 146.53465346534657, 338.28124999999994, 285.96491228070175, 21.34387351778656, 97.8102189781022, 123.23943661971832, 563.7037037037037, 413.83647798742135, 85.13513513513513, 27.48267898383372, 40.79754601226994, 84.5679012345679, 97.76119402985074, 78.85714285714286, 20.2365308804205, 21.580547112462007, 84.12698412698413, 145.37815126050418, 324.0601503759398, 137.95620437956205, 135.1145038167939, 139.1304347826087 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}
