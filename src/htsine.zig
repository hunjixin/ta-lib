const std = @import("std");
const math = std.math;

/// HtSine calculates the Sine and Lead Sine components of a time series using
/// the Hilbert Transform SineWave method.
///
/// This function applies the Hilbert Transform to detect the dominant cycle
/// and derive a smooth sine wave and its lead counterpart. These are used to
/// identify market cycles and generate entry/exit signals.
///
/// ## Theory and Formulas:
///
/// The core idea is to use the In-Phase (I) and Quadrature (Q) components,
/// computed via Hilbert Transform, to estimate the dominant cycle and its phase.
///
/// The Sine and Lead Sine components are defined as:
/// ```
/// Sine      = sin(phase)
/// LeadSine  = sin(phase + 45°)
/// ```
/// where `phase = atan2(Q, I)` is the instantaneous phase of the signal derived from:
/// - Q: Quadrature component
/// - I: In-Phase component
///
/// The phase is smoothed over time to reduce noise. The cycle-based sine wave provides a
/// clear and cyclical indicator to align with turning points in market momentum.
///
/// ## Parameters:
/// - `inReal`: a slice of real-valued time series input (e.g. prices)
/// - `allocator`: allocator for dynamic memory allocation
///
/// ## Returns:
/// A struct with two fields:
/// - `sine`:     The Sine wave values derived from the dominant cycle
/// - `leadSine`: The Lead Sine wave (phase shifted by 45 degrees)
///
/// ## Usage:
/// - Used to detect cyclical turning points
/// - Entry signals are generated when Sine crosses Lead Sine
/// - Lead/lag behavior can indicate continuation or reversal trends
///
/// Reference: John Ehlers, "Rocket Science for Traders", 2001.
pub fn HtSine(inReal: []const f64, allocator: std.mem.Allocator) !struct { []f64, []f64 } {
    const outSine = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outSine);
    const outLeadSine = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outLeadSine);

    @memset(outSine, 0.0);
    @memset(outLeadSine, 0.0);

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
    const deg2Rad: f64 = 1.0 / rad2Deg;
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
    var outIdx: usize = 63;
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
    var hilbertTempReal: f64 = 0.0;
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

        smoothPrice[smoothPriceIdx] = smoothedValue;

        if (today % 2 == 0) {
            // Even day calculation
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
            // Odd day calculation
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

        var ii3: usize = 0;
        while (ii3 < @as(usize, @intFromFloat(DCPeriodInt))) : (ii3 += 1) {
            const tempReal5 = (@as(f64, @floatFromInt(ii3)) * constDeg2RadBy360) / DCPeriodInt;
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
            outSine[outIdx] = math.sin(dcPhase * deg2Rad);
            outLeadSine[outIdx] = math.sin((dcPhase + 45) * deg2Rad);
            outIdx += 1;
        }

        smoothPriceIdx += 1;
        if (smoothPriceIdx > maxIdxSmoothPrice) {
            smoothPriceIdx = 0;
        }

        today += 1;
    }

    return .{ outSine, outLeadSine };
}

test "HtSine work correctly" {
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
    const result1, const result2 = try HtSine(&prices, allocator);
    defer allocator.free(result1);
    defer allocator.free(result2);
    {
        const expected = [_]f64{
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -0.8054234481836359, -0.8788789683642892, -0.8714401808914891, -0.8717537870449541, -0.8534331080589961, -0.8321422845849583, -0.8100343297699533, -0.8418742309510645, -0.8840379331205565, -0.8832298879259829, -0.49040608655707907, -0.5605572455865833, -0.6462734679721165, -0.7299533902586671, -0.7972413413846803, -0.8051224126410216, -0.6664587453711182, 0.1881615294707592, 0.6121029289755424, 0.5546799237315236, 0.3405424738781243, 0.26031666726838654, 0.24116116374861532, 0.2109372193332064, 0.2463558316984052, 0.2757538813329909, 0.29888474587743574, 0.33533529051313044, 0.3388740852641238, 0.3357796731387057, 0.33186863266624317, 0.34706636856856743, 0.3653398499142346, 0.38837719616065614, 0.40979336123832383, 0.42452098445044756, 0.4295473216017694,
        };
        for (result1, 0..) |v, i| {
            try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
        }
    }
    {
        const expected = [_]f64{
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -0.9886224393863081, -0.9587829045448316, -0.9630384069009633, -0.962865891867503, -0.972014081473768, -0.9805481346935279, -0.987415778514062, -0.9769019608159939, -0.9556216473621022, -0.9561286791261617, -0.9630088182406326, -0.9819400403800399, -0.9965817037153677, -0.9994603035994151, -0.9905873349177976, -0.988698683917335, -0.9984352389990282, -0.5614262140126303, -0.1263424254634246, -0.19614002624889545, -0.42404250360679246, -0.49865638844363386, -0.5157098878089158, -0.5420414653482957, -0.5111134813316321, -0.48470359219110487, -0.4634409455800027, -0.4290466274019181, -0.4256483363984332, -0.4286204707872477, -0.43236537663955943, -0.4177404443858739, -0.39989318071496716, -0.37697509644811084, -0.35523985513970435, -0.340045610659053, -0.33481295982348164,
        };
        for (result2, 0..) |v, i| {
            try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
        }
    }
}
