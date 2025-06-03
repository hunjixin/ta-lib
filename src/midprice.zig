const std = @import("std");
const MyError = @import("./lib.zig").MyError;

/// Calculates the MidPrice indicator over a given period for a DataFrame of f64 values.
///
/// The MidPrice indicator is defined as the average of the highest high and the lowest low
/// over the specified period:
///     MidPrice = (HighestHigh(period) + LowestLow(period)) / 2
///
/// - `inHigh`: The high price of the asset.
/// - `inLow`: The low price of the asset.
/// - `period`: The lookback period for calculating the highest high and lowest low.
/// - `allocator`: Allocator used for the result array.
///
/// Returns an array of f64 values representing the MidPrice for each period window.
///
/// Errors if memory allocation fails or if the input is invalid.
pub fn MidPrice(inHigh: []const f64, inLow: []const f64, period: usize, allocator: std.mem.Allocator) ![]f64 {
    const len = inHigh.len;
    var out = try allocator.alloc(f64, len);
    errdefer allocator.free(out);
    @memset(out, 0);
    const loopback = period - 1;

    for (loopback..len) |i| {
        var min: f64 = inLow[i + 1 - period];
        var max: f64 = inHigh[i + 1 - period];
        for (i + 2 - period..i + 1) |j| {
            min = @min(min, inLow[j]);
            max = @max(max, inHigh[j]);
        }
        out[i] = (max + min) / 2.0;
    }
    return out;
}

test "MidPrice calculation with valid input" {
    const allocator = std.testing.allocator;

    const highs = [_]f64{ 10, 12, 11, 13, 13, 14, 13, 15, 14, 100, 17, 16, 18, 17, 19 };
    const lows = [_]f64{ 8, 9, 9, 10, 12, 12, 12, 13, 13, 14, 100, 15, 16, 16, 17 };

    const result = try MidPrice(&highs, &lows, 4, allocator);
    defer allocator.free(result);

    try std.testing.expectEqual(result.len, highs.len);
    const expect = [_]f64{ 0.000000, 0.000000, 0.000000, 10.500000, 11.000000, 11.500000, 12.000000, 13.500000, 13.500000, 56.000000, 56.500000, 56.500000, 57.000000, 16.500000, 17.000000 };
    for (expect, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(v, result[i], 1e-9);
    }
}
