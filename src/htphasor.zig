const std = @import("std");
const math = std.math;

/// HtPhasor calculates the In-Phase (I) and Quadrature (Q) components of a time series using
/// the Hilbert Transform Phasor approach.
///
/// This function decomposes the input real-valued signal `inReal` into two orthogonal components:
/// the In-Phase component (I) and the Quadrature component (Q), which represent the signal as
/// a complex phasor. These components can be used to analyze the instantaneous phase and dominant
/// cycles of the input.
///
/// ## Theory and formulas:
///
/// The Hilbert Transform is used to generate a 90-degree phase-shifted version of the input signal.
/// Using weighted moving averages (Wma) and smoothing, the function calculates the components:
///
/// - Detrender: a bandpass filter approximating the Hilbert Transform of the signal.
/// - I (In-Phase): represents the original signal component.
/// - Q (Quadrature): represents the 90-degree phase shifted component.
///
/// Formulas (simplified):
/// ```
/// detrender[n] = alpha * price[n] - alpha * price[n-2] + beta * detrender[n-1]
/// Q[n] = alpha * detrender[n] - alpha * detrender[n-2] + beta * Q[n-1]
/// I[n] = detrender[n-1]
/// ```
/// where alpha and beta are smoothing coefficients.
///
/// The phasor components I and Q can then be used to compute:
/// - Instantaneous phase: phase = atan2(Q, I)
/// - Dominant cycle period and other derived metrics.
///
/// ## Parameters:
/// - `inReal`: input slice of real-valued time series data (e.g. prices).
/// - `allocator`: memory allocator used to allocate output slices.
///
/// ## Returns:
/// A struct containing two slices:
/// - `inPhase`: the In-Phase component (I) slice.
/// - `quadrature`: the Quadrature component (Q) slice.
///
/// ## Usage:
/// This function is used in cycle analysis, phase detection, and trend filtering in financial
/// technical analysis.
///
/// Reference: John Ehlers, "Cybernetic Analysis for Stocks and Futures", 2004.
pub fn HtPhasor(inReal: []const f64, allocator: std.mem.Allocator) !struct { []f64, []f64 } {
    const outInPhase = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outInPhase);
    const outQuadrature = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outQuadrature);

    @memset(outInPhase, 0.0);
    @memset(outQuadrature, 0.0);

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

    const rad2Deg: f64 = 180.0 / (4.0 * math.atan(@as(f64, 1.0)));
    const lookbackTotal: usize = 32;
    const startIdx: usize = lookbackTotal;
    var trailingWMAIdx: usize = startIdx - lookbackTotal;
    var today: usize = trailingWMAIdx;

    var tempReal: f64 = inReal[today];
    today += 1;
    var periodWMASub: f64 = tempReal;
    var periodWMASum: f64 = tempReal;

    tempReal = inReal[today];
    today += 1;
    periodWMASub += tempReal;
    periodWMASum += tempReal * 2.0;

    tempReal = inReal[today];
    today += 1;
    periodWMASub += tempReal;
    periodWMASum += tempReal * 3.0;

    var trailingWMAValue: f64 = 0.0;
    var i: usize = 9;
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
    var outIdx: usize = 32;
    var previ2: f64 = 0.0;
    var prevq2: f64 = 0.0;
    var Re: f64 = 0.0;
    var Im: f64 = 0.0;
    var i1ForOddPrev3: f64 = 0.0;
    var i1ForEvenPrev3: f64 = 0.0;
    var i1ForOddPrev2: f64 = 0.0;
    var i1ForEvenPrev2: f64 = 0.0;
    var ii2: f64 = 0.0;
    var q2: f64 = 0.0;

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

            if (today >= startIdx) {
                outQuadrature[outIdx] = q1;
                outInPhase[outIdx] = i1ForEvenPrev3;
                outIdx += 1;
            }

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

            if (today >= startIdx) {
                outQuadrature[outIdx] = q1;
                outInPhase[outIdx] = i1ForOddPrev3;
                outIdx += 1;
            }

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
        today += 1;
    }

    return .{ outInPhase, outQuadrature };
}

