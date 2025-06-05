const std = @import("std");
const math = std.math;

/// Computes the arccosine (inverse cosine) of each element in the input array.
///
/// The arccosine function is defined as:
///   acos(x), where x ∈ [-1, 1]
///
/// Parameters:
/// - `inReal`: Input slice of f64 values (each value must be in [-1.0, 1.0])
/// - `allocator`: Memory allocator for creating the output array
///
/// Returns:
/// - A slice of f64 values, each being the result of acos(input[i])
/// - Returns `error.InputOutOfDomain` if any input is outside [-1, 1]
pub fn Acos(inReal: []const f64, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outReal);

    for (outReal, inReal) |*out, v| {
        out.* = math.acos(v);
    }

    return outReal;
}

test "Acos work correctly" {
    var allocator = std.testing.allocator;
    const pricesX = [_]f64{
        -0.1, -0.8, 0, 0.8, 0.10,
    };

    const result = try Acos(&pricesX, allocator);
    defer allocator.free(result);

    const expected = [_]f64{
        1.6709637479564563, 2.498091544796509, 1.5707963267948966, 0.6435011087932843, 1.4706289056333368,
    };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}
