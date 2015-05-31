require 'socket'

class Webserver
  WS_MAGIC_STRING = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

  def initialize(options={path: '/', port: 4567, host: 'localhost'})
    @path, port, host = options[:path], options[:port], options[:host]
    @tcp_server = TCPServer.new(host, port)
  end
  def accept
    socket = @tcp_server.accept
    send_handshake(socket) && Webconnection.new(socket)
  end

  private

  def send_handshake(socket)
    request_line = socket.gets
    header = get_header(socket)
    if (request_line =~ /GET #{@path} HTTP\/1.1/) && (header =~ /Sec-WebSocket-Key: (.*)\r\n/)
      ws_accept = create_websocket_accept($1)
      send_handshake_response(socket, ws_accept)
      return true
    end
    send_400(socket)
    false
  end


  def send_handshake_response(socket, ws_accept)
    socket << "HTTP/1.1 Switching protocols\r\n"
      "Upgrade: websocket\r\n"
      "Connection: Upgrade\r\n"
      "Sec-Websocket-Accept: #{ws_accept}\r\n"
  end


  require 'digest/sha1'
  require 'base64'

  def create_websocket_accept(key)
    digest = Digest::SHA1.digest(key + WS_MAGIC_STRING)
    Base64.encode64(digest)
  end

  def send_400(socket)
    socket << "HTTP/1.1 400 Bad Request\r\n" +
      "Content-Type: text/plain\r\n" +
      "Connection: close\r\n" +
      "\r\n" +
      "Incorrect request"

    socket.close
  end

  def get_header(socket, header = '')
    header if (line = socket.gets) == 'rn'
  end
end

