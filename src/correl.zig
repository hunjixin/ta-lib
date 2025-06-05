const std = @import("std");
const math = std.math;

/// Calculates the Pearson Correlation Coefficient (CORREL) between two time series.
///
/// CORREL is a statistical measure that describes the degree to which two variables move in relation to each other.
/// The output values range from -1.0 to 1.0:
/// - `+1.0` indicates perfect positive correlation,
/// - `0.0` indicates no correlation,
/// - `-1.0` indicates perfect negative correlation.
///
/// The Pearson correlation coefficient is calculated using the following formula:
///
/// ```text
/// CORREL = Σ[(Xᵢ - mean(X)) * (Yᵢ - mean(Y))] / (n * stddev(X) * stddev(Y))
/// ```
///
/// Where:
/// - `X` and `Y` are the two input arrays,
/// - `n` is the time period (`inTimePeriod`),
/// - `mean(X)` and `mean(Y)` are the averages of the last `n` values,
/// - `stddev(X)` and `stddev(Y)` are the standard deviations over the last `n` values.
///
/// This function returns a slice of correlation values, aligned with the end of the input slices (the first `inTimePeriod - 1` values may be zero or omitted depending on implementation).
///
/// # Parameters
/// - `inReal0`: The first input time series (X values).
/// - `inReal1`: The second input time series (Y values).
/// - `inTimePeriod`: The number of periods to use in the correlation calculation (must be ≥ 1).
/// - `allocator`: Memory allocator used to allocate the result array.
///
/// # Returns
/// - An array of `f64` values representing the correlation coefficients between `inReal0` and `inReal1` over the specified time period.
///
/// # Errors
/// - Returns an error if memory allocation fails or if input arrays are too short.
///
/// # Example
/// ```zig
/// const result = try Correl(open_prices, close_prices, 10, allocator);
/// ```
pub fn Correl(
    inReal0: []const f64,
    inReal1: []const f64,
    inTimePeriod: usize,
    allocator: std.mem.Allocator,
) ![]f64 {
    const outReal = try allocator.alloc(f64, inReal0.len);
    errdefer allocator.free(outReal);
    @memset(outReal, 0);

    if (inTimePeriod == 0) return outReal;

    const inTimePeriodF: f64 = @floatFromInt(inTimePeriod);
    const lookbackTotal = inTimePeriod - 1;
    const startIdx = lookbackTotal;
    var trailingIdx: usize = startIdx - lookbackTotal;

    var sumXY: f64 = 0.0;
    var sumX: f64 = 0.0;
    var sumY: f64 = 0.0;
    var sumX2: f64 = 0.0;
    var sumY2: f64 = 0.0;

    // Initial window calculation
    var today: usize = trailingIdx;
    while (today <= startIdx) : (today += 1) {
        const x = inReal0[today];
        sumX += x;
        sumX2 += x * x;

        const y = inReal1[today];
        sumXY += x * y;
        sumY += y;
        sumY2 += y * y;
    }

    var trailingX = inReal0[trailingIdx];
    var trailingY = inReal1[trailingIdx];
    trailingIdx += 1;

    const tempReal = (sumX2 - (sumX * sumX) / inTimePeriodF) *
        (sumY2 - (sumY * sumY) / inTimePeriodF);

    if (tempReal >= 1e-14) {
        outReal[inTimePeriod - 1] = (sumXY - (sumX * sumY) / inTimePeriodF) /
            math.sqrt(tempReal);
    } else {
        outReal[inTimePeriod - 1] = 0.0;
    }

    var outIdx: usize = inTimePeriod;
    today = startIdx + 1;

    // Slide window through remaining data
    while (today < inReal0.len) {
        // Remove trailing element
        sumX -= trailingX;
        sumX2 -= trailingX * trailingX;
        sumXY -= trailingX * trailingY;
        sumY -= trailingY;
        sumY2 -= trailingY * trailingY;

        // Add new element
        const x = inReal0[today];
        sumX += x;
        sumX2 += x * x;

        const y = inReal1[today];
        sumXY += x * y;
        sumY += y;
        sumY2 += y * y;
        today += 1;

        // Update trailing values
        trailingX = inReal0[trailingIdx];
        trailingY = inReal1[trailingIdx];
        trailingIdx += 1;

        // Calculate new correlation
        const newTempReal = (sumX2 - (sumX * sumX) / inTimePeriodF) *
            (sumY2 - (sumY * sumY) / inTimePeriodF);

        if (newTempReal >= 1e-14) {
            outReal[outIdx] = (sumXY - (sumX * sumY) / inTimePeriodF) /
                math.sqrt(newTempReal);
        } else {
            outReal[outIdx] = 0.0;
        }
        outIdx += 1;
    }

    return outReal;
}

test "Correl work correctly" {
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

    const pricesY = [_]f64{
        115.50, 116.30, 117.10, 117.90, 118.70,
        119.50, 120.30, 121.10, 121.90, 122.70,
        123.50, 124.30, 125.10, 125.90, 126.70,
        127.50, 128.30, 129.10, 129.90, 130.70,

        130.20, 129.40, 128.60, 129.20, 129.80,
        129.10, 128.40, 128.90, 129.40, 128.70,
        129.30, 129.90, 130.50, 130.00, 129.50,
        130.10, 130.70, 131.30, 130.80, 130.30,
    };
    const result = try Correl(&pricesX, &pricesY, 8, allocator);
    defer allocator.free(result);

    const expected = [_]f64{
        0, 0, 0, 0, 0, 0, 0, 0.9998769457943636, 0.9998857077547629, 0.999876945794364, 0.999907062333283, 0.9998769457943638, 0.9998857077547425, 0.9998769457943638, 0.9999070623329991, 0.9998769457940748, 0.9998857077544518, 0.9998769457943453, 0.9999070623327285, 0.9998769457937858, 0.999811948750424, 0.9959118811001992, 0.957790367129341, 0.9168429229636496, 0.6682451204677108, 0.6663217446775035, 0.7552446622628334, 0.5840865416420954, 0.09914149879728491, 0.11015155896811742, 0.3519947347128376, 0.3305899427152212, 0.28497176753885956, 0.5168648283985527, 0.6135219375512222, 0.65688428184443, 0.746494549671532, 0.7316334252114167, 0.6555985729665037, 0.45178812249199485,
    };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}
