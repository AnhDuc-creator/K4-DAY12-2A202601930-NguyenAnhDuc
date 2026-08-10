# Thông Tin Deploy — Checkpoint 5

## Thông Tin Học Viên

| Mục         | Nội dung                                                            |
| ----------- | ------------------------------------------------------------------- |
| Họ và tên   | Nguyễn Anh Đức                                                      |
| Mã học viên | 2A202601930                                                         |
| Repo        | https://github.com/AnhDuc-creator/K4-DAY12-2A202601930-NguyenAnhDuc |

## Service

| Mục         | Nội dung                                          |
| ----------- | ------------------------------------------------- |
| Public URL  | https://day12-chat-production-cb83.up.railway.app |
| Platform    | Railway                                           |
| Ngày deploy | 10/08/2026                                        |

## Biến Môi Trường Đã Set Trên Cloud

Ghi tên biến và nguồn giá trị, không ghi giá trị:

| Biến                | Đã set | Ghi chú                                                      |
| ------------------- | ------ | ------------------------------------------------------------ |
| `PORT`              | ✅     | Railway tự gán (8080), app đọc qua `${PORT:-8000}` trong CMD |
| `API_TOKEN`         | ✅     | đặt trong dashboard Railway, không nằm trong repo            |
| `REDIS_URL`         | ✅     | tham chiếu Redis add-on của Railway theo tên service         |
| `BUCKET_CAPACITY`   | ✅     | 10                                                           |
| `REFILL_PER_MINUTE` | ✅     | 10                                                           |
| `DAILY_BUDGET_USD`  | ✅     | 1.0                                                          |
| `LOG_LEVEL`         | ✅     | INFO                                                         |

## Lệnh Kiểm Tra

    [Console]::OutputEncoding = [Text.Encoding]::UTF8
    $url = "https://day12-chat-production-cb83.up.railway.app"
    $tok = "<token dat tren Railway>"

    # 1. Liveness — mong đợi 200 {"status":"ok"}
    curl.exe -i $url/healthz

    # 2. Readiness — mong đợi 200 {"status":"ready"} (đã nối được Redis)
    curl.exe -i $url/readyz

    # 3. Không có token — mong đợi 401 kèm header WWW-Authenticate
    curl.exe -i -X POST $url/chat -H "Content-Type: application/json" --data-raw "{\""message\"":\""Hello\""}"

    # 4. Có token — mong đợi 200 kèm câu trả lời
    Invoke-RestMethod -Uri "$url/chat" -Method Post -ContentType "application/json" -Headers @{Authorization="Bearer $tok"; "X-Client-Id"="sv-test"} -Body '{"message":"Deploy la gi"}'

## Kết Quả Chạy Thật

Chạy lúc 08:46–08:47 GMT ngày 10/08/2026.

    PS> curl.exe -i $url/healthz
    HTTP/1.1 200 OK
    Content-Type: application/json
    Date: Mon, 10 Aug 2026 08:46:52 GMT
    Server: railway-hikari
    x-railway-request-id: 86jbvg3jSYiXNwImxtoGcA
    Content-Length: 64
    x-hikari-trace: sin1.nzn2
    x-railway-edge: sin1
    Connection: keep-alive

    {"status":"ok","service":"day12-chat-service","version":"1.0.0"}

    PS> curl.exe -i $url/readyz
    HTTP/1.1 200 OK
    Content-Type: application/json
    Date: Mon, 10 Aug 2026 08:47:00 GMT
    Server: railway-hikari
    x-railway-request-id: 11Y6AtZ1QtCxhgArnpoFkQ
    Content-Length: 31
    x-hikari-trace: sin1.hs0s
    x-railway-edge: sin1
    Connection: keep-alive

    {"status":"ready","redis":true}

    PS> curl.exe -i -X POST $url/chat -H "Content-Type: application/json" --data-raw "{\""message\"":\""Hello\""}"
    HTTP/1.1 401 Unauthorized
    Content-Type: application/json
    Date: Mon, 10 Aug 2026 08:47:04 GMT
    Server: railway-hikari
    www-authenticate: Bearer
    x-railway-request-id: u3sIEjjwT4ywfqnX2h0iww
    Content-Length: 44
    x-hikari-trace: sin1.tr00
    x-railway-edge: sin1
    Connection: keep-alive

    {"detail":"invalid or missing bearer token"}

    PS> Invoke-RestMethod -Uri "$url/chat" -Method Post -ContentType "application/json" -Headers @{Authorization="Bearer $tok"; "X-Client-Id"="sv-test"} -Body '{"message":"Deploy la gi"}'

    reply        : Về Deploy la gi, cách làm phổ biến trong production là đặt một lớp gateway
                   phía trước để lo authentication, rate limiting và bảo vệ chi phí.
                   (Mình đang nhớ 2 lượt trao đổi trước đó.)
    client_id    : sv-test
    turns_before : 2
    usd_cost     : 3.315E-05
    usage        : @{prompt=41; completion=45}

