const std = @import("std");
const MyError = @import("./lib.zig").MyError;


/// Calculates the midpoint value over a specified period for a given array of prices.
/// 
/// The midpoint is computed as the average of the highest and lowest values within each moving window of the specified period.
/// 
/// Formula:
///     MidPoint = (HighestHigh(period) + LowestLow(period)) / 2
///
/// - `prices`: Slice of input price values (e.g., closing prices).
/// - `period`: The number of periods to use for the moving window.
/// - `allocator`: Allocator used for the result array.
///
/// Returns a newly allocated array of midpoint values, or an error if allocation fails.
pub fn MidPoint(prices: []const f64, period: usize, allocator: std.mem.Allocator) ![]f64 {
    var out = try allocator.alloc(f64, prices.len);
    @memset(out, 0);

    const loopback = period - 1;

    for (loopback..prices.len) |i| {
        var min: f64 = prices[i + 1 - period];
        var max: f64 = prices[i + 1 - period];
        for(i + 2 - period..i+1)|j|{
            min = @min(min, prices[j]);
            max = @max(max, prices[j]);
        }
        out[i] = (max + min) / 2.0;
    }
    return out;
}

test "MidPoint calculation with valid input" {
    const allocator = std.testing.allocator;

    const prices = [_]f64{ 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0 };
    const period = 4;

    const result = try MidPoint(prices[0..], period, allocator);
    defer allocator.free(result);

    try std.testing.expectEqual(result.len, prices.len);
    const expect = [_]f64{ 0,0,0,2.5,3.5,4.5,5.5,6.5,7.5,8.5 };
    for (expect, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(v, result[i], 1e-9);
    }
}