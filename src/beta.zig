const std = @import("std");
const math = std.math;

/// Computes the **Beta** indicator, which is a measure of the volatility (systematic risk) of a
/// security or portfolio compared to the market as a whole.
///
/// Beta is often used in **capital asset pricing models (CAPM)** to describe the relationship
/// between the return of an asset and the return of the benchmark (e.g., market index).
///
/// # Parameters:
/// - `inReal0`: A slice of f64 representing the returns of the asset (e.g., stock returns).
/// - `inReal1`: A slice of f64 representing the returns of the benchmark (e.g., S&P 500).
/// - `inTimePeriod`: The lookback period (window size) for calculating Beta.
/// - `allocator`: A memory allocator for returning the result buffer.
///
/// # Returns:
/// - A slice of f64 values, each representing the Beta of the asset over the given period.
///
/// # Formula:
/// For each window of length `N` (inTimePeriod):
///
/// Let:
/// - \( X = \text{inReal0}[i-N+1..i] \)
/// - \( Y = \text{inReal1}[i-N+1..i] \)
///
/// The **Beta** is calculated as:
///
/// \[
/// \text{Beta} = \frac{\text{Cov}(X, Y)}{\text{Var}(Y)}
/// \]
///
/// Where:
/// - Cov(X, Y) is the covariance between X and Y:
///   \[
///   \text{Cov}(X, Y) = \frac{1}{N} \sum_{j=0}^{N-1} (X_j - \bar{X})(Y_j - \bar{Y})
///   \]
/// - Var(Y) is the variance of Y:
///   \[
///   \text{Var}(Y) = \frac{1}{N} \sum_{j=0}^{N-1} (Y_j - \bar{Y})^2
///   \]
///
/// # Interpretation:
/// - **Beta > 1**: Asset is more volatile than the market.
/// - **Beta = 1**: Asset moves with the market.
/// - **Beta < 1**: Asset is less volatile than the market.
/// - **Beta < 0**: Asset moves inversely to the market.
///
/// # Errors:
/// - Returns an error if the input slices are too short or if `inTimePeriod` is invalid.
pub fn Beta(inReal0: []const f64, inReal1: []const f64, inTimePeriod: usize, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inReal0.len);
    errdefer allocator.free(outReal);
    @memset(outReal, 0.0);

    var x: f64 = 0.0;
    var y: f64 = 0.0;
    var sSS: f64 = 0.0;
    var sXY: f64 = 0.0;
    var sX: f64 = 0.0;
    var sY: f64 = 0.0;
    var tmpReal: f64 = 0.0;
    var n: f64 = 0.0;

    const startIdx = inTimePeriod;
    var trailingIdx: usize = 0;

    var trailingLastPriceX: f64 = inReal0[trailingIdx];
    var lastPriceX: f64 = trailingLastPriceX;
    var trailingLastPriceY: f64 = inReal1[trailingIdx];
    var lastPriceY: f64 = trailingLastPriceY;

    trailingIdx += 1;
    var i: usize = trailingIdx;

    // Initial calculation
    while (i < startIdx) {
        tmpReal = inReal0[i];
        x = 0.0;
        if (!(lastPriceX > -0.00000000000001 and lastPriceX < 0.00000000000001)) {
            x = (tmpReal - lastPriceX) / lastPriceX;
        }
        lastPriceX = tmpReal;

        tmpReal = inReal1[i];
        i += 1;

        y = 0.0;
        if (!(lastPriceY > -0.00000000000001 and lastPriceY < 0.00000000000001)) {
            y = (tmpReal - lastPriceY) / lastPriceY;
        }
        lastPriceY = tmpReal;

        sSS += x * x;
        sXY += x * y;
        sX += x;
        sY += y;
    }

    var outIdx: usize = inTimePeriod;
    n = @floatFromInt(inTimePeriod);

    // Main calculation loop
    while (i < inReal0.len) {
        tmpReal = inReal0[i];
        x = 0.0;
        if (!(lastPriceX > -0.00000000000001 and lastPriceX < 0.00000000000001)) {
            x = (tmpReal - lastPriceX) / lastPriceX;
        }
        lastPriceX = tmpReal;

        tmpReal = inReal1[i];
        i += 1;

        y = 0.0;
        if (!(lastPriceY > -0.00000000000001 and lastPriceY < 0.00000000000001)) {
            y = (tmpReal - lastPriceY) / lastPriceY;
        }
        lastPriceY = tmpReal;

        sSS += x * x;
        sXY += x * y;
        sX += x;
        sY += y;

        tmpReal = inReal0[trailingIdx];
        x = 0.0;
        if (!(trailingLastPriceX > -0.00000000000001 and trailingLastPriceX < 0.00000000000001)) {
            x = (tmpReal - trailingLastPriceX) / trailingLastPriceX;
        }
        trailingLastPriceX = tmpReal;

        tmpReal = inReal1[trailingIdx];
        trailingIdx += 1;

        y = 0.0;
        if (!(trailingLastPriceY > -0.00000000000001 and trailingLastPriceY < 0.00000000000001)) {
            y = (tmpReal - trailingLastPriceY) / trailingLastPriceY;
        }
        trailingLastPriceY = tmpReal;

        tmpReal = (n * sSS) - (sX * sX);
        if (!(tmpReal > -0.00000000000001 and tmpReal < 0.00000000000001)) {
            outReal[outIdx] = ((n * sXY) - (sX * sY)) / tmpReal;
        } else {
            outReal[outIdx] = 0.0;
        }
        outIdx += 1;

        sSS -= x * x;
        sXY -= x * y;
        sX -= x;
        sY -= y;
    }

    return outReal;
}

