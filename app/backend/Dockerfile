# Use the official Golang image to create a build artifact
FROM golang:1.22.4 as builder

WORKDIR /app

COPY . .

# Set the architecture to amd64 or arm64
ENV CGO_ENABLED=0 GOOS=linux GOARCH=amd64

RUN go mod tidy
RUN go build -o main .

# Use a minimal Docker image to run the Go application
FROM alpine:latest

WORKDIR /root

COPY --from=builder /app/main .

EXPOSE 8081

CMD ["/root/main"]
