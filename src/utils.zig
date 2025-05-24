pub fn IsZero(value: f64) bool {
    return (-0.00000000000001 < value) and (value < 0.00000000000001);
}

test "IsZero returns true for zero" {
    const std = @import("std");
    try std.testing.expect(IsZero(0.0));
    try std.testing.expect(IsZero(-0.0));
}
