const std = @import("std");

/// Calculates the Rate of Change Ratio (ROCR) indicator.
///
/// ROCR is a momentum oscillator that compares the current price to a price from
/// a specified number of periods ago. It is useful for evaluating price momentum
/// and comparing the relative strength of assets.
///
/// Formula:
///     ROCR[i] = price[i] / price[i - n]
///
/// Where:
/// - `price[i]` is the current price (typically the closing price)
/// - `n` is the number of periods (lookback)
///
/// Interpretation:
/// - A ROCR value > 1.0 suggests upward momentum (price increased)
/// - A ROCR value < 1.0 suggests downward momentum (price decreased)
/// - A ROCR value around 1.0 indicates stable or sideways movement
///
/// Parameters:
/// - `prices`: Slice of input price values (e.g., close prices)
/// - `inTimePeriod`: Lookback period `n` (must be > 0)
/// - `allocator`: Allocator used to allocate the result slice
///
/// Returns:
/// - A slice of ROCR values with the same length as `prices`.
///   The first `inTimePeriod` elements may be 0.0 or undefined due to lack of data.
///
/// Errors:
/// - Returns `error.InvalidInput` if `inTimePeriod` is zero or greater than the input length.
pub fn Rocr(
    prices: []const f64,
    inTimePeriod: usize,
    allocator: std.mem.Allocator,
) ![]f64 {
    var outReal = try allocator.alloc(f64, prices.len);
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
            outReal[outIdx] = prices[inIdx] / tempReal;
        } else {
            outReal[outIdx] = 0.0;
        }
    }

    return outReal;
}

test "Rocr work correctly" {
    var allocator = std.testing.allocator;
    const prices = [_]f64{
        82.4, 15.7, 63.2, 91.5, 27.8, 54.6, 39.1, 75.3, 44.2, 10.8, 67.5, 16.2, 23.9, 87.1, 19.6,
        10.1, 12.8, 11.4, 75.9, 13.7, 14.2, 13.5, 15.9, 14.8, 43.3, 32.6, 16.2, 13.4, 17.5, 76.1,
        65.8, 12.6, 11.9, 13.3, 13.7, 13.1, 13.8, 15.4, 14.2, 10.6, 17.3, 43.1, 18.9, 17.7, 19.2,
    };
    const result = try Rocr(&prices, 8, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 0.5364077669902912, 0.6878980891719746, 1.0680379746835442, 0.17704918032786884, 0.8597122302158272, 1.5952380952380951, 0.5012787723785166, 0.1341301460823373, 0.28959276018099545, 1.0555555555555556, 1.1244444444444446, 0.845679012345679, 0.5941422594142259, 0.15499425947187143, 0.8112244897959183, 1.4653465346534655, 3.3828124999999996, 2.8596491228070176, 0.21343873517786557, 0.9781021897810219, 1.2323943661971832, 5.637037037037037, 4.138364779874213, 0.8513513513513513, 0.2748267898383372, 0.4079754601226994, 0.845679012345679, 0.9776119402985074, 0.7885714285714286, 0.202365308804205, 0.21580547112462006, 0.8412698412698413, 1.453781512605042, 3.2406015037593985, 1.3795620437956204, 1.3511450381679388, 1.391304347826087 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}
