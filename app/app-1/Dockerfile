FROM golang:1.25 AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN go build -o app .


FROM debian:bookworm-slim
WORKDIR /app

COPY --from=builder /app/app .
COPY --from=builder /app/index.html .

EXPOSE 8080

CMD ["./app"]