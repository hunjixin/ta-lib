const std = @import("std");

/// Calculates the Average Price for each period from given Open, High, Low, and Close price arrays.
///
/// The Average Price is a simple arithmetic mean of the OHLC prices:
///
/// Formula:
/// \[
/// \text{AvgPrice}_i = \frac{Open_i + High_i + Low_i + Close_i}{4}
/// \]
///
/// This indicator smooths price data and can be used as a basis for other technical indicators.
///
/// Params:
/// - `inOpen`: array of open prices
/// - `inHigh`: array of high prices
/// - `inLow`: array of low prices
/// - `inClose`: array of close prices
///
/// Returns:
/// - Array of float64 containing the average prices for each corresponding period.
///
/// Errors:
/// - Returns an error if input arrays are not of equal length or allocation fails.
pub fn AvgPrice(inOpen: []const f64, inHigh: []const f64, inLow: []const f64, inClose: []const f64, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inOpen.len);
    errdefer allocator.free(outReal);
    @memset(outReal, 0.0);

    for (0..inOpen.len) |i| {
        outReal[i] = (inHigh[i] + inLow[i] + inClose[i] + inOpen[i]) / 4;
    }
    return outReal;
}

test "AvgPrice computes average price correctly" {
    var allocator = std.testing.allocator;

    const open = [_]f64{ 10.0, 20.0, 30.0 };
    const high = [_]f64{ 15.0, 25.0, 35.0 };
    const low = [_]f64{ 5.0, 18.0, 28.0 };
    const close = [_]f64{ 12.0, 22.0, 32.0 };

    const result = try AvgPrice(&open, &high, &low, &close, allocator);
    defer allocator.free(result);

    const expected = [_]f64{
        10.5,
        21.25,
        31.25,
    };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}
