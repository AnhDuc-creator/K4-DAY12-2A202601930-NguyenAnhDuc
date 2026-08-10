# Phiếu Phản Ánh — K4 Ngày 12

> **Bài làm cá nhân.** Trả lời bằng lời của chính bạn, dựa trên những gì bạn
> quan sát được khi chạy code — không sao chép đáp án của người khác.
>
> Cách trả lời: thay dòng bằng câu trả lời.
> `grade.py` đếm số câu đã trả lời (15 điểm cho 10 câu).
>
> Họ và tên: Nguyễn Anh Đức  
> Mã học viên: 2A202601930

---

### Câu 1 — Fail fast (CP1)

Trong `Settings`, `api_token` không có giá trị mặc định nên app chết ngay khi
khởi động nếu thiếu biến môi trường. Hãy mô tả một tình huống cụ thể mà việc
"chết sớm" này cứu bạn, so với việc để mặc định `"changeme"`.

> Ứng dụng thiếu biến API_TOKEN sẽ sập ngay lúc khởi động và endpoint /readyz báo lỗi 500 ValidationError. Nếu để giá trị mặc định là "changeme", app vẫn khởi động, các probe báo 200 và nền tảng Railway hiện Online. Lúc này endpoint /chat mở toang cho bất kỳ ai đoán được token, gây rò rỉ bảo mật âm thầm và bạn chỉ nhận ra khi hóa đơn cloud tăng vọt

---

### Câu 2 — Log cho máy đọc (CP1)

Chạy service và gọi `/chat` vài lần. Dán một dòng log JSON bạn thu được, rồi
nêu **hai** việc bạn làm được với dòng log đó mà `print("đã trả lời xong")`
không làm được.

> Dòng log thu được là {"event": "chat_completed", "severity": "INFO", "ts": "2026-08-10T09:58:12.096850+00:00", "client_id": "sv-log", "prompt_tokens": 3, "completion_tokens": 37, "usd_cost": 2.265e-05}. Dòng log định dạng JSON chứa sẵn các trường phân bạch rõ ràng như mã khách hàng và chi phí. Cấu trúc này mang lại hai lợi ích kỹ thuật vượt trội so với lệnh in chuỗi tự do. Thứ nhất, hệ thống dễ dàng lọc tự động theo trường dữ liệu, ví dụ tìm mọi truy vấn của một người dùng cụ thể hoặc lọc cảnh báo khi chi phí vượt ngưỡng. Thứ hai, các nền tảng giám sát có thể đọc trực tiếp định dạng này để vẽ biểu đồ thống kê ngay lập tức mà không cần phân tích cú pháp phức tạp. Nhờ cấu trúc log rõ ràng, ta cũng dễ dàng nhìn thấy lượng mã thông báo đầu vào tăng vọt từ 3 lên 43 rồi 93 qua các lượt chat do ứng dụng phải tự động nạp thêm lịch sử hội thoại.

---

### Câu 3 — Kích thước image (CP2)

Build cả hai phiên bản và ghi lại số đo thật:

```bash
docker build -f <Dockerfile-1-stage> -t chat:single .
docker build -t chat:multi .
docker images | grep chat
```

| Bản               | Dung lượng                        |
| ----------------- | --------------------------------- |
| 1 stage (bản đầu) | 1.73 GB trên đĩa (446 MB khi nén) |
| Multi-stage       | 270 MB trên đĩa (63.7 MB khi nén) |

Giải thích: phần dung lượng chênh lệch đó là những gì?

> Log build cho thấy python:3.11 đầy đủ phải tải 6 layer, riêng một layer đã 236MB, tổng hơn 400MB nén. Bản slim chỉ khoảng 30MB. Đây là phần chênh lớn nhất. Bản 1-stage chạy pip install thẳng vào image cuối nên giữ luôn pip cache và các gói build-time. Bản multi-stage cài ở builder rồi chỉ COPY --from=builder /install /usr/local sang stage runtime, nên toàn bộ stage builder bị vứt đi. COPY . . kéo cả .git, tests/, .venv nếu có. Bản multi-stage chỉ copy app/ và utils/, cộng .dockerignore chặn sẵn.

---

### Câu 4 — Thứ tự lệnh trong Dockerfile (CP2)

Sửa một ký tự trong `app/main.py` rồi build lại. Với Dockerfile của bạn, những
layer nào được dùng lại từ cache, layer nào phải chạy lại? Nếu bạn đặt
`COPY . .` lên trước `RUN pip install` thì kết quả khác thế nào?

> Khi sửa file main.py, các layer WORKDIR, COPY requirements.txt và RUN pip install báo trạng thái CACHED. Chỉ có layer COPY mã nguồn và RUN useradd phải thực thi lại. Nếu đặt lệnh COPY toàn bộ thư mục lên trước RUN pip install, một thay đổi nhỏ ở mã nguồn sẽ làm đổi hash của layer COPY. Điều này phá vỡ cache của toàn bộ các bước phía sau, buộc Docker tải và cài lại toàn bộ thư viện khiến thời gian build tăng từ vài giây lên vài phút.

---

### Câu 5 — Vì sao không chạy bằng root (CP2)

Container mặc định chạy bằng root. Mô tả chuỗi sự kiện dẫn từ "một lỗ hổng
trong code Python của bạn" tới "kẻ tấn công có quyền cao trên máy host", và
lệnh `USER` cắt đứt chuỗi đó ở chỗ nào.

