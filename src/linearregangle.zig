const std = @import("std");
const math = std.math;

/// Calculates the Linear Regression Angle for a given input time series.
///
/// This indicator computes the angle (in degrees) of the slope of the linear regression line
/// over a specified time period. It's useful to measure the direction and steepness of a trend.
///
/// The Linear Regression Line is calculated using the least squares method:
///
///   y = a * x + b
///
/// where:
///   - x is the index (time)
///   - y is the price (inReal)
///   - a is the slope of the regression line
///   - b is the intercept
///
/// The slope 'a' is given by:
///
///   a = [ N * Σ(xy) - Σx * Σy ] / [ N * Σ(x^2) - (Σx)^2 ]
///
/// Then, the angle is calculated as:
///
///   angle = atan(slope) * (180 / π)
///
/// This converts the slope into degrees, representing the inclination of the trend.
///
/// Parameters:
///   - inReal: Input slice of real values (typically price data).
///   - inTimePeriod: The number of periods to consider for each linear regression calculation.
///   - allocator: Memory allocator for the output array.
///
/// Returns:
///   - A slice of f64 values representing the angle (in degrees) of the linear regression slope.
pub fn LinearRegAngle(inReal: []const f64, inTimePeriod: usize, allocator: std.mem.Allocator) ![]f64 {
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

    // Main calculation loop
    while (today < inReal.len) {
        // Update sums for subsequent values
        if (today > startIdx - 1) {
            const tempValue2 = inReal[today - inTimePeriod];
            sumXY += sumY - inTimePeriodF * tempValue2;
            sumY += inReal[today] - tempValue2;
        }

        // Calculate slope (m) and convert to angle in degrees
        const m = (inTimePeriodF * sumXY - sumX * sumY) / divisor;
        outReal[outIdx] = math.atan(m) * (180.0 / math.pi);

        outIdx += 1;
        today += 1;
    }

    return outReal;
}

test "LinearRegAngle work correctly" {
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

    const result = try LinearRegAngle(&pricesX, 10, allocator);
    defer allocator.free(result);

    const expected = [_]f64{
        0, 0, 0, 0, 0, 0, 0, 0, 0, 37.75940987035531, 37.80279245093884, 37.73769947848229, 37.802792450938526, 37.75940987035531, 37.80279245093884, 37.73769947848229, 37.802792450938526, 37.75940987035531, 37.80279245093884, 37.73769947848229, 35.17803725372611, 30.24348115722757, 23.457921370103335, 14.86655895418496, 5.573036761699137, -3.917775403920837, -11.71003616246342, -17.270944330616462, -19.76812970094406, -19.367347547775786, -16.953763208454184, -12.969253456028232, -7.765166018425333, -1.805087723481984, 4.33231398318751, 10.03571059209802, 14.769198530291167, 18.121860247900443, 19.76812970094361, 19.367347547774887, 20.59409022030745, 22.870901550867575, 25.55627889636602, 28.61045966596405, 31.4716845336262, 34.16818532502396, 36.27641231253309, 37.88940493936825, 38.659808254087935, 38.659808254087935, 38.659808254087935, 38.659808254087935, 38.659808254087935, 38.659808254087935, 38.659808254087935, 38.659808254087935, 38.659808254087935, 38.659808254087935, 38.659808254087935, 38.659808254087935,
    };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}
