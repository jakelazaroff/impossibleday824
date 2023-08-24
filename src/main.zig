const std = @import("std");

pub fn main() !void {
    const socket = try std.os.socket(std.os.AF.INET, std.os.SOCK.STREAM, 0);

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

    std.os.closeSocket(socket);
}

fn listen(sock: std.os.socket_t) !void {
    std.debug.print("opening socket {}\n", .{sock});

    var data: [10]u8 = undefined;
    while (true) {
        const length = try std.os.recv(sock, &data, 0);
        if (length == 0) break;

        std.debug.print("received: {s}", .{data[0..length]});

        const response =
            \\HTTP/1.1 200 OK
            \\Accept-Ranges: bytes
            \\Content-Type: text/plain
            \\Content-Length: 13
            \\
            \\hello, world!
        ;

        _ = try std.os.send(sock, response, 0);
    }

    std.debug.print("closing socket {}\n", .{sock});
    std.os.closeSocket(sock);
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
