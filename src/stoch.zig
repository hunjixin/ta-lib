const std = @import("std");
const MaType = @import("./lib.zig").MaType;
const Ma = @import("./lib.zig").Ma;
const IsZero = @import("./utils.zig").IsZero;
const MyError = @import("./lib.zig").MyError;

/// Calculates the Stochastic Oscillator for the given data frame.
///
/// The Stochastic Oscillator is a momentum indicator comparing a particular closing price of a security to a range of its prices over a certain period of time.
/// It is commonly used in technical analysis to generate overbought and oversold trading signals.
///
/// The Fast %K formula:
///   %K = 100 * (Current Close - Lowest Low) / (Highest High - Lowest Low)
/// where:
///   - Lowest Low = lowest low for the look-back period (inFastKPeriod)
///   - Highest High = highest high for the look-back period (inFastKPeriod)
///
/// The Slow %K is typically a moving average of Fast %K over inSlowKPeriod.
/// The Slow %D is a moving average of Slow %K over inSlowDPeriod.
///
/// Parameters:
///   - `high`: The high price of the asset.
///   - `low`: The low price of the asset.
///   - `close`: The closing price of the asset.
///   - `inFastKPeriod`: Look-back period for Fast %K calculation.
///   - `inSlowKPeriod`: Smoothing period for Slow %K (usually 3).
///   - `inSlowKMAType`: num specifying the type of moving average to use (e.g., EMA, SMA)
///   - `inSlowDPeriod`: Smoothing period for Slow %D (usually 3).
///   - `inSlowDMAType`: num specifying the type of moving average to use (e.g., EMA, SMA)
///   - `allocator`: Memory allocator to use for result arrays.
///
/// Returns:
///   - A struct containing two slices of f64:
///       - The first slice is the Slow %K values.
///       - The second slice is the Slow %D values.
///
/// Errors:
///   - Returns an error if memory allocation fails or input parameters are invalid.
pub fn Stoch(
    high: []const f64,
    low: []const f64,
    close: []const f64,
    inFastKPeriod: usize,
    inSlowKPeriod: usize,
    inSlowKMAType: MaType,
    inSlowDPeriod: usize,
    inSlowDMAType: MaType,
    allocator: std.mem.Allocator,
) !struct { []f64, []f64 } {
    const len = close.len;

    var outSlowK = try allocator.alloc(f64, len);
    var outSlowD = try allocator.alloc(f64, len);
    @memset(outSlowK, 0);
    @memset(outSlowD, 0);

    const lookbackK = inFastKPeriod - 1;
    const loobackkSlow = inSlowKPeriod - 1;
    const lookbackFastD = inSlowDPeriod - 1;
    const lookbackTotal = lookbackK + lookbackFastD + loobackkSlow;
    const startIdx = lookbackTotal;

    if (len <= startIdx) return .{ outSlowK, outSlowD };

    const tempLen = len - lookbackK + 1;
    var tempBuffer = try allocator.alloc(f64, tempLen);
    defer allocator.free(tempBuffer);
    @memset(tempBuffer, 0);

    for (lookbackK..len) |today| {
        const outIdx = today - lookbackK;
        const windowStart = today - lookbackK;
        var lowest = low[windowStart];
        var highest = high[windowStart];
        for (windowStart..today + 1) |i| {
            if (low[i] < lowest) lowest = low[i];
            if (high[i] > highest) highest = high[i];
        }
        const diff = (highest - lowest) / 100.0;
        tempBuffer[outIdx] = if (!IsZero(diff))
            (close[today] - lowest) / diff
        else
            0.0;
    }

    const tempBuffer1 = try Ma(tempBuffer, inSlowKPeriod, inSlowKMAType, allocator);
    const tempBuffer2 = try Ma(tempBuffer1, inSlowDPeriod, inSlowDMAType, allocator);
    defer allocator.free(tempBuffer1);
    defer allocator.free(tempBuffer2);

    for (lookbackTotal..len) |j| {
        const i = j - lookbackK;
        outSlowK[j] = tempBuffer1[i];
        outSlowD[j] = tempBuffer2[i];
    }
    return .{ outSlowK, outSlowD };
}

