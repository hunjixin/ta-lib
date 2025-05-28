const std = @import("std");
const DataFrame = @import("./lib.zig").DataFrame;
const EMA = @import("./lib.zig").EMA;
const Roc = @import("./lib.zig").Roc;

pub fn Trix(prices: []const f64, inTimePeriod: usize, allocator: std.mem.Allocator) ![]f64 {
    const tmpReal = try EMA(prices, inTimePeriod, allocator);
    defer allocator.free(tmpReal);
    const tmpReal2 = try EMA(tmpReal[inTimePeriod - 1 ..], inTimePeriod, allocator);
    defer allocator.free(tmpReal2);
    const tmpReal3 = try EMA(tmpReal2[inTimePeriod - 1 ..], inTimePeriod, allocator);
    defer allocator.free(tmpReal3);
    const tmpReal4 = try Roc(tmpReal3, 1, allocator);
    defer allocator.free(tmpReal4);

    var outReal = try allocator.alloc(f64, prices.len);
    @memset(outReal, 0);
    var i: usize = inTimePeriod;
    var j: usize = (inTimePeriod - 1) * 3 + 1;
    while (j < outReal.len) : ({
        i += 1;
        j += 1;
    }) {
        outReal[j] = tmpReal4[i];
    }

    return outReal;
}

test "Trix computes correctly " {
    const allocator = std.testing.allocator;

    // Test data: prices and period
    const prices = [_]f64{ 1.0, 2.0, 3.0, 4.0, 5, 4, 3, 2, 1 };
    const period = 3;

    const result = try Trix(&prices, period, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 0, 0, 0, 0, 0, 0, 0, -3.125, -11.290322580645162 };
    for (expected, 0..) |exp, i| {
        try std.testing.expectApproxEqAbs(exp, result[i], 1e-9);
    }
}
