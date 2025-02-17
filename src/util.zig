const std = @import("std");

// Read u32s delimited by spaces or tabs from a line of text.
pub fn readInts(comptime IntType: type, line: []const u8, nums: *std.ArrayList(IntType)) !void {
    var it = std.mem.splitAny(u8, line, ", \t");
    while (it.next()) |split| {
        if (split.len == 0) {
            continue;
        }
        const num = try std.fmt.parseInt(IntType, split, 10);
        try nums.append(num);
    }
}

fn isDigit(c: u8) bool {
    return c == '-' or (c >= '0' and c <= '9');
}

pub fn extractIntsIntoBuf(comptime IntType: type, str: []const u8, buf: []IntType) ![]IntType {
    var i: usize = 0;
    var n: usize = 0;

    while (i < str.len) {
        const c = str[i];
        if (isDigit(c)) {
            const start = i;
            i += 1;
            while (i < str.len) {
                const c2 = str[i];
                if (!isDigit(c2)) {
                    break;
                }
                i += 1;
            }
            buf[n] = try std.fmt.parseInt(IntType, str[start..i], 10);
            n += 1;
        } else {
            i += 1;
        }
    }
    return buf[0..n];
}

pub fn splitOne(line: []const u8, delim: []const u8) ?struct { head: []const u8, rest: []const u8 } {
    const maybeIdx = std.mem.indexOf(u8, line, delim);
    // XXX is there a more idiomatic way to write this pattern?
    if (maybeIdx) |idx| {
        return .{ .head = line[0..idx], .rest = line[(idx + delim.len)..] };
    } else {
        return null;
    }
}

pub fn splitIntoArrayList(input: []const u8, delim: []const u8, array_list: *std.ArrayList([]const u8)) !void {
    array_list.clearAndFree();
    var it = std.mem.splitSequence(u8, input, delim);
    while (it.next()) |part| {
        try array_list.append(part);
    }
    // std.fmt.bufPrint(buf: []u8, comptime fmt: []const u8, args: anytype)
    // std.fmt.bufPrintIntToSlice(buf: []u8, value: anytype, base: u8, case: Case, options: FormatOptions)
}

// Split the string into a pre-allocated buffer of slices.
// The buffer must be large enough to accommodate the number of parts.
// The returned slices point into the input string.
pub fn splitIntoBuf(str: []const u8, delim: []const u8, buf: [][]const u8) [][]const u8 {
    var rest = str;
    var i: usize = 0;
    while (splitOne(rest, delim)) |split| {
        buf[i] = split.head;
        rest = split.rest;
        i += 1;
    }
    buf[i] = rest;
    i += 1;
    return buf[0..i];
}

// Split the string on any character in delims, filtering out empty values.
pub fn splitAnyIntoBuf(str: []const u8, delims: []const u8, buf: [][]const u8) [][]const u8 {
    var it = std.mem.splitAny(u8, str, delims);
    var i: usize = 0;
    while (it.next()) |part| {
        if (part.len > 0) {
            buf[i] = part;
            i += 1;
        }
    }
    return buf[0..i];
}

pub fn readInputFile(allocator: std.mem.Allocator, filename: []const u8) ![]const u8 {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    const stat = try file.stat();
    const fileSize = stat.size;
    return try file.reader().readAllAlloc(allocator, fileSize);
}

fn printHashMap(comptime V: type, hash_map: std.StringHashMap(V)) void {
    var is_first = true;
    var it = hash_map.iterator();
    std.debug.print("{{ ", .{});
    while (it.next()) |entry| {
        if (!is_first) {
            std.debug.print(", ", .{});
        } else {
            is_first = false;
        }
        std.debug.print("{s}: {any}", .{ entry.key_ptr.*, entry.value_ptr.* });
    }
    std.debug.print(" }}\n", .{});
}

pub fn hashMinMaxValue(comptime V: type, hash_map: anytype) ?struct { min: V, max: V } {
    var min: V = undefined;
    var max: V = undefined;
    var it = hash_map.valueIterator();
    if (it.next()) |val| {
        min = val.*;
        max = val.*;
    } else {
        return null;
    }
    while (it.next()) |val| {
        min = @min(min, val.*);
        max = @max(max, val.*);
    }
    return .{ .min = min, .max = max };
}

pub fn hashMaxValue(comptime V: type, hash_map: anytype) ?V {
    const minMax = hashMinMaxValue(V, hash_map);
    if (minMax) |v| {
        return v.max;
    }
    return null;
}

const assert = std.debug.assert;

pub fn lcm(comptime V: type, nums: []const V) V {
    assert(nums.len >= 1);
    var gcd = nums[0];
    var prod = nums[0];
    for (nums[1..]) |num| {
        gcd = std.math.gcd(gcd, num);
        prod *= num;
    }
    return prod / gcd;
}

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualDeep = std.testing.expectEqualDeep;

test "splitIntoBuf" {
    var buf: [8][]const u8 = undefined;
    const parts = splitIntoBuf("abc,def,,gh12", ",", &buf);
    try expectEqual(@as(usize, 4), parts.len);
    try expectEqualDeep(@as([]const u8, "abc"), parts[0]);
    try expectEqualDeep(@as([]const u8, "def"), parts[1]);
    try expectEqualDeep(@as([]const u8, ""), parts[2]);
    try expectEqualDeep(@as([]const u8, "gh12"), parts[3]);
    // const expected = [_][]const u8{ "abc", "def", "", "gh12" };
    // expectEqualDeep(@as([][]const u8, &[_][]const u8{ "abc", "def", "", "gh12" }), parts);
}

const eql = std.mem.eql;

test "extractIntsIntoBuf" {
    var buf: [8]i32 = undefined;
    var ints = try extractIntsIntoBuf(i32, "12, 38, -233", &buf);
    try expect(eql(i32, &[_]i32{ 12, 38, -233 }, ints));

    ints = try extractIntsIntoBuf(i32, "zzz343344ddkd", &buf);
    try expect(eql(i32, &[_]i32{343344}, ints));

    ints = try extractIntsIntoBuf(i32, "not a number", &buf);
    try expect(eql(i32, &[_]i32{}, ints));
}

test "splitAnyIntoBuf" {
    var buf: [5][]const u8 = undefined;
    var parts = splitAnyIntoBuf("Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53", ":|", &buf);
    try expectEqual(@as(usize, 3), parts.len);
    try expectEqualDeep(@as([]const u8, "Card 1"), parts[0]);
    try expectEqualDeep(@as([]const u8, " 41 48 83 86 17 "), parts[1]);
    try expectEqualDeep(@as([]const u8, " 83 86  6 31 17  9 48 53"), parts[2]);
}

test "lcm" {
    try expectEqual(lcm(u64, &[_]u64{ 3739, 3797, 3919, 4003 }), 222718819437131);
}
