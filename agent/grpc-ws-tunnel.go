package main

import (
	"context"
	"flag"
	"io"
	"log"
	"net"
	"net/http"
	"sync"
	"time"

	"github.com/coder/websocket"
)

func main() {
	listen := flag.String("listen", ":8010", "listen address")
	target := flag.String("target", "127.0.0.1:8008", "tcp target address")
	path := flag.String("path", "/grpc-tunnel", "websocket tunnel path")
	pingInterval := flag.Duration("ping-interval", 25*time.Second, "websocket ping interval (0 to disable)")
	pingTimeout := flag.Duration("ping-timeout", 10*time.Second, "websocket ping timeout")
	flag.Parse()

	mux := http.NewServeMux()
	mux.HandleFunc(*path, func(w http.ResponseWriter, r *http.Request) {
		wsConn, err := websocket.Accept(w, r, &websocket.AcceptOptions{
			InsecureSkipVerify: true,
			CompressionMode:    websocket.CompressionDisabled,
		})
		if err != nil {
			log.Printf("accept websocket failed: %v", err)
			return
		}

		// Half-open tunnels (Cloudflare/Choreo idle drop, middlebox RST) leave
		// gRPC streams blocked on Recv forever. Periodic pings force a close so
		// the agent reconnect loop can run.
		pingCancel := startWebSocketPinger(wsConn, *pingInterval, *pingTimeout)
		defer pingCancel()

		upstream, err := net.DialTimeout("tcp", *target, 10*time.Second)
		if err != nil {
			log.Printf("dial upstream %s failed: %v", *target, err)
			_ = wsConn.Close(websocket.StatusInternalError, "upstream unavailable")
			return
		}

		tunnel := websocket.NetConn(context.Background(), wsConn, websocket.MessageBinary)

		// Close both ends when either direction finishes so the peer unblocks.
		var once sync.Once
		closeBoth := func() {
			once.Do(func() {
				_ = upstream.Close()
				_ = tunnel.Close()
				_ = wsConn.Close(websocket.StatusGoingAway, "tunnel closed")
			})
		}
		defer closeBoth()

		errCh := make(chan error, 2)
		go func() {
			_, copyErr := io.Copy(upstream, tunnel)
			errCh <- copyErr
			closeBoth()
		}()
		go func() {
			_, copyErr := io.Copy(tunnel, upstream)
			errCh <- copyErr
			closeBoth()
		}()

		<-errCh
	})

	server := &http.Server{
		Addr:              *listen,
		Handler:           mux,
		ReadHeaderTimeout: 10 * time.Second,
	}

	log.Printf("grpc websocket tunnel listening on %s, path %s, target %s, ping %s", *listen, *path, *target, *pingInterval)
	log.Fatal(server.ListenAndServe())
}

func startWebSocketPinger(wsConn *websocket.Conn, interval, timeout time.Duration) context.CancelFunc {
	if interval <= 0 {
		return func() {}
	}
	ctx, cancel := context.WithCancel(context.Background())
	go func() {
		ticker := time.NewTicker(interval)
		defer ticker.Stop()
		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				pingCtx, pingCancel := context.WithTimeout(ctx, timeout)
				err := wsConn.Ping(pingCtx)
				pingCancel()
				if err != nil {
					_ = wsConn.Close(websocket.StatusGoingAway, "ping failed")
					return
				}
			}
		}
	}()
	return cancel
}