test "HtPhasor work correctly" {
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
    const result1, const result2 = try HtPhasor(&prices, allocator);
    defer allocator.free(result1);
    defer allocator.free(result2);
    {
        const expected = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -0.9024212540316113, -0.9111713414354039, -0.8802499339301291, -0.4960778452207575, 0.23014326182764316, 0.7640685272779155, 1.2051976875847823, 1.4124276273020036, 1.480539860969718, 1.5330935653579774, 1.55852273854552, 1.6247655051654633, 1.7036460167088041, 2.094098119232095, 2.644904666583977, 3.0896840035867155, 3.4687494553929463, 3.8178013810604963, 4.16338938698645, 4.517710463224215, 4.802326770579395, 5.03001981646354, 5.212174253170801, 5.357897802536707, 5.474476642029276, 5.567739713623535, 5.642350170898792, 5.702038536719044, 5.749789229375306, 5.787989783500208, 5.818550226800178, 5.631928274509247, 5.231299384009103, 3.408348179741738, 0.47463103906539017, -1.8927735052680879, -2.1991180583317744, -0.5502106646549256, -0.13848330139516707, -1.0242883165477394, -1.0595315422118696, 0.023940740147532596, 0.14701303615574066, 0.5013334899759525, 1.4223099248946263, 1.795787900374446, 1.4419082904871432, 0.3013132038672545, 0.15202808996388498, 0.7723534897849268, 1.3613343824720547, 1.2221869268469512, 0.2554423474034378, 0.142313857397412, 0.8195692281122378, 1.5640245994760262, 2.218333722674086, 2.500684199438992, 2.582701732190924, 2.64507068686511, 2.7332198657270186, 2.828359375876229, 2.8509790059819076, 2.790398643814507, 2.7303652648708865, 2.7338179992730107, 2.8140730539507297, 2.9681988696757102 };
        for (result1, 0..) |v, i| {
            try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
        }
    }
    {
        const expected = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -0.019215874858781092, 0.21526515411755665, 0.8173598134743345, 1.8739996453845966, 2.237272686834156, 1.9357657403984254, 1.43590432781059, 0.737356067860151, 0.396154965488413, 0.24176567936444127, 0.305998254710822, 0.5017104820991275, 1.0799523015478043, 1.9093333739681657, 2.190959179919986, 2.1462954099062257, 2.130978783208837, 2.109451105048814, 2.144652014389174, 2.018627671848984, 1.7167425044518398, 1.4333245910735462, 1.166642597179318, 0.9458209465452857, 0.7646611532696098, 0.616851736077154, 0.49675998947666156, 0.39950629597537207, 0.23527357761538528, 0.0005297541692854394, -1.318796410652403, -3.5998368723728733, -8.614498130049618, -14.999810337819635, -15.031792335762978, -8.459778109918657, 1.4428432526514114, 4.345819627075662, -0.37055744149532255, -1.1980818438162115, 2.609404589851861, 2.9518294254645614, 1.8006797797994998, 3.0500565820431476, 2.3071475638650067, 0.03384996843957971, -2.3315904207860485, -2.0458825833984573, 0.5794794455217158, 1.5340231818529844, 0.6334047500583837, -1.4727944504136345, -1.3896127591400955, 1.028331535122911, 2.3674119442891164, 2.589765322190243, 1.9893400150495408, 1.0376474637631037, 0.5580619656354756, 0.4054242230297649, 0.35896835435978436, 0.21593829485940866, -0.0351717948377084, -0.1674571003319354, -0.05483941614261505, 0.24951575611036117, 0.6575350111370634, 1.0769457349889688 };
        for (result2, 0..) |v, i| {
            try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
        }
    }
}
