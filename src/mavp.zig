const std = @import("std");
const MyError = @import("./lib.zig").MyError;
const SMA = @import("./lib.zig").SMA;

pub fn MAVP(prices: []const f64, inPeriods: []const usize, inMinPeriod: usize, inMaxPeriod: usize, allocator: std.mem.Allocator) ![]f64 {
    if (prices.len != inPeriods.len) {
        return MyError.RowColumnMismatch;
    }
    if (inMinPeriod > inMaxPeriod or inMinPeriod == 0) {
        return MyError.InvalidInput;
    }

    const startIdx = inMaxPeriod - 1;
    const outputSize = prices.len;

    var outReal = try allocator.alloc(f64, outputSize);
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
            const localOutputArray = try SMA(prices, curPeriod, allocator);
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

test "MAVP work correctly" {
    var allocator = std.testing.allocator;
    const prices = [_]f64{
        82.4, 15.7, 63.2, 91.5, 27.8, 54.6, 39.1, 75.3, 44.2, 10.8, 67.5, 16.2, 23.9, 87.1, 19.6,
        10.1, 12.8, 11.4, 75.9, 13.7, 14.2, 13.5, 15.9, 14.8, 43.3, 32.6, 16.2, 13.4, 17.5, 76.1,
    };

    const periods = [_]usize{
        2, 3, 4, 5, 6, 2, 3, 4, 5, 6, 2, 3, 4, 5, 6, 2, 3, 4, 5, 6, 2, 3, 4, 5, 6, 2, 3, 4, 5, 6,
    };

    const mavp = try MAVP(&prices, &periods, 2, 6, allocator);
    defer allocator.free(mavp);

    const expected = [_]f64{ 0.0000000000, 0.0000000000, 0.0000000000, 0.0000000000, 0.0000000000, 41.2000000000, 40.5000000000, 49.2000000000, 48.2000000000, 41.9666666667, 39.1500000000, 31.5000000000, 29.6000000000, 41.1000000000, 37.5166666667, 14.8500000000, 14.1666666667, 13.4750000000, 25.9600000000, 23.9166666667, 13.9500000000, 13.8000000000, 14.3250000000, 14.4200000000, 19.2333333333, 37.9500000000, 30.7000000000, 26.3750000000, 24.6000000000, 33.1833333333 };
    for (mavp, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(v, expected[i], 1e-9);
    }
}
