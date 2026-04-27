package main

import (
	"context"
	"flag"
	"io"
	"log"
	"net"
	"net/http"
	"time"

	"github.com/coder/websocket"
)

func main() {
	listen := flag.String("listen", ":8010", "listen address")
	target := flag.String("target", "127.0.0.1:8008", "tcp target address")
	path := flag.String("path", "/grpc-tunnel", "websocket tunnel path")
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
		defer wsConn.Close(websocket.StatusNormalClosure, "")

		upstream, err := net.DialTimeout("tcp", *target, 10*time.Second)
		if err != nil {
			log.Printf("dial upstream %s failed: %v", *target, err)
			wsConn.Close(websocket.StatusInternalError, "upstream unavailable")
			return
		}
		defer upstream.Close()

		tunnel := websocket.NetConn(context.Background(), wsConn, websocket.MessageBinary)
		defer tunnel.Close()

		errCh := make(chan error, 2)
		go func() {
			_, err := io.Copy(upstream, tunnel)
			errCh <- err
		}()
		go func() {
			_, err := io.Copy(tunnel, upstream)
			errCh <- err
		}()

		<-errCh
	})

	server := &http.Server{
		Addr:              *listen,
		Handler:           mux,
		ReadHeaderTimeout: 10 * time.Second,
	}

	log.Printf("grpc websocket tunnel listening on %s, path %s, target %s", *listen, *path, *target)
	log.Fatal(server.ListenAndServe())
}
