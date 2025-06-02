const std = @import("std");
const math = std.math;

/// Calculates the Hilbert Transform - Dominant Cycle Period (HT_DCPERIOD)
///
/// The HT_DCPERIOD is a technical analysis indicator designed to estimate
/// the dominant cycle length (in bars) in a time series, typically used on
/// financial price data.
///
/// This function implements the indicator based on John Ehlers' work in
/// "Rocket Science for Traders" and is modeled similarly to the TA-Lib implementation.
///
/// # Core Algorithm Steps:
///
/// 1. **Smoothing the input**: A Weighted Moving Average (Wma) is applied over 4 periods
///    to reduce noise and prepare the input signal for Hilbert Transform processing.
///
/// 2. **Hilbert Transform**: The smoothed signal is decomposed using recursive filters
///    to produce in-phase (I) and quadrature (Q) components using discrete Hilbert Transform
///    approximations. The coefficients used include:
///    - `a = 0.0962`
///    - `b = 0.5769`
///
/// 3. **Cycle Phase Estimation**: From the I and Q components, the instantaneous phase difference
///    is computed to estimate the dominant cycle period using:
///
///     ```
///     period = 360 / (atan(Im / Re) * (180 / PI))
///     ```
///
///     where:
///     - `Re = I2 * prevI2 + Q2 * prevQ2`
///     - `Im = I2 * prevQ2 - Q2 * prevI2`
///
///     These represent the real and imaginary parts of a complex signal vector derived from I/Q data.
///
/// 4. **Cycle Clamping & Smoothing**:
///     - The calculated period is clamped between 6 and 50.
///     - A smoothing step ensures stability:
///
///     ```
///     smoothPeriod = 0.33 * period + 0.67 * prevSmoothPeriod
///     ```
///
/// # Parameters:
/// - `inReal`: Slice of input time series values (e.g. closing prices)
/// - `allocator`: Allocator to allocate memory for the output array
///
/// # Returns:
/// - An array of the same length as `inReal`, where each element is the estimated dominant cycle period
///
/// # Notes:
/// - The first `32` elements of the output will be less reliable (warm-up period)
/// - The function assumes `inReal.len >= 64` for accurate results
///
/// # Example:
/// ```zig
/// const htPeriod = try ta.HtDcPeriod(closePrices, allocator);
/// ```
///
/// # References:
/// - John F. Ehlers, "Rocket Science for Traders"
/// - TA-Lib HT_DCPERIOD source implementation
pub fn HtDcPeriod(inReal: []const f64, allocator: std.mem.Allocator) ![]f64 {
    const len = inReal.len;
    var outReal = try allocator.alloc(f64, len);
    @memset(outReal, 0);

    const a = 0.0962;
    const b = 0.5769;
    var detrenderOdd = [_]f64{0} ** 3;
    var detrenderEven = [_]f64{0} ** 3;
    var q1Odd = [_]f64{0} ** 3;
    var q1Even = [_]f64{0} ** 3;
    var jIOdd = [_]f64{0} ** 3;
    var jIEven = [_]f64{0} ** 3;
    var jQOdd = [_]f64{0} ** 3;
    var jQEven = [_]f64{0} ** 3;
    const rad2Deg = 180.0 / (4.0 * math.atan(@as(f64, 1.0)));
    const lookbackTotal: usize = 32;
    const startIdx = lookbackTotal;
    var trailingWMAIdx: usize = startIdx - lookbackTotal;
    var today: usize = trailingWMAIdx;

    var tempReal = inReal[today];
    today += 1;
    var periodWMASub = tempReal;
    var periodWMASum = tempReal;

    tempReal = inReal[today];
    today += 1;
    periodWMASub += tempReal;
    periodWMASum += tempReal * 2.0;

    tempReal = inReal[today];
    today += 1;
    periodWMASub += tempReal;
    periodWMASum += tempReal * 3.0;

    var trailingWMAValue: f64 = 0.0;
    var i: i32 = 9;
    var smoothedValue: f64 = 0.0;

    while (i != 0) {
        tempReal = inReal[today];
        today += 1;
        periodWMASub += tempReal;
        periodWMASub -= trailingWMAValue;
        periodWMASum += tempReal * 4.0;
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
    var outIdx = lookbackTotal;
    var previ2: f64 = 0.0;
    var prevq2: f64 = 0.0;
    var Re: f64 = 0.0;
    var Im: f64 = 0.0;
    var ii2: f64 = 0.0;
    var q2: f64 = 0.0;
    var i1ForOddPrev3: f64 = 0.0;
    var i1ForEvenPrev3: f64 = 0.0;
    var i1ForOddPrev2: f64 = 0.0;
    var i1ForEvenPrev2: f64 = 0.0;
    var smoothPeriod: f64 = 0.0;

    while (today < len) {
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
        if ((today % 2) == 0) {
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

            hilbertIdx = (hilbertIdx + 1) % 3;

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

        const tempPeriod = period;
        if (Im != 0.0 and Re != 0.0) {
            period = 360.0 / (math.atan(Im / Re) * rad2Deg);
        }

        var temp2 = 1.5 * tempPeriod;
        if (period > temp2) {
            period = temp2;
        }

        temp2 = 0.67 * tempPeriod;
        if (period < temp2) {
            period = temp2;
        }

        if (period < 6.0) {
            period = 6.0;
        } else if (period > 50.0) {
            period = 50.0;
        }

        period = (0.2 * period) + (0.8 * tempPeriod);
        smoothPeriod = (0.33 * period) + (0.67 * smoothPeriod);

        if (today >= startIdx) {
            outReal[outIdx] = smoothPeriod;
            outIdx += 1;
        }

        today += 1;
    }

    return outReal;
}

test "HtDcPeriod work correctly" {
    var allocator = std.testing.allocator;
    const prices = [_]f64{
        82.4, 15.7, 63.2, 91.5, 27.8, 54.6, 39.1, 75.3, 44.2, 10.8, 67.5, 16.2, 23.9, 87.1, 19.6,
        10.1, 12.8, 11.4, 75.9, 13.7, 14.2, 13.5, 15.9, 14.8, 43.3, 32.6, 16.2, 13.4, 17.5, 76.1,
        65.8, 12.6, 11.9, 13.3, 13.7, 13.1, 13.8, 15.4, 14.2, 10.6, 17.3, 43.1, 18.9, 17.7, 19.2,
    };
    const result = try HtDcPeriod(&prices, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 11.01413133149039, 11.078560509576791, 11.491637310642503, 11.862209566274696, 11.886530793859023, 11.92531421047681, 12.347432957469852, 12.710058564748794, 12.74895559060974, 12.621166815012625, 12.497115922161267, 12.462250807582187, 12.515784344417638 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}
