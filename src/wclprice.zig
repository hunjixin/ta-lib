const std = @import("std");

/// Calculates the Weighted Close Price (WCLPRICE) for each price bar.
///
/// The Weighted Close Price provides a more balanced average of price action
/// by placing more weight on the closing price, which is often considered the
/// most important price in a trading session.
///
/// **Formula:**
/// ```text
/// Weighted Close Price = (High + Low + Close * 2) / 4
/// ```
///
/// **Parameters:**
/// - `inHigh`: Array of high prices
/// - `inLow`: Array of low prices
/// - `inClose`: Array of close prices
/// - `allocator`: Memory allocator used to allocate the result array
///
/// **Returns:**
/// - An array of f64 values, each representing the Weighted Close Price
///   for the corresponding input bar.
///
/// Example:
/// ```text
/// High:   [10.0, 12.0]
/// Low:    [ 9.0, 11.0]
/// Close:  [ 9.5, 11.5]
/// Output: [(10+9+9.5*2)/4, (12+11+11.5*2)/4] = [9.75, 11.5]
/// ```
pub fn WclPrice(inHigh: []const f64, inLow: []const f64, inClose: []const f64, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inHigh.len);
    errdefer allocator.free(outReal);
    @memset(outReal, 0.0);

    for (0..inHigh.len) |i| {
        outReal[i] = (inHigh[i] + inLow[i] + inClose[i] * 2) / 4;
    }
    return outReal;
}

test "WclPrice computes average price correctly" {
    var allocator = std.testing.allocator;

    const high = [_]f64{ 15.0, 25.0, 35.0 };
    const low = [_]f64{ 5.0, 18.0, 28.0 };
    const close = [_]f64{ 12.0, 22.0, 32.0 };

    const result = try WclPrice(&high, &low, &close, allocator);
    defer allocator.free(result);

    const expected = [_]f64{
        11,
        21.75,
        31.75,
    };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}
