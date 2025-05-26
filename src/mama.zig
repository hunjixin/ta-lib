const std = @import("std");
const MyError = @import("./lib.zig").MyError;
/// Calculates the MESA Adaptive Moving Average (MAMA) and Following Adaptive Moving Average (FAMA) for a given array of prices.
///
/// - `prices`: Slice of input price data as f64 values.
/// - `inFastLimit`: Fast limit parameter for the MAMA calculation.
/// - `inSlowLimit`: Slow limit parameter for the MAMA calculation.
/// - `allocator`: Allocator used for memory allocation of the output arrays.
///
/// Returns a struct containing two slices:
///   - The first slice is the calculated MAMA values.
///   - The second slice is the calculated FAMA values.
///
/// Returns an error if memory allocation fails.
pub fn MAMA(prices: []const f64, inFastLimit: f64, inSlowLimit: f64, allocator: std.mem.Allocator) !struct { []f64, []f64 } {
    const math = std.math;
    if (prices.len == 0) return error.InvalidInput;

    var outMAMA = try allocator.alloc(f64, prices.len);
    var outFAMA = try allocator.alloc(f64, prices.len);

    const a = 0.0962;
    const b = 0.5769;
    var detrenderOdd = [_]f64{ 0.0, 0.0, 0.0 };
    var detrenderEven = [_]f64{ 0.0, 0.0, 0.0 };
    var q1Odd = [_]f64{ 0.0, 0.0, 0.0 };
    var q1Even = [_]f64{ 0.0, 0.0, 0.0 };
    var jIOdd = [_]f64{ 0.0, 0.0, 0.0 };
    var jIEven = [_]f64{ 0.0, 0.0, 0.0 };
    var jQOdd = [_]f64{ 0.0, 0.0, 0.0 };
    var jQEven = [_]f64{ 0.0, 0.0, 0.0 };
    const one: f64 = 1.0;
    const rad2Deg = 180.0 / (4.0 * std.math.atan(one));
    const lookbackTotal = 32;
    const startIdx = lookbackTotal;
    var trailingWMAIdx: usize = startIdx - lookbackTotal;
    var today: usize = trailingWMAIdx;
    var tempReal: f64 = prices[today];
    today += 1;
    var periodWMASub = tempReal;
    var periodWMASum = tempReal;
    tempReal = prices[today];
    today += 1;
    periodWMASub += tempReal;
    periodWMASum += tempReal * 2.0;
    tempReal = prices[today];
    today += 1;
    periodWMASub += tempReal;
    periodWMASum += tempReal * 3.0;
    var trailingWMAValue: f64 = 0.0;
    var i: usize = 9;
    var smoothedValue: f64 = 0.0;
    while (i != 0) {
        tempReal = prices[today];
        today += 1;
        periodWMASub += tempReal;
        periodWMASub -= trailingWMAValue;
        periodWMASum += tempReal * 4.0;
        trailingWMAValue = prices[trailingWMAIdx];
        trailingWMAIdx += 1;
        // smoothedValue = periodWMASum * 0.1;
        periodWMASum -= periodWMASub;
        i -= 1;
    }
    var hilbertIdx: usize = 0;
    var detrender: f64 = 0.0;
    var prevDetrenderOdd: f64 = 0.0;
    var prevDetrenderEven: f64 = 0.0;
    var prevDetrenderInputOdd: f64 = 0.0;
    var prevDetrenderInputEven: f64 = 0.0;

    var q1: f64 = 0.0;
    var prevq1Odd: f64 = 0.0;
    var prevq1Even: f64 = 0.0;
    var prevq1InputOdd: f64 = 0.0;
    var prevq1InputEven: f64 = 0.0;

    var jI: f64 = 0.0;
    var prevjIOdd: f64 = 0.0;
    var prevjIEven: f64 = 0.0;
    var prevjIInputOdd: f64 = 0.0;
    var prevjIInputEven: f64 = 0.0;

    var jQ: f64 = 0.0;
    var prevjQOdd: f64 = 0.0;
    var prevjQEven: f64 = 0.0;
    var prevjQInputOdd: f64 = 0.0;
    var prevjQInputEven: f64 = 0.0;

    var period: f64 = 0.0;
    var outIdx: usize = startIdx;
    var previ2: f64 = 0.0;
    var prevq2: f64 = 0.0;
    var Re: f64 = 0.0;
    var Im: f64 = 0.0;
    var mama: f64 = 0.0;
    var fama: f64 = 0.0;
    var i1ForOddPrev3: f64 = 0.0;
    var i1ForEvenPrev3: f64 = 0.0;
    var i1ForOddPrev2: f64 = 0.0;
    var i1ForEvenPrev2: f64 = 0.0;
    var prevPhase: f64 = 0.0;
    var adjustedPrevPeriod: f64 = 0.0;
    var todayValue: f64 = 0.0;
    var hilbertTempReal: f64 = 0.0;

    while (today < prices.len) {
        adjustedPrevPeriod = (0.075 * period) + 0.54;
        todayValue = prices[today];

        periodWMASub += todayValue;
        periodWMASub -= trailingWMAValue;
        periodWMASum += todayValue * 4.0;
        trailingWMAValue = prices[trailingWMAIdx];
        trailingWMAIdx += 1;
        smoothedValue = periodWMASum * 0.1;
        periodWMASum -= periodWMASub;
        var q2: f64 = 0.0;
        var ii2: f64 = 0.0;
        var tempReal2: f64 = 0.0;
        if ((today & 1) == 0) {
            hilbertTempReal = a * smoothedValue;
            detrender = -detrenderEven[hilbertIdx];
            detrenderEven[hilbertIdx] = hilbertTempReal;
            detrender += hilbertTempReal;
            detrender -= prevDetrenderEven;
            prevDetrenderEven = b * prevDetrenderInputEven;
            detrender += prevDetrenderEven;
            prevDetrenderInputEven = smoothedValue;
            detrender *= adjustedPrevPeriod;

            hilbertTempReal = a * detrender;
            q1 = -q1Even[hilbertIdx];
            q1Even[hilbertIdx] = hilbertTempReal;
            q1 += hilbertTempReal;
            q1 -= prevq1Even;
            prevq1Even = b * prevq1InputEven;
            q1 += prevq1Even;
            prevq1InputEven = detrender;
            q1 *= adjustedPrevPeriod;

            hilbertTempReal = a * i1ForEvenPrev3;
            jI = -jIEven[hilbertIdx];
            jIEven[hilbertIdx] = hilbertTempReal;
            jI += hilbertTempReal;
            jI -= prevjIEven;
            prevjIEven = b * prevjIInputEven;
            jI += prevjIEven;
            prevjIInputEven = i1ForEvenPrev3;
            jI *= adjustedPrevPeriod;

            hilbertTempReal = a * q1;
            jQ = -jQEven[hilbertIdx];
            jQEven[hilbertIdx] = hilbertTempReal;
            jQ += hilbertTempReal;
            jQ -= prevjQEven;
            prevjQEven = b * prevjQInputEven;
            jQ += prevjQEven;
            prevjQInputEven = q1;
            jQ *= adjustedPrevPeriod;

            hilbertIdx += 1;
            if (hilbertIdx == 3) hilbertIdx = 0;

            q2 = (0.2 * (q1 + jI)) + (0.8 * prevq2);
            ii2 = (0.2 * (i1ForEvenPrev3 - jQ)) + (0.8 * previ2);
            i1ForOddPrev3 = i1ForOddPrev2;
            i1ForOddPrev2 = detrender;
            if (i1ForEvenPrev3 != 0.0) {
                tempReal2 = math.atan(q1 / i1ForEvenPrev3) * rad2Deg;
            } else {
                tempReal2 = 0.0;
            }
        } else {
            hilbertTempReal = a * smoothedValue;
            detrender = -detrenderOdd[hilbertIdx];
            detrenderOdd[hilbertIdx] = hilbertTempReal;
            detrender += hilbertTempReal;
            detrender -= prevDetrenderOdd;
            prevDetrenderOdd = b * prevDetrenderInputOdd;
            detrender += prevDetrenderOdd;
            prevDetrenderInputOdd = smoothedValue;
            detrender *= adjustedPrevPeriod;

            hilbertTempReal = a * detrender;
            q1 = -q1Odd[hilbertIdx];
            q1Odd[hilbertIdx] = hilbertTempReal;
            q1 += hilbertTempReal;
            q1 -= prevq1Odd;
            prevq1Odd = b * prevq1InputOdd;
            q1 += prevq1Odd;
            prevq1InputOdd = detrender;
            q1 *= adjustedPrevPeriod;

            hilbertTempReal = a * i1ForOddPrev3;
            jI = -jIOdd[hilbertIdx];
            jIOdd[hilbertIdx] = hilbertTempReal;
            jI += hilbertTempReal;
            jI -= prevjIOdd;
            prevjIOdd = b * prevjIInputOdd;
            jI += prevjIOdd;
            prevjIInputOdd = i1ForOddPrev3;
            jI *= adjustedPrevPeriod;

            hilbertTempReal = a * q1;
            jQ = -jQOdd[hilbertIdx];
            jQOdd[hilbertIdx] = hilbertTempReal;
            jQ += hilbertTempReal;
            jQ -= prevjQOdd;
            prevjQOdd = b * prevjQInputOdd;
            jQ += prevjQOdd;
            prevjQInputOdd = q1;
            jQ *= adjustedPrevPeriod;

            q2 = (0.2 * (q1 + jI)) + (0.8 * prevq2);
            ii2 = (0.2 * (i1ForOddPrev3 - jQ)) + (0.8 * previ2);
            i1ForEvenPrev3 = i1ForEvenPrev2;
            i1ForEvenPrev2 = detrender;
            if (i1ForOddPrev3 != 0.0) {
                tempReal2 = math.atan(q1 / i1ForOddPrev3) * rad2Deg;
            } else {
                tempReal2 = 0.0;
            }
        }
        tempReal = prevPhase - tempReal2;
        prevPhase = tempReal2;
        if (tempReal < 1.0) {
            tempReal = 1.0;
        }
        if (tempReal > 1.0) {
            tempReal = inFastLimit / tempReal;
            if (tempReal < inSlowLimit) {
                tempReal = inSlowLimit;
            }
        } else {
            tempReal = inFastLimit;
        }
        mama = (tempReal * todayValue) + ((1.0 - tempReal) * mama);
        tempReal *= 0.5;
        fama = (tempReal * mama) + ((1.0 - tempReal) * fama);
        if (today >= startIdx) {
            outMAMA[outIdx] = mama;
            outFAMA[outIdx] = fama;
            outIdx += 1;
        }
        Re = (0.2 * ((ii2 * previ2) + (q2 * prevq2))) + (0.8 * Re);
        Im = (0.2 * ((ii2 * prevq2) - (q2 * previ2))) + (0.8 * Im);
        prevq2 = q2;
        previ2 = ii2;
        tempReal = period;
        if (Im != 0.0 and Re != 0.0) {
            period = 360.0 / (math.atan(Im / Re) * rad2Deg);
        }
        tempReal2 = 1.5 * tempReal;
        if (period > tempReal2) {
            period = tempReal2;
        }
        tempReal2 = 0.67 * tempReal;
        if (period < tempReal2) {
            period = tempReal2;
        }
        if (period < 6.0) {
            period = 6.0;
        } else if (period > 50.0) {
            period = 50.0;
        }
        period = (0.2 * period) + (0.8 * tempReal);
        today += 1;
    }
    return .{ outMAMA, outFAMA };
}