> Chuỗi tấn công bắt đầu khi lỗ hổng mã nguồn cho phép kẻ gian thực thi lệnh tùy ý. Nếu tiến trình chạy bằng quyền quản trị cao nhất, chúng có thể đọc ghi file hệ thống, cài cắm công cụ và lợi dụng các cấu hình lỏng lẻo để lợi dụng các cấu hình lỏng lẻo như docker socket bị mount vào container hoặc container được cấp dư capability. Lệnh USER appuser cắt đứt chuỗi rủi ro này ngay từ bước xâm nhập đầu tiên vì tiến trình đã bị hạ xuống quyền người dùng thường. Dù lỗ hổng phần mềm vẫn bị khai thác, kẻ tấn công không thể can thiệp tệp tin hệ thống hay dùng các đặc quyền cấp cao để vượt rào, qua đó giới hạn thiệt hại chỉ nằm gọn trong phạm vi ứng dụng.

---

### Câu 6 — Bearer token (CP3)

Vì sao 401 phải kèm header `WWW-Authenticate: Bearer`? Và vì sao ta trả **cùng
một** thông báo lỗi cho cả ba trường hợp (thiếu header, sai scheme, sai token)
thay vì nói rõ sai ở đâu cho người dùng dễ sửa?

> Tiêu đề WWW-Authenticate là bắt buộc theo chuẩn HTTP cho lỗi 401 để báo cho máy khách biết chuẩn xác thực cần dùng. Việc phản hồi chung một thông báo lỗi giúp giấu kín thông tin, ngăn kẻ gian đoán được chúng đã gửi đúng định dạng hay chưa.

---

### Câu 7 — Token bucket (CP3)

Với `capacity=10`, `refill_per_minute=10`: một client im lặng 10 phút rồi gửi
liên tiếp. Nó gửi được bao nhiêu request trước khi bị 429? Nếu bỏ đoạn
`min(capacity, ...)` trong `available()` thì con số đó thành bao nhiêu, và tại sao?

> Hàm available dùng toán tử min để giới hạn xô chứa tối đa 10 token. Do đó client im lặng 10 phút vẫn chỉ tích lũy và gửi được 10 request rồi bị chặn bằng mã 429. Nếu gỡ bỏ toán tử min, số token sẽ cộng dồn theo thời gian thành 100 token. Lúc này client có thể xả đồng loạt 100 request liên tiếp, tạo ra mức tải bùng nổ vượt gấp 10 lần thiết kế ban đầu của hệ thống.

---

### Câu 8 — Ngân sách theo ngày (CP3)

So sánh hạn mức $30/tháng với hạn mức $1/ngày cho cùng một client. Giả sử có sự
cố khiến một client gọi liên tục từ 2h sáng. Với mỗi cách, thiệt hại tối đa là
bao nhiêu và service tự hồi phục khi nào?

> Với ngân sách 30 USD một tháng, thiệt hại tối đa là 30 USD và client có thể bị ngưng phục vụ đến tận tháng sau nếu sự cố vô tình đốt sạch tiền ngay những ngày đầu tháng. Ngược lại, hạn mức 1 USD một ngày giới hạn thiệt hại tối đa ở mức 1 USD và hệ thống sẽ tự động khôi phục vào 0 giờ UTC hôm sau. Cơ chế tự phục hồi này hoạt động nhờ hàm định danh khóa trong tệp cost_guard.py luôn ghép mã client với chuỗi ngày tháng năm hiện tại. Khi bước sang ngày mới, chuỗi khóa thay đổi khiến hàm kiểm tra đọc ra giá trị chi phí bằng 0 và tự động mở lại kết nối mà không cần can thiệp thủ công. Thực tế cả hai phương án đều có thể lọt lưới vượt ngân sách đúng bằng chi phí của request cuối cùng do cơ chế hạn ngạch mềm luôn kiểm tra trước rồi mới ghi nhận chi phí thực tế. Nhìn chung, việc chia nhỏ hạn mức theo ngày giúp thu hẹp rủi ro sự cố xuống còn một phần ba mươi và tự khắc phục qua đêm rất hiệu quả.

---

### Câu 9 — /healthz khác /readyz (CP4)

Nếu gộp hai endpoint làm một và cho nó kiểm tra Redis, chuyện gì xảy ra với cụm
3 container khi Redis mất kết nối 30 giây? Trả lời theo đúng thứ tự sự kiện.

> Nếu gộp chung hai probe và Redis đứt kết nối, endpoint gộp sẽ trả lỗi 503. Đầu tiên, Load Balancer thấy 503 sẽ lập tức ngắt cả 3 container khỏi vòng định tuyến. Tiếp theo, Orchestrator hiểu nhầm ứng dụng đã sập hoàn toàn nên ra lệnh kill và restart lại toàn bộ cụm. Khi Redis phục hồi sau 30 giây, 3 container vẫn phải tốn thêm thời gian khởi động lại từ đầu, khiến hệ thống ngưng trệ rất lâu thay vì tự phục hồi ngay lập tức.

---

### Câu 10 — Deploy thật (CP5)

Ghi lại **một** lỗi bạn gặp khi deploy lên cloud (build fail, health check
timeout, sai REDIS_URL, app không đọc `$PORT`...): thông báo lỗi là gì, bạn
tìm ra nguyên nhân bằng cách nào, và sửa ra sao?

> Ở Build Logs và Deploy Logs trên Railway, tôi thấy 2 dòng: "1/1 replicas never became healthy!" và "Error: Invalid value for '--port': '$PORT' is not a valid integer". Tôi xem Build Logs thấy image build và push thành công nên loại trừ lỗi Docker, chuyển sang Deploy Logs thấy uvicorn báo lỗi tham số, đối chiếu railway.toml phát hiện startCommand. Xóa startCommand, để CMD của Dockerfile lo. CMD dùng sh -c nên có shell expand biến.
