const std = @import("std");
const math = std.math;

/// Computes the Parabolic Sar (Stop and Reverse) with extended parameter control.
///
/// The Parabolic Sar is a trend-following indicator developed by Welles Wilder. It helps to identify potential trend reversals in the price of an asset.
/// This extended version allows fine-grained control of acceleration parameters for both long and short positions.
///
/// ---
/// **Concept:**
/// The Sar is calculated using the formula:
/// ```text
/// Sar(n) = Sar(n-1) + AF * (EP - Sar(n-1))
/// ```
/// - `Sar(n-1)`: Previous Sar value
/// - `AF`: Acceleration Factor (starts from init, incremented by factor, capped at max)
/// - `EP`: Extreme Point (highest high in long position, lowest low in short position)
///
/// Reversals occur when the price crosses the Sar, and the direction of the Sar switches.
///
/// ---
/// **Extended Parameters:**
/// - `inStartValue`: Initial Sar value.
/// - `inOffsetOnReverse`: Offset added when a reversal occurs.
/// - `inAccelerationInitLong`: Initial acceleration for long positions.
/// - `inAccelerationLongF`: Acceleration increment per period for long positions.
/// - `inAccelerationMaxLong`: Maximum acceleration for long positions.
/// - `inAccelerationInitShort`: Initial acceleration for short positions.
/// - `inAccelerationShortF`: Acceleration increment per period for short positions.
/// - `inAccelerationMaxShort`: Maximum acceleration for short positions.
///
/// ---
/// **Parameters:**
/// - `inHigh`: Array of high prices.
/// - `inLow`: Array of low prices.
/// - `allocator`: Memory allocator to allocate output buffer.
///
/// ---
/// **Returns:**
/// - Slice of `f64` containing the computed Sar values. The output has the same length as the input.
///
/// ---
/// **Errors:**
/// - If the input arrays are mismatched in length or too short.
/// - If allocation of output memory fails.
///
/// ---
/// **Example:**
/// ```text
/// let result = try SarExt(highs, lows, 0.02, 0.0, 0.02, 0.02, 0.2, 0.02, 0.02, 0.2, allocator);
/// ```
pub fn SarExt(inHigh: []const f64, inLow: []const f64, inStartValue: f64, inOffsetOnReverse: f64, inAccelerationInitLong: f64, inAccelerationLongF: f64, inAccelerationMaxLong: f64, inAccelerationInitShort: f64, inAccelerationShortF: f64, inAccelerationMaxShort: f64, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inHigh.len);
    errdefer allocator.free(outReal);

    // Initialize output array with NaN
    @memset(outReal, 0);

    // Need at least 2 elements to calculate
    if (inHigh.len < 2) return outReal;

    const startIdx: usize = 1;
    var afLong = inAccelerationInitLong;
    var afShort = inAccelerationInitShort;

    // Clamp acceleration factors to their max values
    if (afLong > inAccelerationMaxLong) {
        afLong = inAccelerationMaxLong;
    }

    var inAccelerationLong = inAccelerationLongF;
    if (inAccelerationLong > inAccelerationMaxLong) {
        inAccelerationLong = inAccelerationMaxLong;
    }
    if (afShort > inAccelerationMaxShort) {
        afShort = inAccelerationMaxShort;
    }
    var inAccelerationShort = inAccelerationShortF;
    if (inAccelerationShort > inAccelerationMaxShort) {
        inAccelerationShort = inAccelerationMaxShort;
    }

    // Determine initial position (long/short)
    var isLong: i32 = 0;
    if (inStartValue == 0.0) {
        // Calculate minus DM for first two periods
        const downMove = inLow[0] - inLow[1];
        const upMove = inHigh[1] - inHigh[0];
        isLong = if (downMove > 0 and downMove > upMove) 0 else 1;
    } else if (inStartValue > 0.0) {
        isLong = 1;
    }

    var outIdx = startIdx;
    var todayIdx = startIdx;

    var newHigh = inHigh[todayIdx - 1];
    var newLow = inLow[todayIdx - 1];

    var ep: f64 = 0.0; // Extreme point
    var sar: f64 = 0.0; // Stop and reverse value

    // Initialize Sar and extreme point
    if (inStartValue == 0.0) {
        if (isLong == 1) {
            ep = inHigh[todayIdx];
            sar = newLow;
        } else {
            ep = inLow[todayIdx];
            sar = newHigh;
        }
    } else if (inStartValue > 0.0) {
        ep = inHigh[todayIdx];
        sar = inStartValue;
    } else {
        ep = inLow[todayIdx];
        sar = @abs(inStartValue);
    }

    newLow = inLow[todayIdx];
    newHigh = inHigh[todayIdx];

    var prevLow: f64 = 0.0;
    var prevHigh: f64 = 0.0;

    // Main processing loop
    while (todayIdx < inHigh.len) {
        prevLow = newLow;
        prevHigh = newHigh;
        newLow = inLow[todayIdx];
        newHigh = inHigh[todayIdx];
        todayIdx += 1;

        if (isLong == 1) {
            // Long position handling
            if (newLow <= sar) {
                // Reverse to short position
                isLong = 0;
                sar = ep;
                if (sar < prevHigh) sar = prevHigh;
                if (sar < newHigh) sar = newHigh;

                // Apply offset on reverse
                if (inOffsetOnReverse != 0.0) {
                    sar += sar * inOffsetOnReverse;
                }

                outReal[outIdx] = -sar;
                outIdx += 1;

                // Reset acceleration for short position
                afShort = inAccelerationInitShort;
                ep = newLow;
                sar += afShort * (ep - sar);

                // Clamp Sar to recent highs
                if (sar < prevHigh) sar = prevHigh;
                if (sar < newHigh) sar = newHigh;
            } else {
                // Continue long position
                outReal[outIdx] = sar;
                outIdx += 1;

                // Update extreme point and acceleration
                if (newHigh > ep) {
                    ep = newHigh;
                    afLong += inAccelerationLong;
                    if (afLong > inAccelerationMaxLong) {
                        afLong = inAccelerationMaxLong;
                    }
                }

                // Update Sar
                sar += afLong * (ep - sar);

                // Clamp Sar to recent lows
                if (sar > prevLow) sar = prevLow;
                if (sar > newLow) sar = newLow;
            }
        } else {
            // Short position handling
            if (newHigh >= sar) {
                // Reverse to long position
                isLong = 1;
                sar = ep;
                if (sar > prevLow) sar = prevLow;
                if (sar > newLow) sar = newLow;

                // Apply offset on reverse
                if (inOffsetOnReverse != 0.0) {
                    sar -= sar * inOffsetOnReverse;
                }

                outReal[outIdx] = sar;
                outIdx += 1;

                // Reset acceleration for long position
                afLong = inAccelerationInitLong;
                ep = newHigh;
                sar += afLong * (ep - sar);

                // Clamp Sar to recent lows
                if (sar > prevLow) sar = prevLow;
                if (sar > newLow) sar = newLow;
            } else {
                // Continue short position
                outReal[outIdx] = -sar;
                outIdx += 1;

                // Update extreme point and acceleration
                if (newLow < ep) {
                    ep = newLow;
                    afShort += inAccelerationShort;
                    if (afShort > inAccelerationMaxShort) {
                        afShort = inAccelerationMaxShort;
                    }
                }

                // Update Sar
                sar += afShort * (ep - sar);

                // Clamp Sar to recent highs
                if (sar < prevHigh) sar = prevHigh;
                if (sar < newHigh) sar = newHigh;
            }
        }
    }

    return outReal;
}