test "MAMA work correctly" {
    var allocator = std.testing.allocator;
    const prices = [_]f64{
        82.4, 15.7, 63.2, 91.5, 27.8, 54.6, 39.1, 75.3, 44.2, 10.8, 67.5, 16.2, 23.9, 87.1, 19.6,
        10.1, 12.8, 11.4, 75.9, 13.7, 14.2, 13.5, 15.9, 14.8, 43.3, 32.6, 16.2, 13.4, 17.5, 76.1,
        65.8, 12.6, 11.9, 13.3, 13.7, 13.1, 13.8, 15.4, 14.2, 10.6, 17.3, 43.1, 18.9, 17.7, 19.2,
        1.5,  2.7,  3.6,  4.8,  5.2,  6.4,  7.9,  8.3,  9.1,  9.7,  10.2, 11.6, 12.8, 13.9, 14.5,
    };
    const mama, const fmana = try MAMA(&prices, 0.5, 0.05, allocator);
    defer allocator.free(mama);
    defer allocator.free(fmana);

    {
        const expected = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 30.3185218092, 29.4675957187, 21.5837978593, 21.1596079664, 20.7916275681, 18.0958137840, 17.9010230948, 17.5359719401, 17.5241733431, 18.8029646759, 18.8514823380, 18.7939082211, 18.9969541105, 10.2484770553, 9.8710532025, 9.5575005424, 7.1787502712, 7.0798127576, 7.0458221197, 7.0885310138, 7.1491044631, 7.2466492399, 7.3693167779, 8.7846583890, 8.9254254695, 9.1191541960, 9.3581964862, 11.9290982431 };
        for (mama, 0..) |v, i| {
            try std.testing.expectApproxEqAbs(v, expected[i], 1e-9);
        }
    }

    {
        const expected = [_]f64{
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 29.0351771385, 29.0459876030, 27.1804401671, 27.0299193620, 26.8739620672, 24.6794249964, 24.5099649489, 24.3356151236, 24.1653290791, 24.0312699690, 22.7363230613, 22.6377626903, 21.7275605453, 18.8577896728, 18.6331212611, 18.4062307431, 15.5993606251, 15.3863719284, 15.1778581832, 14.9756250040, 14.7799619905, 14.5916291717, 14.4110713618, 13.0044681186, 12.9024920524, 12.8079086060, 12.7216658030, 12.5235239130,
        };
        for (fmana, 0..) |v, i| {
            try std.testing.expectApproxEqAbs(v, expected[i], 1e-9);
        }
    }
}
