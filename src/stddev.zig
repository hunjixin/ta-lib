const std = @import("std");
const DataFrame = @import("./lib.zig").DataFrame;
const VAR = @import("./lib.zig").VAR;

/// Calculates the standard deviation of a given slice of prices over a specified period.
///
/// The standard deviation is a statistical measure of volatility, representing how much the values deviate from the mean.
/// Formula:
///     stddev = sqrt(sum((x_i - mean)^2) / period) * inNbDev
///
/// Parameters:
/// - prices: Slice of input price data (e.g., closing prices).
/// - period: Number of periods to use for the moving window calculation.
/// - inNbDev: The number of standard deviations to multiply the result by (commonly 1.0 or 2.0).
/// - allocator: Allocator used for memory allocation of the result.
///
/// Returns:
/// - A slice of f64 values representing the calculated standard deviation for each period.
///
/// Errors:
/// - Returns an error if memory allocation fails or if input parameters are invalid.
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
        try std.testing.expectEqual(result.len, prices.len);
        const expect = [_]f64{ 0, 0, 0, 0, 2.8284271247461903, 2.8284271247461903, 2.8284271247461903, 2.8284271247461903, 2.8284271247461903, 2.8284271247461903 };
        for (expect, 0..) |v, i| {
            try std.testing.expectApproxEqAbs(v, result[i], 1e-9);
        }
    }
}
