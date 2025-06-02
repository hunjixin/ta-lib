const std = @import("std");

/// Calculates the Typical Price for each time period.
///
/// Typical Price is a technical indicator that provides a simple average of the
/// high, low, and close prices for a given time period. It is commonly used as a base
/// for other indicators such as Cci (Commodity Channel Index) and Bollinger Bands.
///
/// # Formula:
///     Typical Price = (High + Low + Close) / 3
///
/// # Parameters:
/// - `inHigh`: A slice of high prices for each time period.
/// - `inLow`: A slice of low prices for each time period.
/// - `inClose`: A slice of close prices for each time period.
/// - `allocator`: The memory allocator used to allocate the output array.
///
/// # Returns:
/// - A dynamically allocated array of typical prices for each input time period.
///
/// # Errors:
/// - Returns an error if the input slices are not the same length.
/// - Returns an error if allocation fails.
///
/// # Example:
/// ```zig
/// const high = [_]f64{ 120.0, 121.0, 119.0 };
/// const low = [_]f64{ 115.0, 116.0, 114.0 };
/// const close = [_]f64{ 118.0, 119.0, 117.0 };
/// const result = try TypPrice(high[0..], low[0..], close[0..], allocator);
/// // result = [117.67, 118.67, 116.67]
/// ```
pub fn TypPrice(inHigh: []const f64, inLow: []const f64, inClose: []const f64, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inHigh.len);
    errdefer allocator.free(outReal);
    @memset(outReal, 0.0);

    for (0..inHigh.len) |i| {
        outReal[i] = (inHigh[i] + inLow[i] + inClose[i]) / 3;
    }
    return outReal;
}

test "TypPrice computes average price correctly" {
    var allocator = std.testing.allocator;

    const high = [_]f64{ 15.0, 25.0, 35.0 };
    const low = [_]f64{ 5.0, 18.0, 28.0 };
    const close = [_]f64{ 12.0, 22.0, 32.0 };

    const result = try TypPrice(&high, &low, &close, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 10.666666666666666, 21.666666666666668, 31.666666666666668 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}
