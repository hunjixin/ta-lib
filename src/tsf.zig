const std = @import("std");
const math = std.math;

pub fn Tsf(inReal: []const f64, inTimePeriod: usize, allocator: std.mem.Allocator) ![]f64 {
    var outReal = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outReal);

    const inTimePeriodF = @as(f64, @floatFromInt(inTimePeriod));
    const startIdx = inTimePeriod;
    var outIdx = startIdx - 1;
    var today = startIdx - 1;

    const sumX = inTimePeriodF * (inTimePeriodF - 1.0) * 0.5;
    const sumXSqr = inTimePeriodF * (inTimePeriodF - 1) * (2 * inTimePeriodF - 1) / 6;
    const divisor = sumX * sumX - inTimePeriodF * sumXSqr;

    // initialize values of sumY and sumXY over first (inTimePeriod) input values
    var sumXY: f64 = 0.0;
    var sumY: f64 = 0.0;
    var i = inTimePeriod;

    while (i > 0) {
        i -= 1;
        const tempValue1 = inReal[today - i];
        sumY += tempValue1;
        sumXY += @as(f64, @floatFromInt(i)) * tempValue1;
    }

    while (today < inReal.len) {
        // sumX and sumXY are already available for first output value
        if (today > startIdx - 1) {
            const tempValue2 = inReal[today - inTimePeriod];
            sumXY += sumY - inTimePeriodF * tempValue2;
            sumY += inReal[today] - tempValue2;
        }

        const m = (inTimePeriodF * sumXY - sumX * sumY) / divisor;
        const b = (sumY - m * sumX) / inTimePeriodF;
        outReal[outIdx] = b + m * inTimePeriodF;

        today += 1;
        outIdx += 1;
    }

    return outReal;
}

test "Tsf work correctly" {
    var allocator = std.testing.allocator;
    const pricesX = [_]f64{
        100.00, 100.80, 101.60, 102.30, 103.10,
        103.90, 104.70, 105.40, 106.20, 107.00,
        107.80, 108.50, 109.30, 110.10, 110.90,
        111.60, 112.40, 113.20, 114.00, 114.70,

        114.20, 113.80, 113.50, 113.10, 112.80,
        112.40, 112.10, 111.70, 111.40, 111.00,
        111.50, 111.90, 112.20, 112.60, 112.90,
        113.30, 113.60, 114.00, 114.30, 114.70,
    };

    const result = try Tsf(&pricesX, 10, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 107.76000000000005, 108.54666666666671, 109.30666666666666, 110.08666666666667, 110.86000000000006, 111.64666666666672, 112.40666666666667, 113.18666666666667, 113.96000000000005, 114.74666666666673, 115.50666666666667, 115.76666666666671, 115.62666666666671, 115.22666666666676, 114.60000000000005, 113.86666666666679, 113.03333333333346, 112.24000000000008, 111.52000000000005, 110.99333333333345, 110.66666666666674, 110.65333333333339, 110.8733333333334, 111.26000000000003, 111.78666666666663, 112.38666666666657, 113.0333333333333, 113.65999999999997, 114.23999999999992, 114.70666666666655, 115.0333333333332 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}
