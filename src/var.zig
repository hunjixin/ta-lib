const std = @import("std");

/// Calculates the variance of the given `prices` over a specified `period`.
///
/// The variance is a statistical measure of the dispersion of price values,
/// defined by the formula:
///
///     VAR = (1/N) * Σ (price_i - mean)^2
///
/// where N is the period, price_i is each price in the period, and mean is the average price over the period.
///
/// Parameters:
/// - `prices`: Slice of input price values (f64).
/// - `period`: The number of periods to use for the variance calculation.
/// - `allocator`: Allocator used for the result array.
///
/// Returns:
/// - A newly allocated slice of f64 containing the variance values for each period.
///
/// Errors:
/// - Returns an error if allocation fails or if the input is invalid.
pub fn VAR(prices: []const f64, period: usize, allocator: std.mem.Allocator) ![]f64 {
    var out = try allocator.alloc(f64, prices.len);
    @memset(out, 0);

    if (period == 0 or prices.len < period) return out;

    const periodF: f64 = @floatFromInt(period);
    var period_total1: f64 = 0;
    var period_total2: f64 = 0;
    const nb_initial_needed = period - 1;
    var i: usize = 0;

    // Pre-calculate sums for the first window (except last element)
    if (period > 1) {
        while (i < nb_initial_needed) : (i += 1) {
            const temp = prices[i];
            period_total1 += temp;
            period_total2 += temp * temp;
        }
    }

    var out_idx = nb_initial_needed;
    var trailing_idx: usize = 0;
    i = nb_initial_needed;
    while (i < prices.len) : (i += 1) {
        const temp = prices[i];
        period_total1 += temp;
        period_total2 += temp * temp;

        const mean1 = period_total1 / periodF;
        const mean2 = period_total2 / periodF;
        out[out_idx] = mean2 - mean1 * mean1;

        const trailing = prices[trailing_idx];
        period_total1 -= trailing;
        period_total2 -= trailing * trailing;

        trailing_idx += 1;
        out_idx += 1;
    }

    return out;
}

test "VAR work correctly" {
    const allocator = std.testing.allocator;

    const prices = [_]f64{ 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0 };
    const period = 5;

    const result = try VAR(prices[0..], period, allocator);
    defer allocator.free(result);

    try std.testing.expectEqual(result.len, prices.len);
    const expect = [_]f64{ 0, 0, 0, 0, 2, 2, 2, 2, 2, 2 };
    for (expect, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(v, result[i], 1e-9);
    }
}
