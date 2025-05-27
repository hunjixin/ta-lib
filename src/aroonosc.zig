const std = @import("std");
const DataFrame = @import("./lib.zig").DataFrame;

pub fn AroonOSC(
    df: *const DataFrame(f64),
    inTimePeriod: usize,
    allocator: std.mem.Allocator,
) ![]f64 {
    const inHigh = try df.getColumnData("high");
    const inLow = try df.getColumnData("low");

    const len = inHigh.len;
    if (len != inLow.len) return error.InvalidInput;

    var out = try allocator.alloc(f64, len);
    @memset(out, 0);

    const startIdx: usize = inTimePeriod;
    var outIdx: usize = startIdx;
    var today: usize = startIdx;
    var trailingIdx: usize = startIdx - inTimePeriod;
    var lowestIdx: usize = 0;
    var highestIdx: usize = 0;
    var lowest: f64 = 0.0;
    var highest: f64 = 0.0;
    var lowest_valid = false;
    var highest_valid = false;
    const factor = 100.0 / @as(f64, @floatFromInt(inTimePeriod));

    while (today < len) {
        var tmp = inLow[today];
        if (!lowest_valid or lowestIdx < trailingIdx) {
            lowestIdx = trailingIdx;
            lowest = inLow[lowestIdx];
            var i = trailingIdx + 1;
            while (i <= today) : (i += 1) {
                tmp = inLow[i];
                if (tmp <= lowest) {
                    lowestIdx = i;
                    lowest = tmp;
                }
            }
            lowest_valid = true;
        } else if (tmp <= lowest) {
            lowestIdx = today;
            lowest = tmp;
        }

        tmp = inHigh[today];
        if (!highest_valid or highestIdx < trailingIdx) {
            highestIdx = trailingIdx;
            highest = inHigh[highestIdx];
            var i = trailingIdx + 1;
            while (i <= today) : (i += 1) {
                tmp = inHigh[i];
                if (tmp >= highest) {
                    highestIdx = i;
                    highest = tmp;
                }
            }
            highest_valid = true;
        } else if (tmp >= highest) {
            highestIdx = today;
            highest = tmp;
        }

        out[outIdx] = factor * @as(f64, @floatFromInt((highestIdx - lowestIdx)));
        outIdx += 1;
        trailingIdx += 1;
        today += 1;
    }

    return out;
}

test "Aroon computes  correctly" {
    const gpa = std.testing.allocator;

    var df = try DataFrame(f64).init(gpa);
    defer df.deinit();

    try df.addColumnWithData("high", &[_]f64{ 10, 12, 11, 13, 13, 14, 13, 15, 14, 100, 17, 16, 18, 17, 19, 21, 23, 22, 25, 24, 27, 29, 28, 30, 32, 31, 35, 34, 36, 38 });
    try df.addColumnWithData("low", &[_]f64{ 8, 9, 9, 10, 12, 12, 12, 13, 13, 14, 100, 15, 16, 16, 17, 18, 19, 18, 20, 21, 22, 24, 23, 25, 26, 27, 28, 29, 30, 31 });

    const osc = try AroonOSC(&df, 5, gpa);
    defer gpa.free(osc);

    const expected = [_]f64{
        0,
        0,
        0,
        0,
        0,
        100,
        60,
        100,
        80,
        60,
        60,
        60,
        20,
        20,
        0,
        80,
        100,
        60,
        100,
        80,
        60,
        80,
        80,
        100,
        100,
        80,
        80,
        80,
        100,
        100,
    };
    for (expected, 0..) |exp, i| {
        try std.testing.expectApproxEqAbs(exp, osc[i], 1e-9);
    }
}
