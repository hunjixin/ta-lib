const std = @import("std");
const DataFrame = @import("./lib.zig").DataFrame;

/// Calculates the Simple Moving Average (SMA) for a given price array and period.
///
/// Formula:
///     SMA_t = (P_{t} + P_{t-1} + ... + P_{t-period+1}) / period
/// where:
///     - SMA_t: the simple moving average at time t
///     - P_{t}: the price at time t
///     - period: the number of periods to average
///
/// Parameters:
/// - prices: array of price data (input)
/// - period: the window size for the moving average
/// - allocator: memory allocator for the output array
///
/// Returns:
/// - Array of SMA values (length equals prices.len)
///
/// Note:
/// - For indices less than period-1, the output will be zero (not enough data to compute SMA).
pub fn SMA(prices: []const f64, period: usize, allocator: std.mem.Allocator) ![]f64 {
    var out = try allocator.alloc(f64, prices.len);
    @memset(out, 0);
    var da: f64 = 0.0;
    const dived: f64 = @floatFromInt(period);

    for (0..prices.len) |i| {
        if (i < period - 1) {
            da += prices[i];
        } else {
            da += prices[i];
            out[i] = da / dived;
            da -= prices[i + 1 - period];
        }
    }
    return out;
}

test "SMA computes simple moving average correctly" {
    const allocator = std.testing.allocator;

    // Test data: prices and period
    const prices = [_]f64{ 1.0, 2.0, 3.0, 4.0, 5.0 };
    const period = 3;

    const result = try SMA(&prices, period, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 0, 0, 2, 3, 4 };
    for (expected, 0..) |exp, i| {
        try std.testing.expectApproxEqAbs(result[i], exp, 1e-9);
    }
}
