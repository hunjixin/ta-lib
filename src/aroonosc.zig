const std = @import("std");

pub fn AroonOsc(
    inHigh: []const f64,
    inLow: []const f64,
    inTimePeriod: usize,
    allocator: std.mem.Allocator,
) ![]f64 {
    const outReal = try allocator.alloc(f64, inHigh.len);
    errdefer allocator.free(outReal);
    @memset(outReal, 0);

    if (inTimePeriod == 0) return outReal;

    const startIdx = inTimePeriod;
    var outIdx: usize = startIdx;
    var today: usize = startIdx;
    var trailingIdx: usize = startIdx - inTimePeriod;
    var lowestIdx: i64 = -1;
    var highestIdx: i64 = -1;
    var lowest: f64 = 0.0;
    var highest: f64 = 0.0;
    const factor: f64 = 100.0 / @as(f64, @floatFromInt(inTimePeriod));

    while (today < inHigh.len) {
        var tmp: f64 = inLow[today];

        if (lowestIdx < @as(i64, @intCast(trailingIdx))) {
            lowestIdx = @intCast(trailingIdx);
            lowest = inLow[@intCast(lowestIdx)];
            var i: usize = @as(usize, @intCast(lowestIdx)) + 1;
            while (i <= today) : (i += 1) {
                tmp = inLow[i];
                if (tmp <= lowest) {
                    lowestIdx = @intCast(i);
                    lowest = tmp;
                }
            }
        } else if (tmp <= lowest) {
            lowestIdx = @intCast(today);
            lowest = tmp;
        }

        tmp = inHigh[today];
        if (highestIdx < @as(i64, @intCast(trailingIdx))) {
            highestIdx = @intCast(trailingIdx);
            highest = inHigh[@intCast(highestIdx)];
            var i: usize = @as(usize, @intCast(highestIdx)) + 1;
            while (i <= today) : (i += 1) {
                tmp = inHigh[i];
                if (tmp >= highest) {
                    highestIdx = @intCast(i);
                    highest = tmp;
                }
            }
        } else if (tmp >= highest) {
            highestIdx = @intCast(today);
            highest = tmp;
        }

        const aroon = factor * @as(f64, @floatFromInt(highestIdx - lowestIdx));
        outReal[outIdx] = aroon;

        outIdx += 1;
        trailingIdx += 1;
        today += 1;
    }

    return outReal;
}

test "Aroon computes  correctly" {
    const gpa = std.testing.allocator;

    const highs = [_]f64{ 10, 12, 11, 13, 13, 14, 13, 15, 14, 100, 17, 16, 18, 17, 19, 21, 23, 22, 25, 24, 27, 29, 28, 30, 32, 31, 35, 34, 36, 38 };
    const lows = [_]f64{ 8, 9, 9, 10, 12, 12, 12, 13, 13, 14, 100, 15, 16, 16, 17, 18, 19, 18, 20, 21, 22, 24, 23, 25, 26, 27, 28, 29, 30, 31 };

    const osc = try AroonOsc(&highs, &lows, 5, gpa);
    defer gpa.free(osc);

    const expected = [_]f64{ 0, 0, 0, 0, 0, 100, 60, 100, 80, 60, 60, 60, 20, 20, 0, 80, 100, 60, 100, 80, 60, 80, 80, 100, 100, 80, 80, 80, 100, 100 };
    for (expected, 0..) |exp, i| {
        try std.testing.expectApproxEqAbs(exp, osc[i], 1e-9);
    }
}
