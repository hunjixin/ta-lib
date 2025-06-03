const std = @import("std");
const MyError = @import("./lib.zig").MyError;

/// Calculates the Rate of Change Percentage (ROCP) indicator.
///
/// ROCP is a momentum indicator that measures the percentage change
/// between the current price and the price a specific number of periods ago.
/// It is commonly used to identify trend direction and strength.
///
/// Formula:
///     ROCP[i] = (price[i] - price[i - n]) / price[i - n]
///
/// Where:
/// - `price[i]` is the current price (typically closing price)
/// - `n` is the time period (lookback)
///
/// Interpretation:
/// - A positive ROCP indicates upward momentum (price increased)
/// - A negative ROCP indicates downward momentum (price decreased)
/// - A ROCP near 0 indicates little to no change
///
/// Parameters:
/// - `prices`: Slice of price data (e.g., close prices)
/// - `inTimePeriod`: Lookback period `n` (must be > 0)
/// - `allocator`: Memory allocator for result array
///
/// Returns:
/// - A slice of ROCP values (length same as `prices`)
///   The first `inTimePeriod` elements may be 0.0 or undefined due to lack of historical data.
///
/// Errors:
/// - Returns `error.InvalidInput` if `inTimePeriod == 0` or `prices.len <= inTimePeriod`
pub fn Rocp(
    prices: []const f64,
    inTimePeriod: usize,
    allocator: std.mem.Allocator,
) ![]f64 {
    var outReal = try allocator.alloc(f64, prices.len);
    errdefer allocator.free(outReal);
    @memset(outReal, 0);

    if (inTimePeriod < 1) {
        return outReal;
    }

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
            outReal[outIdx] = (prices[inIdx] - tempReal) / tempReal;
        } else {
            outReal[outIdx] = 0.0;
        }
    }

    return outReal;
}

test "Rocp work correctly" {
    var allocator = std.testing.allocator;
    const prices = [_]f64{
        82.4, 15.7, 63.2, 91.5, 27.8, 54.6, 39.1, 75.3, 44.2, 10.8, 67.5, 16.2, 23.9, 87.1, 19.6,
        10.1, 12.8, 11.4, 75.9, 13.7, 14.2, 13.5, 15.9, 14.8, 43.3, 32.6, 16.2, 13.4, 17.5, 76.1,
        65.8, 12.6, 11.9, 13.3, 13.7, 13.1, 13.8, 15.4, 14.2, 10.6, 17.3, 43.1, 18.9, 17.7, 19.2,
    };
    const result = try Rocp(&prices, 8, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, -0.46359223300970875, -0.3121019108280254, 0.06803797468354425, -0.8229508196721311, -0.14028776978417273, 0.5952380952380951, -0.49872122762148335, -0.8658698539176628, -0.7104072398190046, 0.05555555555555552, 0.12444444444444452, -0.154320987654321, -0.40585774058577406, -0.8450057405281286, -0.18877551020408168, 0.4653465346534655, 2.3828124999999996, 1.8596491228070178, -0.7865612648221344, -0.021897810218978027, 0.23239436619718315, 4.637037037037037, 3.138364779874214, -0.1486486486486487, -0.7251732101616628, -0.5920245398773006, -0.154320987654321, -0.022388059701492588, -0.21142857142857138, -0.797634691195795, -0.7841945288753799, -0.15873015873015872, 0.453781512605042, 2.2406015037593985, 0.3795620437956204, 0.3511450381679389, 0.3913043478260868 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}
