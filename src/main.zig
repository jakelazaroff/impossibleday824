const std = @import("std");

const allocator = std.heap.page_allocator;

pub fn main() !void {
    const socket = try std.os.socket(std.os.AF.INET, std.os.SOCK.STREAM, 0);
    defer std.os.closeSocket(socket);

    // const address = std.os.sockaddr.in{ .port = 8080, .addr = 2130706433 };
    // 31, 144 = 8080
    // 127, 0, 0, 1 = 127.0.0.1
    // zeros = padding
    const address = std.os.sockaddr{ .family = std.os.AF.INET, .data = [_]u8{ 31, 144, 127, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0 }, .len = 0 };
    try std.os.bind(socket, &address, @sizeOf(std.os.sockaddr));
    try std.os.listen(socket, 1);

    var clientAddress: ?*std.os.sockaddr = null;
    var clientLen: ?*std.os.socklen_t = null;

    while (true) {
        const client = try std.os.accept(socket, clientAddress, clientLen, 0);
        _ = try std.Thread.spawn(.{}, listen, .{client});
    }
}

fn listen(sock: std.os.socket_t) !void {
    defer std.os.closeSocket(sock);

    std.debug.print("opening socket {}\n", .{sock});

    var req: [1000]u8 = undefined;
    while (true) {
        const length = try std.os.recv(sock, &req, 0);
        if (length == 0) break;

        std.debug.print("received: {s}\n", .{req[0..length]});

        var it = std.mem.tokenize(u8, req[0..length], " ");
        const verb = it.next() orelse "";
        if (std.mem.eql(u8, verb, "GET")) {
            const path = it.next() orelse "/";
            std.debug.print("path: {s}\n", .{path});

            if (std.fs.cwd().openFile(path[1..], .{})) |file| {
                defer file.close();

                var data: [1000]u8 = undefined;
                const dataLen = try std.fs.File.preadAll(file, &data, 0);

                const res = try response(data[0..dataLen]);
                std.debug.print("{s}\n", .{res});

                _ = try std.os.send(sock, res, 0);
            } else |_| {
                _ = try std.os.send(sock, notfound, 0);
            }
        }
    }

    std.debug.print("closing socket {}\n", .{sock});
}

const notfound =
    \\HTTP/1.1 404 Not Found
    \\Accept-Ranges: bytes
    \\Content-Type: text/plain
    \\Content-Length: 13
    \\
    \\404 Not found
;

fn response(data: []u8) ![]u8 {
    const base =
        \\HTTP/1.1 200 OK
        \\Accept-Ranges: bytes
        \\Content-Type: text/plain
        \\Content-Length: {d}
        \\
        \\{s}
    ;

    return try std.fmt.allocPrint(allocator, base, .{ data.len, data });
}

// SOCKET FUNCTIONS
// accept
// bind -- if a program binds a socket to a source address
//          the socket can be used to receive data sent to that address
// closeSocket
// connect
// getpeername
// getsockname
// listen
// recv
// recvfrom
// send
// sendmsg
// sendto
// sendsockopt
// shutdown

// A server may create several concurrently established TCP sockets with the same local port/ip
// each mapped to its own server-child process, serving its own client process.
// They are treated as different sockets since remote address is different
// = different socket-pair
