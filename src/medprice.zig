const std = @import("std");

/// Computes the Median Price for each data point in a time series.
///
/// Median Price is a simple technical indicator used in financial analysis,
/// defined as the average of the high and low prices for a given period.
/// It is often used as a base price for other indicators such as Bollinger Bands or envelopes.
///
/// # Formula:
///     Median Price = (High + Low) / 2
///
/// # Parameters:
/// - `inHigh`: An array of high prices.
/// - `inLow`: An array of low prices.
/// - `allocator`: Memory allocator to allocate the result array.
///
/// # Returns:
/// - An array of median prices, same length as input arrays.
///
/// # Errors:
/// - Returns an error if allocation fails or if input lengths do not match.
///
/// # Example:
/// ```zig
/// const highs = [_]f64{ 110.0, 120.0, 130.0 };
/// const lows = [_]f64{ 100.0, 115.0, 125.0 };
/// const result = try MedPrice(highs[0..], lows[0..], allocator);
/// // result = [105.0, 117.5, 127.5]
/// ```
pub fn MedPrice(inHigh: []const f64, inLow: []const f64, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inHigh.len);
    errdefer allocator.free(outReal);
    @memset(outReal, 0.0);

    for (0..inHigh.len) |i| {
        outReal[i] = (inHigh[i] + inLow[i]) / 2;
    }
    return outReal;
}

test "MedPrice computes average price correctly" {
    var allocator = std.testing.allocator;

    const high = [_]f64{ 15.0, 25.0, 35.0 };
    const low = [_]f64{ 5.0, 18.0, 28.0 };

    const result = try MedPrice(&high, &low, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 10, 21.5, 31.5 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}
