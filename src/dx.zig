const std = @import("std");
const math = std.math;
const MyError = @import("./lib.zig").MyError;

pub fn Dx(
    inHigh: []const f64,
    inLow: []const f64,
    inClose: []const f64,
    inTimePeriod: usize,
    allocator: std.mem.Allocator,
) ![]f64 {
    if (!(inHigh.len == inLow.len and inLow.len == inClose.len)) {
        return MyError.RowColumnMismatch;
    }

    var outReal = try allocator.alloc(f64, inClose.len);
    errdefer allocator.free(outReal);
    @memset(outReal, 0);

    const lookbackTotal = if (inTimePeriod > 1) inTimePeriod else 2;
    const startIdx = lookbackTotal;
    const inTimePeriodF: f64 = @floatFromInt(inTimePeriod);
    var outIdx = startIdx;

    var prevMinusDM: f64 = 0.0;
    var prevPlusDM: f64 = 0.0;
    var prevTR: f64 = 0.0;
    var today = startIdx - lookbackTotal;
    var prevHigh = inHigh[today];
    var prevLow = inLow[today];
    var prevClose = inClose[today];

    // Initial calculations
    var i = inTimePeriod - 1;
    while (i > 0) : (i -= 1) {
        today += 1;
        const tempReal = inHigh[today];
        const diffP = tempReal - prevHigh;
        prevHigh = tempReal;

        const tempReal2 = inLow[today];
        const diffM = prevLow - tempReal2;
        prevLow = tempReal2;

        if (diffM > 0 and diffP < diffM) {
            prevMinusDM += diffM;
        } else if (diffP > 0 and diffP > diffM) {
            prevPlusDM += diffP;
        }

        var tempTR = prevHigh - prevLow;
        const tempReal3 = @abs(prevHigh - prevClose);
        if (tempReal3 > tempTR) {
            tempTR = tempReal3;
        }
        const tempReal4 = @abs(prevLow - prevClose);
        if (tempReal4 > tempTR) {
            tempTR = tempReal4;
        }

        prevTR += tempTR;
        prevClose = inClose[today];
    }

    // First DX value
    if (!(math.approxEqAbs(f64, prevTR, 0.0, 0.00000000000001))) {
        const minusDI = 100.0 * (prevMinusDM / prevTR);
        const plusDI = 100.0 * (prevPlusDM / prevTR);
        const tempSum = minusDI + plusDI;
        if (!(math.approxEqAbs(f64, tempSum, 0.0, 0.00000000000001))) {
            outReal[outIdx] = 100.0 * (@abs(minusDI - plusDI) / tempSum);
        }
    }

    // Subsequent DX values
    outIdx = startIdx;
    while (today < inClose.len - 1) {
        today += 1;
        const tempReal = inHigh[today];
        const diffP = tempReal - prevHigh;
        prevHigh = tempReal;

        const tempReal2 = inLow[today];
        const diffM = prevLow - tempReal2;
        prevLow = tempReal2;

        prevMinusDM -= prevMinusDM / inTimePeriodF;
        prevPlusDM -= prevPlusDM / inTimePeriodF;

        if (diffM > 0 and diffP < diffM) {
            prevMinusDM += diffM;
        } else if (diffP > 0 and diffP > diffM) {
            prevPlusDM += diffP;
        }

        var tempTR = prevHigh - prevLow;
        const tempReal3 = @abs(prevHigh - prevClose);
        if (tempReal3 > tempTR) {
            tempTR = tempReal3;
        }
        const tempReal4 = @abs(prevLow - prevClose);
        if (tempReal4 > tempTR) {
            tempTR = tempReal4;
        }

        prevTR = prevTR - (prevTR / inTimePeriodF) + tempTR;
        prevClose = inClose[today];

        if (!(math.approxEqAbs(f64, prevTR, 0.0, 0.00000000000001))) {
            const minusDI = 100.0 * (prevMinusDM / prevTR);
            const plusDI = 100.0 * (prevPlusDM / prevTR);
            const tempSum = minusDI + plusDI;
            if (!(math.approxEqAbs(f64, tempSum, 0.0, 0.00000000000001))) {
                outReal[outIdx] = 100.0 * (@abs(minusDI - plusDI) / tempSum);
            } else {
                outReal[outIdx] = outReal[outIdx - 1];
            }
        } else {
            outReal[outIdx] = outReal[outIdx - 1];
        }
        outIdx += 1;
    }

    return outReal;
}

test "Dx work correctly " {
    var allocator = std.testing.allocator;

    // Trend reversals and choppy data: up, down, up, down, flat, up, down, up, down, up
    const highs = [_]f64{ 10, 12, 11, 13, 13, 14, 13, 15, 14, 100, 17, 16, 18, 17, 19, 21, 23, 22, 25, 24, 27, 29, 28, 30, 32, 31, 35, 34, 36, 38 };
    const lows = [_]f64{ 8, 9, 9, 10, 12, 12, 12, 13, 13, 14, 100, 15, 16, 16, 17, 18, 19, 18, 20, 21, 22, 24, 23, 25, 26, 27, 28, 29, 30, 31 };
    const closes = [_]f64{ 8, 9, 9, 10, 12, 12, 12, 13, 13, 14, 100, 15, 16, 16, 17, 19, 20, 21, 23, 22, 24, 26, 25, 27, 29, 28, 32, 33, 34, 35 };

    const adx = try Dx(&highs, &lows, &closes, 5, allocator);
    defer allocator.free(adx);

    const expected = [_]f64{ 0, 0, 0, 0, 0, 100, 100, 100, 100, 100, 100, 19.75187006774451, 17.679467667485966, 17.67946766748596, 14.581156656443875, 10.930383547745674, 6.681538206967594, 8.863233239693006, 0.08835144073209814, 0.08835144073210846, 11.107226757123437, 18.68676877809035, 12.68180591808232, 22.486326193263842, 32.026788234572685, 32.026788234572685, 50.90868987882754, 50.90868987882755, 59.66266275275333, 67.01502292272959 };
    for (adx, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}
