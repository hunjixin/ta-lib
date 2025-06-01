const std = @import("std");
const math = std.math;

/// Computes the Linear Regression value (y) for each point in the input series over a sliding window.
///
/// The Linear Regression Line is the best-fit straight line for a given set of data using the Least Squares Method.
/// For a window of `inTimePeriod` points, it calculates the linear regression line:
///     y = a * x + b
/// where:
///     - `x` is the index within the window (0, 1, 2, ..., inTimePeriod - 1)
///     - `a` is the slope of the line
///     - `b` is the y-intercept
///
/// The slope `a` and intercept `b` are calculated using:
///     a = (n * Σ(x_i * y_i) - Σx_i * Σy_i) / (n * Σ(x_i^2) - (Σx_i)^2)
///     b = (Σy_i - a * Σx_i) / n
/// where:
///     - n = inTimePeriod
///     - x_i = i (index within the window)
///     - y_i = inReal[i] (value at each index)
///
/// The function returns a slice of `f64` values, each representing the fitted y-value at the last point of each window,
/// i.e., y = a * (inTimePeriod - 1) + b
///
/// Parameters:
/// - `inReal`: Input time series data
/// - `inTimePeriod`: The window length for regression
/// - `allocator`: Memory allocator for the result
///
/// Returns:
/// - Slice of linear regression output values for each window
///
/// Example:
/// Given input: [81.59, 81.06, 82.87, 83.00, 83.61]
/// With time period: 3
/// Output: [LinearReg over [81.59, 81.06, 82.87], LinearReg over [81.06, 82.87, 83.00], ...]
pub fn LinearReg(inReal: []const f64, inTimePeriod: usize, allocator: std.mem.Allocator) ![]f64 {
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

    while (today < inReal.len) : ({
        outIdx += 1;
        today += 1;
    }) {
        if (today > startIdx - 1) {
            const tempValue2 = inReal[today - inTimePeriod];
            sumXY += sumY - inTimePeriodF * tempValue2;
            sumY += inReal[today] - tempValue2;
        }

        const m = (inTimePeriodF * sumXY - sumX * sumY) / divisor;
        const b = (sumY - m * sumX) / inTimePeriodF;

        outReal[outIdx] = b + m * (inTimePeriodF - 1);
    }

    return outReal;
}

test "LinearReg work correctly" {
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

    const result = try LinearReg(&pricesX, 10, allocator);
    defer allocator.free(result);

    const expected = [_]f64{
        0, 0, 0, 0, 0, 0, 0, 0, 0, 106.98545454545459, 107.77090909090911, 108.53272727272727, 109.3109090909091, 110.0854545454546, 110.87090909090912, 111.63272727272728, 112.41090909090909, 113.18545454545459, 113.97090909090913, 114.73272727272729, 115.06181818181823, 115.0436363636364, 114.79272727272735, 114.33454545454549, 113.769090909091, 113.10181818181829, 112.44727272727279, 111.83090909090913, 111.35272727272738, 111.01818181818189, 110.95818181818187, 111.10363636363643, 111.39636363636366, 111.81818181818178, 112.310909090909, 112.85636363636361, 113.3963636363636, 113.91272727272721, 114.34727272727264, 114.68181818181809, 115.190909090909, 115.83818181818178, 116.58181818181819, 117.41454545454536, 118.29454545454537, 119.21454545454534, 120.1327272727272, 121.04181818181802, 121.89999999999975, 122.69999999999975, 123.49999999999974, 124.29999999999974, 125.09999999999974, 125.89999999999975, 126.69999999999975, 127.49999999999974, 128.29999999999973, 129.09999999999974, 129.89999999999975, 130.69999999999973,
    };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}