Ghi chú: console PowerShell hiển thị tiếng Việt bị lỗi font do code page mặc định
không phải UTF-8; dữ liệu server trả về vẫn đúng UTF-8. Đặt
`[Console]::OutputEncoding = [Text.Encoding]::UTF8` trước khi chạy thì hiển thị đúng.

`turns_before: 2` cho thấy lịch sử hội thoại của `sv-test` đã được lưu trong Redis
add-on từ lần gọi trước — state nằm ngoài process, đúng yêu cầu stateless.

## Ảnh Chụp Màn Hình

- `screenshots/railway-dashboard.png` — dashboard Railway, `day12-chat` và `day12-chat-redis` cùng Online
- `screenshots/healthz.png` — gọi `/healthz` 200, `/readyz` 200, `/chat` không token 401
- `screenshots/chat-authenticated.png` — gọi `/chat` với Bearer token hợp lệ, trả 200 kèm đủ 5 trường
- `screenshots/stateless-scale.png` — chạy local `docker compose --scale chat=3`, `turns_before` tăng đều qua các container

## Sự Cố Khi Deploy

**Lỗi 1 — Healthcheck failed, `$PORT` không phải số nguyên.**

Build Docker thành công và image đã push (61.4 MB), nhưng Railway báo
`1/1 replicas never became healthy!`. Deploy Logs cho thấy
`Error: Invalid value for '--port': '$PORT' is not a valid integer`, lặp lại 4 lần
theo số lần restart. Nguyên nhân: `railway.toml` có `startCommand` ghi đè `CMD` của
Dockerfile, và Railway không chạy lệnh đó qua shell nên `$PORT` không được expand —
uvicorn nhận nguyên chuỗi 5 ký tự làm tham số. Sửa bằng cách xóa `startCommand`,
để Docker `CMD` (dạng `sh -c` với `${PORT:-8000}`) lo việc expand. Sau khi sửa,
log xác nhận `Uvicorn running on http://0.0.0.0:8080` — Railway gán PORT=8080.

**Lỗi 2 — `/readyz` trả 500 thay vì 503.**

`/healthz` trả 200 nhưng `/readyz` trả 500 Internal Server Error. Traceback trong
Deploy Logs chỉ tới `get_settings()` với
`ValidationError: 1 validation error for Settings — api_token Field required`:
biến `API_TOKEN` chưa được set trên Railway. Đây là fail-fast của CP1 hoạt động
đúng như thiết kế, và nó cũng chứng minh vì sao phải tách hai probe: `/healthz`
không nhận dependency nào nên không chạm tới Settings và vẫn trả 200, còn `/readyz`
gọi `get_store()` → `get_redis_client()` → `get_settings()` nên nổ ngay ở tầng
dependency, trước khi vào thân hàm — vì thế mới ra 500 chứ không phải 503.

Ngoài ra `REDIS_URL` ban đầu bị đặt là `${{REDIS_URL}}`, tức tự tham chiếu chính
biến của service `day12-chat`, kết quả là chuỗi rỗng. Cú pháp đúng phải có tên
service phía trước: `${{<ten-service-redis>.REDIS_URL}}`. Sau khi sửa cả hai,
`/readyz` trả `{"status":"ready","redis":true}`.

**Lỗi 3 — Docker Hub rate limit khi build ở máy.**

Lần build local đầu tiên fail với
`429 Too Many Requests` khi pull `python:3.11-slim`. Nguyên nhân: hạn mức pull ẩn
danh của Docker Hub tính theo IP, mà mạng dùng chung IP cho nhiều máy. Sửa bằng
`docker login` để dùng hạn mức riêng của tài khoản.