test "SarExt calculation with valid input" {
    const allocator = std.testing.allocator;

    const highs = [_]f64{ 10, 12, 11, 13, 13, 14, 13, 15, 14, 100, 17, 16, 18, 17, 19 };
    const lows = [_]f64{ 8, 9, 9, 10, 12, 12, 12, 13, 13, 14, 100, 15, 16, 16, 17 };

    {
        const result = try SarExt(&highs, &lows, 0.0, 0.01, 0.02, 0.02, 0.2, 0.02, 0.02, 0.2, allocator);
        defer allocator.free(result);

        try std.testing.expectEqual(result.len, highs.len);
        const expect = [_]f64{ 0, 8, 8.08, 8.1584, 8.352064, 8.537981440000001, 8.8657025536, 9.173760400384, 9.63985956835328, 10.068670802885018, 13, 14, 15, 15, 16 };
        for (expect, 0..) |v, i| {
            try std.testing.expectApproxEqAbs(v, result[i], 1e-9);
        }
    }
    {
        const result = try SarExt(&highs, &lows, 1, 0.01, 0.02, 0.02, 0.2, 0.02, 0.02, 0.2, allocator);
        defer allocator.free(result);

        try std.testing.expectEqual(result.len, highs.len);
        const expect = [_]f64{ 0, 1, 1.22, 1.4356, 1.8981759999999999, 2.34224896, 3.0417140224, 3.6992111810559996, 4.603274286571519, 5.4350123436457976, 13, 14, 15, 15, 16 };
        for (expect, 0..) |v, i| {
            try std.testing.expectApproxEqAbs(v, result[i], 1e-9);
        }
    }
}
