# ----------- Build stage -----------
    FROM golang:1.22.4 AS builder

    WORKDIR /app
    
    COPY . .
    
    # Set the architecture to amd64 or arm64
    ENV CGO_ENABLED=0 GOOS=linux GOARCH=amd64
    
    RUN go mod tidy
    RUN go build -o main .
    
    # ----------- Runtime stage -----------
    FROM alpine:latest
    
    # Install CA certificates and basic tools
    RUN apk --no-cache add ca-certificates
    
    WORKDIR /root
    
    # Copy built Go binary
    COPY --from=builder /app/main .
    
    # Copy the DigiCert root certificate
    COPY --from=builder /app/DigiCertGlobalRootCA.crt.pem .
    
    EXPOSE 8081
    
    CMD ["/root/main"]
    