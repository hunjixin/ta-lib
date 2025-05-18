pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "add works" {
    const std = @import("std");
    try std.testing.expect(add(2, 3) == 5);
}