test "Beta work correctly" {
    var allocator = std.testing.allocator;
    const pricesX = [_]f64{
        100.00, 100.80, 101.60, 102.30, 103.10,
        103.90, 104.70, 105.40, 106.20, 107.00,
        107.80, 108.50, 109.30, 110.10, 110.90,
        111.60, 112.40, 113.20, 114.00, 114.70,

        114.20, 113.80, 113.50, 113.10, 112.80,
        112.40, 112.10, 111.70, 111.40, 111.00,
        111.50, 111.90, 112.20, 112.60, 112.90,
        113.30, 113.60, 114.00, 114.30, 114.70,
    };

    const pricesY = [_]f64{
        115.50, 116.30, 117.10, 117.90, 118.70,
        119.50, 120.30, 121.10, 121.90, 122.70,
        123.50, 124.30, 125.10, 125.90, 126.70,
        127.50, 128.30, 129.10, 129.90, 130.70,

        130.20, 129.40, 128.60, 129.20, 129.80,
        129.10, 128.40, 128.90, 129.40, 128.70,
        129.30, 129.90, 130.50, 130.00, 129.50,
        130.10, 130.70, 131.30, 130.80, 130.30,
    };
    const result = try Beta(&pricesX, &pricesY, 8, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 0.09259347454219599, 0.0439512091803773, -0.021563639594289093, 0.12652838963535093, 0.08914532015957691, 0.04096606902413322, -0.023402548624057343, 0.12312176283037145, 0.08589744756263075, 0.03820648682716569, -0.025021694208903347, 0.11987281886433863, 0.8862198895172355, 1.0286043451030666, 1.1085180920684479, 0.8568476089025835, 0.7532200426324772, 0.8340801597587748, 0.9132620452543062, -0.03253196147318418, -0.2809207874078762, -0.19258358376305545, 0.6262844944783474, 0.7799414330289097, 0.9212516617619846, 0.47892800785120887, 0.1562965846218287, 0.5177001412451042, 1.109836822860035, 1.3269268162678236, 2.3782539910704417, 0.0867291169276316 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}
