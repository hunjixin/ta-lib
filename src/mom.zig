const std = @import("std");
const MyError = @import("./lib.zig").MyError;

pub fn Mom(prices: []const f64, period: usize, allocator: std.mem.Allocator) ![]f64 {
    var out = try allocator.alloc(f64, prices.len);
    @memset(out, 0);
    if (prices.len < period) {
        return out;
    }

    for (period..prices.len) |i| {
        out[i] = prices[i] - prices[i - period];
    }
    return out;
}

test "Mom work correctly" {
    var allocator = std.testing.allocator;
    const prices = [_]f64{ 10, 12, 11, 13, 13, 14, 13, 15, 14, 100, 17, 16, 18, 17, 19 };
    const period = 5;
    const result = try Mom(&prices, period, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 0, 0, 0, 0, 0, 4, 1, 4, 1, 87, 3, 3, 3, 3, -81 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}
