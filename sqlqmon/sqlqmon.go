package main

import (
	"embed"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"
)

//go:embed public
var static_files1 embed.FS

var staticDir1 = "public"

func rootPath1(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Cache-Control", "no-cache")

		if r.URL.Path == "/" {
			r.URL.Path = fmt.Sprintf("/%s/", staticDir1)
		} else {
			b := strings.Split(r.URL.Path, "/")[0]
			if b != staticDir1 {
				r.URL.Path = fmt.Sprintf("/%s%s", staticDir1, r.URL.Path)
			}
		}
		h.ServeHTTP(w, r)
	})
}

var epoch = time.Unix(0, 0).Format(time.RFC1123)

var noCacheHeaders = map[string]string{
	"Expires":         epoch,
	"Cache-Control":   "no-cache, private, max-age=0",
	"Pragma":          "no-cache",
	"X-Accel-Expires": "0",
}

var etagHeaders = []string{
	"ETag",
	"If-Modified-Since",
	"If-Match",
	"If-None-Match",
	"If-Range",
	"If-Unmodified-Since",
}

func NoCache(h http.Handler) http.Handler {
	fn := func(w http.ResponseWriter, r *http.Request) {

		// Delete any ETag headers that may have been set
		for _, v := range etagHeaders {
			if r.Header.Get(v) != "" {
				r.Header.Del(v)
			}
		}

		// Set our NoCache headers
		for k, v := range noCacheHeaders {
			w.Header().Set(k, v)
		}

		h.ServeHTTP(w, r)
	}

	return http.HandlerFunc(fn)
}

func main() {

	var staticFS1 = http.FS(static_files1)
	fs1 := rootPath1(http.FileServer(staticFS1))
	http.Handle("/", fs1)

	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}

	log.Printf("Listening on :%s...\n", port)
	err := http.ListenAndServe(fmt.Sprintf(":%s", port), nil)
	if err != nil {
		log.Fatal(err)
	}
}
