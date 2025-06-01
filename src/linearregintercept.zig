const std = @import("std");
const math = std.math;

/// Calculates the Linear Regression Intercept for a given input time series.
///
/// This indicator computes the intercept `b` of the linear regression line over a specified time period.
/// The intercept represents the point where the regression line crosses the y-axis (when x = 0).
///
/// The linear regression line is defined as:
///
///   y = a * x + b
///
/// where:
///   - x is the time index,
///   - y is the value (price),
///   - a is the slope,
///   - b is the intercept.
///
/// The slope `a` is calculated by:
///
///   a = [ N * Σ(xy) - Σx * Σy ] / [ N * Σ(x^2) - (Σx)^2 ]
///
/// The intercept `b` is calculated by:
///
///   b = ( Σy - a * Σx ) / N
///
/// where N = inTimePeriod,
///       Σ denotes summation over the time period.
///
/// Parameters:
///   - inReal: Input slice of real values (e.g., price data).
///   - inTimePeriod: The number of periods to use in the linear regression calculation.
///   - allocator: Memory allocator for the returned slice.
///
/// Returns:
///   - A slice of f64 values representing the intercepts of the linear regression line for each point.
pub fn LinearRegIntercept(inReal: []const f64, inTimePeriod: usize, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outReal);
    @memset(outReal, 0.0);

    const inTimePeriodF: f64 = @floatFromInt(inTimePeriod);
    const startIdx: usize = inTimePeriod;
    var outIdx: usize = startIdx - 1;
    var today: usize = startIdx - 1;

    const sumX: f64 = inTimePeriodF * (inTimePeriodF - 1) * 0.5;
    const sumXSqr: f64 = inTimePeriodF * (inTimePeriodF - 1) * (2 * inTimePeriodF - 1) / 6;
    const divisor: f64 = sumX * sumX - inTimePeriodF * sumXSqr;

    var sumXY: f64 = 0.0;
    var sumY: f64 = 0.0;
    var i: usize = inTimePeriod;

    while (i > 0) {
        i -= 1;
        const tempValue1 = inReal[today - i];
        sumY += tempValue1;
        sumXY += @as(f64, @floatFromInt(i)) * tempValue1;
    }
    while (today < inReal.len) {
        if (today > startIdx - 1) {
            const tempValue2 = inReal[today - inTimePeriod];
            sumXY += sumY - inTimePeriodF * tempValue2;
            sumY += inReal[today] - tempValue2;
        }

        const m = (inTimePeriodF * sumXY - sumX * sumY) / divisor;
        outReal[outIdx] = (sumY - m * sumX) / inTimePeriodF;

        outIdx += 1;
        today += 1;
    }

    return outReal;
}

test "LinearRegIntercept work correctly" {
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

        115.50, 116.30, 117.10, 117.90, 118.70,
        119.50, 120.30, 121.10, 121.90, 122.70,
        123.50, 124.30, 125.10, 125.90, 126.70,
        127.50, 128.30, 129.10, 129.90, 130.70,
    };

    const result = try LinearRegIntercept(&pricesX, 10, allocator);
    defer allocator.free(result);

    const expected = [_]f64{
        0, 0, 0, 0, 0, 0, 0, 0, 0, 100.01454545454541, 100.78909090909086, 101.56727272727272, 102.32909090909092, 103.11454545454542, 103.88909090909087, 104.66727272727273, 105.4290909090909, 106.21454545454542, 106.98909090909088, 107.76727272727274, 108.71818181818178, 109.7963636363636, 110.88727272727265, 111.94545454545451, 112.89090909090903, 113.71818181818176, 114.31272727272726, 114.62909090909088, 114.58727272727268, 114.18181818181817, 113.70181818181815, 113.17636363636362, 112.6236363636364, 112.10181818181823, 111.62909090909099, 111.26363636363642, 111.02363636363641, 110.96727272727283, 111.11272727272743, 111.51818181818196, 111.80909090909105, 112.0418181818183, 112.2781818181819, 112.5054545454547, 112.7854545454547, 113.10545454545475, 113.52727272727289, 114.03818181818205, 114.7000000000003, 115.5000000000003, 116.3000000000003, 117.10000000000029, 117.90000000000029, 118.7000000000003, 119.5000000000003, 120.3000000000003, 121.10000000000029, 121.90000000000029, 122.7000000000003, 123.5000000000003,
    };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}
