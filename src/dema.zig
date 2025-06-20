const std = @import("std");
const MyError = @import("./lib.zig").MyError;
const Ema = @import("./lib.zig").Ema;

/// Calculates the Double Exponential Moving Average (Dema) for a given array of prices.
///
/// The Dema is a technical indicator that aims to reduce the lag of traditional moving averages.
/// It is calculated using the formula:
///     Dema = 2 * Ema(prices, period) - Ema(Ema(prices, period), period)
///
/// Parameters:
/// - prices: The input slice of price data (e.g., closing prices).
/// - period: The number of periods to use for the moving average calculation.
/// - allocator: The allocator to use for allocating the result array.
///
/// Returns:
/// - An array of f64 values representing the Dema for the input prices.
///
/// Errors:
/// - Returns an error if memory allocation fails or if the input is invalid.
pub fn Dema(prices: []const f64, period: usize, allocator: std.mem.Allocator) ![]f64 {
    var out = try allocator.alloc(f64, prices.len);
    errdefer allocator.free(out);
    @memset(out, 0);

    const firstEMA = try Ema(prices, period, allocator);
    defer allocator.free(firstEMA);

    const secondEMA = try Ema(firstEMA[period - 1 ..], period, allocator);
    defer allocator.free(secondEMA);

    for (2 * period - 2..prices.len) |i| {
        out[i] = 2 * firstEMA[i] - secondEMA[i + 1 - period];
    }
    return out;
}

test "Dema computes correctly" {
    const allocator = std.testing.allocator;

    // Test data: prices and period
    const prices = [_]f64{ 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0 };
    const period = 5;

    const result = try Dema(&prices, period, allocator);
    defer allocator.free(result);

    const expected = [_]f64{
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        9,
        10,
    };
    for (expected, 0..) |exp, i| {
        try std.testing.expectApproxEqAbs(exp, result[i], 1e-9);
    }
}
