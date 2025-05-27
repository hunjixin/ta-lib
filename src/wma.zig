const std = @import("std");
const MyError = @import("./lib.zig").MyError;

/// Calculates the Weighted Moving Average (WMA) for a given array of prices.
///
/// The WMA assigns more weight to recent prices, making it more responsive to new information
/// compared to the Simple Moving Average (SMA).
///
/// Formula:
///   WMA = (P1 * W1 + P2 * W2 + ... + Pn * Wn) / (W1 + W2 + ... + Wn)
///   where:
///     - Pn is the price at position n
///     - Wn is the weight for position n (typically, Wn = n for the most recent price)
///
/// Parameters:
///   prices   - Slice of input price data (array of f64).
///   period   - The number of periods to use for the moving average.
///   allocator - Allocator to use for the result array.
///
/// Returns:
///   Allocated array of f64 containing the WMA values.
///
/// Errors:
///   Returns an error if allocation fails or if the input is invalid.
pub fn WMA(prices: []const f64, period: usize, allocator: std.mem.Allocator) ![]f64 {
    const len = prices.len;
    var out = try allocator.alloc(f64, len);
    @memset(out, 0);

    if (period == 1) {
        @memcpy(out, prices);
        return out;
    }

    const divider = (period * (period + 1)) >> 1;
    var out_idx: usize = period - 1;
    var trailing_idx: usize = 0;
    var period_sum: f64 = 0.0;
    var period_sub: f64 = 0.0;
    var in_idx: usize = 0;
    var i: usize = 1;

    while (in_idx < period - 1) {
        const temp_real = prices[in_idx];
        period_sub += temp_real;
        period_sum += temp_real * @as(f64, @floatFromInt(i));
        in_idx += 1;
        i += 1;
    }

    var trailing_value: f64 = 0.0;
    while (in_idx < prices.len) {
        const temp_real = prices[in_idx];
        period_sub += temp_real;
        period_sub -= trailing_value;
        period_sum += temp_real * @as(f64, @floatFromInt(period));
        trailing_value = prices[trailing_idx];
        out[out_idx] = period_sum / @as(f64, @floatFromInt(divider));
        period_sum -= period_sub;
        in_idx += 1;
        trailing_idx += 1;
        out_idx += 1;
    }
    return out;
}

test "Wma work correctly" {
    var allocator = std.testing.allocator;
    const prices = [_]f64{
        82.4, 15.7, 63.2, 91.5, 27.8, 54.6, 39.1, 75.3, 44.2, 10.8, 67.5, 16.2, 23.9, 87.1, 19.6,
        10.1, 12.8, 11.4, 75.9, 13.7, 14.2, 13.5, 15.9, 14.8, 43.3, 32.6, 16.2, 13.4, 17.5, 76.1,
    };

    const result = try WMA(&prices, 5, allocator);
    defer allocator.free(result);

    const expected = [_]f64{
        0.000000000, 0.000000000, 0.000000000, 0.000000000, 53.893333333, 53.386666667, 49.566666667, 56.253333333, 51.766666667, 39.300000000, 46.866666667, 36.473333333, 30.173333333, 48.366666667, 41.200000000, 30.280000000, 24.086666667, 17.653333333, 33.553333333, 29.466666667, 25.940000000, 21.906666667, 18.626666667, 14.680000000, 24.306666667, 28.393333333, 25.786666667, 22.066666667, 19.880000000, 37.046666667,
    };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}
