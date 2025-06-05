const std = @import("std");

/// Computes the Linear Regression Slope of the input data over a specified time period.
///
/// The Linear Regression Slope measures the slope (rate of change) of the linear regression
/// line fitted to the last `inTimePeriod` points in the input data. It is useful to identify
/// the direction and strength of a trend.
///
/// Formula:
/// For a set of points \((x_i, y_i)\), where \(x_i\) = index (0 to n-1), and \(y_i\) = price values,
/// the slope \(b\) is calculated as:
/// \[
/// b = \frac{n \sum x_i y_i - \sum x_i \sum y_i}{n \sum x_i^2 - (\sum x_i)^2}
/// \]
///
/// where:
/// - \(n\) = inTimePeriod (number of points)
/// - \(\sum x_i\) = sum of indices (0 + 1 + ... + n-1)
/// - \(\sum y_i\) = sum of prices in the period
/// - \(\sum x_i y_i\) = sum of products of index and price
/// - \(\sum x_i^2\) = sum of squares of indices
///
/// The resulting slope indicates the average change in price per unit time within the window.
///
/// Params:
/// - `inReal`: input array of float64 price values
/// - `inTimePeriod`: window size for regression calculation
/// - `allocator`: memory allocator for output slice
///
/// Returns:
/// - Array of float64 containing the slope values for each valid period.
///
/// Errors:
/// - Returns an error if allocation fails or input length is insufficient.
pub fn LinearRegSlope(inReal: []const f64, inTimePeriod: usize, allocator: std.mem.Allocator) ![]f64 {
    var outReal = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outReal);
    @memset(outReal, 0);

    const inTimePeriodF: f64 = @floatFromInt(inTimePeriod);
    const startIdx = inTimePeriod;
    var outIdx = startIdx - 1;
    var today = startIdx - 1;

    const sumX = inTimePeriodF * (inTimePeriodF - 1) * 0.5;
    const sumXSqr = inTimePeriodF * (inTimePeriodF - 1) * (2 * inTimePeriodF - 1) / 6;
    const divisor = sumX * sumX - inTimePeriodF * sumXSqr;

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
        if (today > startIdx - 1) {
            const tempValue2 = inReal[today - inTimePeriod];
            sumXY += sumY - inTimePeriodF * tempValue2;
            sumY += inReal[today] - tempValue2;
        }

        outReal[outIdx] = (inTimePeriodF * sumXY - sumX * sumY) / divisor;
        outIdx += 1;
        today += 1;
    }

    return outReal;
}

test "LinearRegSlope work correctly" {
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

    const result = try LinearRegSlope(&pricesX, 10, allocator);
    defer allocator.free(result);

    const expected = [_]f64{
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0.7745454545454634, 0.7757575757575845, 0.7739393939393939, 0.7757575757575758, 0.7745454545454634, 0.7757575757575845, 0.7739393939393939, 0.7757575757575758, 0.7745454545454634, 0.7757575757575845, 0.7739393939393939, 0.7048484848484937, 0.5830303030303119, 0.43393939393941156, 0.26545454545455427, 0.09757575757577522, -0.06848484848483084, -0.20727272727271845, -0.3109090909090821, -0.3593939393939218, -0.3515151515151427, -0.30484848484847604, -0.2303030303030215, -0.13636363636363635, -0.031515151515160336, 0.07575757575755812, 0.17696969696968815, 0.26363636363635484, 0.3272727272727096, 0.35939393939391295, 0.3515151515151251, 0.3757575757575493, 0.42181818181816416, 0.4781818181818094, 0.545454545454519, 0.6121212121211856, 0.6787878787878435, 0.7339393939393675, 0.7781818181817741, 0.7999999999999383, 0.7999999999999383, 0.7999999999999383, 0.7999999999999383, 0.7999999999999383, 0.7999999999999383, 0.7999999999999383, 0.7999999999999383, 0.7999999999999383, 0.7999999999999383, 0.7999999999999383, 0.7999999999999383,
    };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}
