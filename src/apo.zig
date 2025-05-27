const std = @import("std");
const MA = @import("./lib.zig").MA;
const MaType = @import("./lib.zig").MaType;

/// Calculates the Absolute Price Oscillator (APO) for a given price series.
///
/// The Absolute Price Oscillator is defined as the difference between two moving averages
/// of a security's price, typically a fast (shorter period) and a slow (longer period) moving average:
///
///     APO = MA_fast(prices, inFastPeriod) - MA_slow(prices, inSlowPeriod)
///
/// # Parameters
/// - `prices`: Slice of input price data (usually closing prices).
/// - `inFastPeriod`: The period for the fast (short-term) moving average.
/// - `inSlowPeriod`: The period for the slow (long-term) moving average.
/// - `inMAType`: The type of moving average to use (e.g., simple, exponential).
/// - `allocator`: Allocator used for result memory allocation.
///
/// # Returns
/// Returns a slice of f64 values representing the APO for each input price, or an error if allocation fails.
///
/// # Formula
/// ```text
/// APO[i] = MA_fast(prices, inFastPeriod)[i] - MA_slow(prices, inSlowPeriod)[i]
/// ```
///
/// # Reference
/// - [Absolute Price Oscillator (APO) - Investopedia](https://www.investopedia.com/terms/a/absolute-price-oscillator.asp)
pub fn APO(prices: []const f64, inFastPeriod: usize, inSlowPeriod: usize, inMAType: MaType, allocator: std.mem.Allocator) ![]f64 {
    var fastPeriod = inFastPeriod;
    var slowPeriod = inSlowPeriod;
    if (slowPeriod < fastPeriod) {
        std.mem.swap(usize, &slowPeriod, &fastPeriod);
    }
    const tempBuffer = try MA(prices, fastPeriod, inMAType, allocator);
    defer allocator.free(tempBuffer);

    const outReal = try MA(prices, slowPeriod, inMAType, allocator);
    for (slowPeriod - 1..prices.len) |i| {
        outReal[i] = tempBuffer[i] - outReal[i];
    }
    return outReal;
}

test "APO computes correctly" {
    const allocator = std.testing.allocator;
    const prices = [_]f64{
        82.4, 15.7, 63.2, 91.5, 27.8, 54.6, 39.1, 75.3, 44.2, 10.8, 67.5, 16.2, 23.9, 87.1, 19.6,
        10.1, 12.8, 11.4, 75.9, 13.7, 14.2, 13.5, 15.9, 14.8, 43.3, 32.6, 16.2, 13.4, 17.5, 76.1,
    };

    const result = try APO(&prices, 5, 8, MaType.SMA, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 1.460000000, -3.225000000, -6.012500000, -3.970000000, 0.862500000, -8.930000000, -4.412500000, -0.215000000, -3.545000000, -0.300000000, -2.875000000, -6.165000000, -7.032500000, -5.000000000, 4.340000000, 5.702500000, -7.105000000, -4.997500000, -3.967500000, 4.035000000, 3.572500000, 3.700000000, 2.435000000 };
    for (expected, 0..) |exp, i| {
        try std.testing.expectApproxEqAbs(exp, result[i], 1e-9);
    }
}