test "Stoch calculation works with bigger dataset" {
    const gpa = std.testing.allocator;

    const highs = [_]f64{
        15.2, 16.8, 18.5, 19.1, 20.7, 22.3, 23.0, 24.8, 26.1, 27.5,
        28.9, 30.2, 31.7, 33.0, 34.4, 35.8, 37.1, 38.5, 39.9, 41.2,
    };
    const lows = [_]f64{
        13.1, 14.0, 15.7, 16.2, 17.8, 19.0, 20.2, 21.5, 22.7, 24.0,
        25.1, 26.3, 27.6, 28.9, 30.1, 31.4, 32.7, 34.0, 35.2, 36.5,
    };
    const closes = [_]f64{
        14.0, 16.0, 17.2, 18.7, 19.9, 21.5, 22.6, 23.9, 25.0, 26.8,
        27.7, 29.1, 30.5, 31.8, 33.2, 34.7, 36.0, 37.3, 38.7, 40.0,
    };

    {
        const result = try Stoch(&highs, &lows, &closes, 5, 3, MaType.SMA, 3, MaType.SMA, gpa);
        defer gpa.free(result[0]);
        defer gpa.free(result[1]);

        const expect_fastk = [_]f64{
            0,                 0,                 0,                 0,                 0,                 0,                 0,                 0,                 90.26747320598098, 89.34885918503012,
            88.23953012862812, 88.44264142438585, 86.74329501915712, 86.89655172413796, 86.81003584229394, 87.39483116393139, 87.97962648556882, 88.11403508771934, 87.89205155746514, 87.67006802721092,
        };
        const expect_fastd = [_]f64{
            0,                 0,                 0,                 0,                 0,                 0,                 0,                 0,                 91.06388611178618, 90.3628749580335,
            89.28528750654641, 88.67701024601469, 87.80848885739037, 87.36082938922698, 86.81662752852968, 87.03380624345442, 87.39483116393137, 87.82949757907318, 87.9952377102511,  87.89205155746514,
        };

        for (result[0], expect_fastk, 0..) |actual, expect, idx| {
            if (@abs(actual - expect) > 1e-8) {
                std.debug.print("Mismatch at fastk index {}: actual={}, expect={}\n", .{ idx, actual, expect });
            }
            try std.testing.expectApproxEqAbs(expect, actual, 1e-8);
        }

        for (result[1], expect_fastd, 0..) |actual, expect, idx| {
            if (@abs(actual - expect) > 1e-8) {
                std.debug.print("Mismatch at fastd index {}: actual={}, expect={}\n", .{ idx, actual, expect });
            }
            try std.testing.expectApproxEqAbs(expect, actual, 1e-8);
        }
    }

    {
        const result = try Stoch(&highs, &lows, &closes, 8, 3, MaType.SMA, 3, MaType.SMA, gpa);
        defer gpa.free(result[0]);
        defer gpa.free(result[1]);

        const expect_fastk = [_]f64{
            0,                0,               0,                 0,                 0,                 0,                0,                 0,                 0,                0, 0,
            91.9160033235321, 90.743798154263, 90.76840445347561, 90.62461850698901, 90.97524261790646, 91.3012604296113, 91.41696099654405, 91.27476671425097, 91.1325724319579,
        };
        const expect_fastd = [_]f64{
            0,                 0,                 0,                 0,                 0,                 0,                 0,                 0,                 0,                 0, 0,
            92.06229537990798, 91.50083033944533, 91.14273531042357, 90.71227370490921, 90.78942185945704, 90.96704051816893, 91.23115468135394, 91.33099604680211, 91.27476671425097,
        };

        for (result[0], expect_fastk, 0..) |actual, expect, idx| {
            if (@abs(actual - expect) > 1e-8) {
                std.debug.print("Mismatch at fastk index {}: actual={}, expect={}\n", .{ idx, actual, expect });
            }
            try std.testing.expectApproxEqAbs(expect, actual, 1e-8);
        }

        for (result[1], expect_fastd, 0..) |actual, expect, idx| {
            if (@abs(actual - expect) > 1e-8) {
                std.debug.print("Mismatch at fastd index {}: actual={}, expect={}\n", .{ idx, actual, expect });
            }
            try std.testing.expectApproxEqAbs(expect, actual, 1e-8);
        }
    }
}
