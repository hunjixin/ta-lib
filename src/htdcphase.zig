const std = @import("std");
const math = std.math;

/// Calculates the Hilbert Transform - Dominant Cycle Phase (HT_DCPHASE)
///
/// The HT_DCPHASE indicator estimates the phase angle of the dominant cycle
/// in a time series, often used in technical analysis to identify cycle
/// turning points or shifts in trend.
///
/// This function implements the indicator based on John Ehlers' work
/// ("Rocket Science for Traders") and follows the methodology used
/// in TA-Lib.
///
/// # Core Algorithm Steps:
///
/// 1. **Input Smoothing**: The input signal is smoothed using a Weighted Moving Average (Wma)
///    over 4 periods to reduce noise.
///
/// 2. **Hilbert Transform Components**: Recursive filters approximate the Hilbert Transform,
///    generating in-phase (I) and quadrature (Q) components of the smoothed input,
///    using coefficients:
///    - `a = 0.0962`
///    - `b = 0.5769`
///
/// 3. **Phase Calculation**:
///    The phase angle is calculated from the I and Q components as:
///
///    ```
///    phase = atan(Q / I) * (180 / PI)
///    ```
///
///    - The angle is converted from radians to degrees.
///    - The phase indicates the position within the cycle: 0 to 360 degrees.
///
/// 4. **Phase Adjustment and Unwrapping**:
///    - To avoid abrupt jumps, the phase difference between consecutive points is computed.
///    - Negative differences are adjusted by adding 360 degrees.
///    - Phase values are smoothed to reduce noise and maintain continuity.
///
/// 5. **Output**:
///    - The result is an array of phase values (degrees) corresponding to each input data point.
///
/// # Parameters:
/// - `inReal`: Slice of input values (e.g., closing prices)
/// - `allocator`: Memory allocator for the output buffer
///
/// # Returns:
/// - A slice of floats representing the dominant cycle phase angle in degrees.
///
/// # Notes:
/// - The initial output values are less reliable due to the filter warm-up period.
/// - Input length should be sufficiently long (>= 64 samples) for stable results.
///
/// # Usage Example:
/// ```zig
/// const htPhase = try ta.HtDcPhase(closePrices, allocator);
/// ```
///
/// # References:
/// - John F. Ehlers, "Rocket Science for Traders"
/// - TA-Lib HT_DCPHASE function
pub fn HtDcPhase(inReal: []const f64, allocator: std.mem.Allocator) ![]f64 {
    const len = inReal.len;
    var outReal = try allocator.alloc(f64, len);
    errdefer allocator.free(outReal);
    @memset(outReal, 0);

    const a: f64 = 0.0962;
    const b: f64 = 0.5769;
    var detrenderOdd = [3]f64{ 0.0, 0.0, 0.0 };
    var detrenderEven = [3]f64{ 0.0, 0.0, 0.0 };
    var q1Odd = [3]f64{ 0.0, 0.0, 0.0 };
    var q1Even = [3]f64{ 0.0, 0.0, 0.0 };
    var jIOdd = [3]f64{ 0.0, 0.0, 0.0 };
    var jIEven = [3]f64{ 0.0, 0.0, 0.0 };
    var jQOdd = [3]f64{ 0.0, 0.0, 0.0 };
    var jQEven = [3]f64{ 0.0, 0.0, 0.0 };

    var smoothPriceIdx: usize = 0;
    const maxIdxSmoothPrice: usize = 50 - 1;
    var smoothPrice = [_]f64{0.0} ** (maxIdxSmoothPrice + 1);

    const tempReal = math.atan(@as(f64, 1.0));
    const rad2Deg: f64 = 45.0 / tempReal;
    const constDeg2RadBy360: f64 = tempReal * 8.0;

    const lookbackTotal: usize = 63;
    const startIdx: usize = lookbackTotal;
    var trailingWMAIdx: usize = startIdx - lookbackTotal;
    var today: usize = trailingWMAIdx;

    var tempReal1: f64 = inReal[today];
    today += 1;
    var periodWMASub: f64 = tempReal1;
    var periodWMASum: f64 = tempReal1;
    tempReal1 = inReal[today];
    today += 1;
    periodWMASub += tempReal1;
    periodWMASum += tempReal1 * 2.0;
    tempReal1 = inReal[today];
    today += 1;
    periodWMASub += tempReal1;
    periodWMASum += tempReal1 * 3.0;

    var trailingWMAValue: f64 = 0.0;
    var i: usize = 34;
    var smoothedValue: f64 = 0.0;

    while (i != 0) {
        tempReal1 = inReal[today];
        today += 1;
        periodWMASub += tempReal1;
        periodWMASub -= trailingWMAValue;
        periodWMASum += tempReal1 * 4.0;
        trailingWMAValue = inReal[trailingWMAIdx];
        trailingWMAIdx += 1;
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
    var prevJIOdd: f64 = 0.0;
    var prevJIEven: f64 = 0.0;
    var prevJIInputOdd: f64 = 0.0;
    var prevJIInputEven: f64 = 0.0;
    var jQ: f64 = 0.0;
    var prevJQOdd: f64 = 0.0;
    var prevJQEven: f64 = 0.0;
    var prevJQInputOdd: f64 = 0.0;
    var prevJQInputEven: f64 = 0.0;
    var period: f64 = 0.0;
    var outIdx: usize = 0;
    var previ2: f64 = 0.0;
    var prevq2: f64 = 0.0;
    var Re: f64 = 0.0;
    var Im: f64 = 0.0;
    var i1ForOddPrev3: f64 = 0.0;
    var i1ForEvenPrev3: f64 = 0.0;
    var i1ForOddPrev2: f64 = 0.0;
    var i1ForEvenPrev2: f64 = 0.0;
    var smoothPeriod: f64 = 0.0;
    var dcPhase: f64 = 0.0;
    var q2: f64 = 0.0;
    var ii2: f64 = 0.0;

    while (today < inReal.len) {
        const adjustedPrevPeriod = (0.075 * period) + 0.54;
        const todayValue = inReal[today];
        periodWMASub += todayValue;
        periodWMASub -= trailingWMAValue;
        periodWMASum += todayValue * 4.0;
        trailingWMAValue = inReal[trailingWMAIdx];
        trailingWMAIdx += 1;
        smoothedValue = periodWMASum * 0.1;
        periodWMASum -= periodWMASub;

        var hilbertTempReal: f64 = 0.0;
        smoothPrice[smoothPriceIdx] = smoothedValue;

        if (today % 2 == 0) {
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
            jI -= prevJIEven;
            prevJIEven = b * prevJIInputEven;
            jI += prevJIEven;
            prevJIInputEven = i1ForEvenPrev3;
            jI *= adjustedPrevPeriod;

            hilbertTempReal = a * q1;
            jQ = -jQEven[hilbertIdx];
            jQEven[hilbertIdx] = hilbertTempReal;
            jQ += hilbertTempReal;
            jQ -= prevJQEven;
            prevJQEven = b * prevJQInputEven;
            jQ += prevJQEven;
            prevJQInputEven = q1;
            jQ *= adjustedPrevPeriod;

            hilbertIdx += 1;
            if (hilbertIdx == 3) {
                hilbertIdx = 0;
            }

            q2 = (0.2 * (q1 + jI)) + (0.8 * prevq2);
            ii2 = (0.2 * (i1ForEvenPrev3 - jQ)) + (0.8 * previ2);
            i1ForOddPrev3 = i1ForOddPrev2;
            i1ForOddPrev2 = detrender;
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
            jI -= prevJIOdd;
            prevJIOdd = b * prevJIInputOdd;
            jI += prevJIOdd;
            prevJIInputOdd = i1ForOddPrev3;
            jI *= adjustedPrevPeriod;

            hilbertTempReal = a * q1;
            jQ = -jQOdd[hilbertIdx];
            jQOdd[hilbertIdx] = hilbertTempReal;
            jQ += hilbertTempReal;
            jQ -= prevJQOdd;
            prevJQOdd = b * prevJQInputOdd;
            jQ += prevJQOdd;
            prevJQInputOdd = q1;
            jQ *= adjustedPrevPeriod;

            q2 = (0.2 * (q1 + jI)) + (0.8 * prevq2);
            ii2 = (0.2 * (i1ForOddPrev3 - jQ)) + (0.8 * previ2);
            i1ForEvenPrev3 = i1ForEvenPrev2;
            i1ForEvenPrev2 = detrender;
        }

        Re = (0.2 * ((ii2 * previ2) + (q2 * prevq2))) + (0.8 * Re);
        Im = (0.2 * ((ii2 * prevq2) - (q2 * previ2))) + (0.8 * Im);
        prevq2 = q2;
        previ2 = ii2;

        const tempReal3 = period;
        if (Im != 0.0 and Re != 0.0) {
            period = 360.0 / (math.atan(Im / Re) * rad2Deg);
        }

        const tempReal2 = 1.5 * tempReal3;
        if (period > tempReal2) {
            period = tempReal2;
        }

        const tempReal4 = 0.67 * tempReal3;
        if (period < tempReal4) {
            period = tempReal4;
        }

        if (period < 6) {
            period = 6;
        } else if (period > 50) {
            period = 50;
        }

        period = (0.2 * period) + (0.8 * tempReal3);
        smoothPeriod = (0.33 * period) + (0.67 * smoothPeriod);
        const DCPeriod = smoothPeriod + 0.5;
        const DCPeriodInt = math.floor(DCPeriod);

        var realPart: f64 = 0.0;
        var imagPart: f64 = 0.0;
        var idx: usize = smoothPriceIdx;

        var j: usize = 0;
        while (j < @as(usize, @intFromFloat(DCPeriodInt))) : (j += 1) {
            const tempReal5 = (@as(f64, @floatFromInt(j)) * constDeg2RadBy360) / DCPeriodInt;
            const tempReal6 = smoothPrice[idx];
            realPart += math.sin(tempReal5) * tempReal6;
            imagPart += math.cos(tempReal5) * tempReal6;

            if (idx == 0) {
                idx = 50 - 1;
            } else {
                idx -= 1;
            }
        }

        const tempReal7 = @abs(imagPart);
        if (tempReal7 > 0.0) {
            dcPhase = math.atan(realPart / imagPart) * rad2Deg;
        } else if (tempReal7 <= 0.01) {
            if (realPart < 0.0) {
                dcPhase -= 90.0;
            } else if (realPart > 0.0) {
                dcPhase += 90.0;
            }
        }

        dcPhase += 90.0;
        dcPhase += 360.0 / smoothPeriod;
        if (imagPart < 0.0) {
            dcPhase += 180.0;
        }
        if (dcPhase > 315.0) {
            dcPhase -= 360.0;
        }

        if (today >= startIdx) {
            outReal[outIdx] = dcPhase;
            outIdx += 1;
        }

        smoothPriceIdx += 1;
        if (smoothPriceIdx > maxIdxSmoothPrice) {
            smoothPriceIdx = 0;
        }

        today += 1;
    }

    return outReal;
}
test "HtDcPhase work correctly" {
    var allocator = std.testing.allocator;
    const prices = [_]f64{
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

        130.20, 129.40, 128.60, 129.20, 129.80,
        129.10, 128.40, 128.90, 129.40, 128.70,
        129.30, 129.90, 130.50, 130.00, 129.50,
        130.10, 130.70, 131.30, 130.80, 130.30,

        130.90, 131.50, 132.10, 132.70, 133.30,
        133.90, 134.50, 135.10, 135.70, 136.30,
        136.90, 137.50, 138.10, 138.70, 139.30,
        139.90, 140.50, 141.10, 141.70, 142.30,
    };
    const result = try HtDcPhase(&prices, allocator);
    defer allocator.free(result);

    const expected = [_]f64{
        233.65116984500827, 241.50742833239255, 240.62643154461477, 240.66308488035088, 238.58706003149473, 236.31943546084844, 234.0992856633515, 237.33856620350363, 242.13336055561314, 242.03447167881455, 209.3672759594716, 214.0943437517444, 220.2612230033994, 226.88248673774808, 232.86747150026986, 233.6220790333538, 221.79433390525946, 169.15448743546426, 142.25828576284323, 146.31132844599972, 160.0900720524462, 164.91114711614483, 166.04491668714286, 167.82271866276153, 165.7380266726272, 163.99305440302507, 162.6093693062374, 160.4070719287082, 160.1917078928213, 160.3800435678551, 160.61776680809302, 159.69201427273052, 158.57150085957235, 157.14643857004398, 155.80814526008595, 154.87965294129876, 154.56116453278264, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}
