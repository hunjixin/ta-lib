const std = @import("std");

pub fn Roc(inReal: []const f64, inTimePeriod: usize, allocator: std.mem.Allocator) ![]f64 {
    var outReal = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outReal);
    @memset(outReal, 0);

    var outIdx: usize = inTimePeriod;
    var inIdx: usize = inTimePeriod;
    var trailingIdx: usize = 0;
    while (inIdx < inReal.len) : ({
        inIdx += 1;
        trailingIdx += 1;
        outIdx += 1;
    }) {
        const tempReal = inReal[trailingIdx];
        if (tempReal != 0.0) {
            outReal[outIdx] = ((inReal[inIdx] / tempReal) - 1.0) * 100.0;
        } else {
            outReal[outIdx] = 0.0;
        }
    }

    return outReal;
}

test "Roc computes correctly" {
    const allocator = std.testing.allocator;

    // Test data: prices and period
    const prices = [_]f64{ 1.0, 2.0, 3.0, 4.0, 5.0 };
    const period = 3;

    const result = try Roc(&prices, period, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 0, 0, 0, 300, 150 };
    for (expected, 0..) |exp, i| {
        try std.testing.expectApproxEqAbs(exp, result[i], 1e-9);
    }
}
