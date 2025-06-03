const std = @import("std");
const MyError = @import("./lib.zig").MyError;
const MaType = @import("./lib.zig").MaType;
const Ma = @import("./lib.zig").Ma;

/// Calculates the Moving Average with Variable Period (Mavp) for a given price series.
///
/// The Mavp is a moving average where the period can change at each data point,
/// allowing for dynamic smoothing based on market conditions or other criteria.
/// The formula for Mavp at index `i` is:
/// ```
/// Mavp[i] = sum(prices[i - period/2 .. i + period/2]) / period
/// ```
/// where `period` is clamped between `inMinPeriod` and `inMaxPeriod` and is taken from `inPeriods[i]`.
///
/// Parameters:
/// - `prices`: Array of input price values (e.g., closing prices).
/// - `inPeriods`: Array specifying the moving average period for each price point.
/// - `inMinPeriod`: Minimum allowed period for the moving average.
/// - `inMaxPeriod`: Maximum allowed period for the moving average.
/// - `maType`: Enum specifying the type of moving average to use (e.g., Ema, Sma)
/// - `allocator`: Memory allocator for the result array.
///
/// Returns:
/// - Allocated array of Mavp values corresponding to each input price.
///
/// Errors:
/// - Returns an error if memory allocation fails or if input arrays have mismatched lengths.
///
/// Reference:
/// - [TA-Lib Mavp Documentation](https://ta-lib.org/function.html)
pub fn Mavp(prices: []const f64, inPeriods: []const usize, inMinPeriod: usize, inMaxPeriod: usize, maType: MaType, allocator: std.mem.Allocator) ![]f64 {
    if (prices.len != inPeriods.len) {
        return MyError.RowColumnMismatch;
    }
    if (inMinPeriod > inMaxPeriod or inMinPeriod == 0) {
        return MyError.InvalidInput;
    }

    const startIdx = inMaxPeriod - 1;
    const outputSize = prices.len;

    var outReal = try allocator.alloc(f64, outputSize);
    errdefer allocator.free(outReal);
    @memset(outReal, 0);

    var localPeriodArray = try allocator.alloc(usize, outputSize);
    defer allocator.free(localPeriodArray);

    for (startIdx..outputSize) |i| {
        var tempInt = inPeriods[i];
        if (tempInt < inMinPeriod) {
            tempInt = inMinPeriod;
        } else if (tempInt > inMaxPeriod) {
            tempInt = inMaxPeriod;
        }
        localPeriodArray[i] = tempInt;
    }

    var i = startIdx;
    while (i < outputSize) : (i += 1) {
        const curPeriod = localPeriodArray[i];
        if (curPeriod != 0) {
            const localOutputArray = try Ma(prices, curPeriod, maType, allocator);
            defer allocator.free(localOutputArray);

            outReal[i] = localOutputArray[i];
            var j = i + 1;
            while (j < outputSize) : (j += 1) {
                if (localPeriodArray[j] == curPeriod) {
                    localPeriodArray[j] = 0;
                    outReal[j] = localOutputArray[j];
                }
            }
        }
    }

    return outReal;
}

test "Mavp work correctly" {
    var allocator = std.testing.allocator;
    const prices = [_]f64{
        82.4, 15.7, 63.2, 91.5, 27.8, 54.6, 39.1, 75.3, 44.2, 10.8, 67.5, 16.2, 23.9, 87.1, 19.6,
        10.1, 12.8, 11.4, 75.9, 13.7, 14.2, 13.5, 15.9, 14.8, 43.3, 32.6, 16.2, 13.4, 17.5, 76.1,
    };

    const periods = [_]usize{
        2, 3, 4, 5, 6, 2, 3, 4, 5, 6, 2, 3, 4, 5, 6, 2, 3, 4, 5, 6, 2, 3, 4, 5, 6, 2, 3, 4, 5, 6,
    };

    const mavp = try Mavp(&prices, &periods, 2, 6, MaType.SMA, allocator);
    defer allocator.free(mavp);

    const expected = [_]f64{ 0.0000000000, 0.0000000000, 0.0000000000, 0.0000000000, 0.0000000000, 41.2000000000, 40.5000000000, 49.2000000000, 48.2000000000, 41.9666666667, 39.1500000000, 31.5000000000, 29.6000000000, 41.1000000000, 37.5166666667, 14.8500000000, 14.1666666667, 13.4750000000, 25.9600000000, 23.9166666667, 13.9500000000, 13.8000000000, 14.3250000000, 14.4200000000, 19.2333333333, 37.9500000000, 30.7000000000, 26.3750000000, 24.6000000000, 33.1833333333 };
    for (mavp, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}
