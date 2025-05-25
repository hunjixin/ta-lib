const std = @import("std");
const DataFrame = @import("./lib.zig").DataFrame;
const VAR = @import("./lib.zig").VAR;

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
///
pub fn StdDev(prices: []const f64, period: usize, inNbDev: f64, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try VAR(prices, period, allocator);
    if (!std.math.approxEqAbs(f64, inNbDev, 1.0, 1e-9)) {
        for (0..prices.len) |i| {
            const tempReal = outReal[i];
            if (!(tempReal < 0.00000000000001)) {
                outReal[i] = @sqrt(tempReal) * inNbDev;
            } else {
                outReal[i] = 0.0;
            }
        }
    } else {
        for (0..prices.len) |i| {
            const tempReal = outReal[i];
            if (!(tempReal < 0.00000000000001)) {
                outReal[i] = @sqrt(tempReal);
            } else {
                outReal[i] = 0.0;
            }
        }
    }
    return outReal;
}

test "StdDev work correctly" {
    const allocator = std.testing.allocator;

    const prices = [_]f64{ 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0 };
    const period = 5;

    {
        const result = try StdDev(prices[0..], period, 1, allocator);
        defer allocator.free(result);

        try std.testing.expectEqual(result.len, prices.len);
        const expect = [_]f64{ 0, 0, 0, 0, 1.4142135623730951, 1.4142135623730951, 1.4142135623730951, 1.4142135623730951, 1.4142135623730951, 1.4142135623730951 };

        for (expect, 0..) |v, i| {
            try std.testing.expectApproxEqAbs(v, result[i], 1e-9);
        }
    }

    {
        const result = try StdDev(prices[0..], period, 2, allocator);
        defer allocator.free(result);
        std.debug.print("{any}", .{result});
        try std.testing.expectEqual(result.len, prices.len);
        const expect = [_]f64{ 0, 0, 0, 0, 2.8284271247461903, 2.8284271247461903, 2.8284271247461903, 2.8284271247461903, 2.8284271247461903, 2.8284271247461903 };
        for (expect, 0..) |v, i| {
            try std.testing.expectApproxEqAbs(v, result[i], 1e-9);
        }
    }
}
