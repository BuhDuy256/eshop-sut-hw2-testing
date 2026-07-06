# Kịch bản quay video demo — Agent Skill end-to-end (FR-08)

> ⚠️ **CẦN SỬA LẠI, chưa quay theo bản này.** Kịch bản dưới đây dựng quanh Decision Table của
> FR-09 (coupon) — nhưng FR-09 **không phải** 1 trong 4 feature được giao
> (`docs/hw2-reqs/features-that-need-testing.md`: chỉ FR-04, FR-08, FR-15, FR-17), và toàn bộ
> nội dung FR-09 (bao gồm Decision Table) đã bị gỡ khỏi phạm vi FR-08. Hiện tại **chưa có
> feature nào trong 4 feature được giao có Decision Table** — cần chờ làm xong FR-17 (feature
> coupon thật sự được giao) mới biết có Decision Table hay không. Kịch bản Cảnh 4 (EP +
> Decision Table) và các đoạn nói liên quan tới FR-09/C1-C5 bên dưới đang **sai**, cần viết
> lại sau khi FR-15/FR-17 xong — khi đó chọn feature demo phù hợp hơn (có thể vẫn là FR-08 nếu
> không feature nào có Decision Table, hoặc FR-17 nếu nó có).
>
> Mục đích gốc: đáp ứng §7 của `docs/hw2-reqs/2026.HW02.Domain Testing_En.md` — "demonstration
> videos that show, end to end, how you used the skills on a complete feature."
> Thời lượng gợi ý: 7–9 phút. Đọc thoải mái theo giọng của bạn, không cần đọc từng chữ.

---

## Cảnh 0 — Mở đầu (15–20 giây)

**Nói:**
> "Video này demo cách mình dùng hai Agent Skill tự xây — `domain-test-design` và
> `bug-reporting` — để test tính năng Checkout và Coupon của hệ thống EShop, từ lúc đọc spec
> cho tới lúc ra bug report và file GitHub issue."

**Màn hình:** để trống hoặc mở VS Code ở thư mục gốc project.

---

## Cảnh 1 — Spec (30–40 giây)

**Mở:** `README.md`, cuộn tới dòng ~102 (FR-08) và ~110 (FR-09).

**Nói:**
> "Đây là spec — README của hệ thống. FR-08 nói: chỉ người đăng nhập mới thanh toán được,
> backend phải tự tính lại tổng tiền, không được tin giá trị `total_amount` client gửi lên,
> và sau khi thanh toán thành công thì giỏ hàng phải được xóa."
>
> "FR-09 định nghĩa 5 điều kiện để áp mã giảm giá — C1 tới C5 — mã phải tồn tại và active,
> còn hạn, đơn hàng đủ ngưỡng tối thiểu, người dùng phải đăng nhập, và chưa dùng hết lượt.
> Tất cả 5 điều kiện phải thỏa mãn cùng lúc."

**Chỉ tay vào bảng 5 điều kiện trong README khi nói.**

---

## Cảnh 2 — Giới thiệu Skill (30–40 giây)

**Mở:** `.claude/skills/domain-test-design/SKILL.md`.

**Nói:**
> "Đây là skill mình tự viết — `domain-test-design`. Nó có 6 giai đoạn: đầu tiên là build
> Testing Model từ spec và code — domain, boundary, oracle cho từng biến. Sau đó kiểm tra lại
> mọi assumption xem có thể quy về spec trực tiếp không, để tránh đoán mò. Rồi mới tới
> Equivalence Partitioning, Boundary Value Analysis, và chỉ build Decision Table khi thật sự
> có nhiều điều kiện phải thỏa mãn cùng lúc — đúng như 5 điều kiện coupon ở FR-09."
>
> "Điểm quan trọng nhất: MODEL không bao giờ là ORACLE — code chỉ giúp mình biết *chỗ nào*
> cần test, còn *đúng hay sai* thì luôn lấy từ spec, không bao giờ lấy từ code hay từ kết quả
> chạy thử."

**Cuộn nhanh qua 6 Stage trong file, không cần đọc hết.**

---

## Cảnh 3 — Testing Model (45–60 giây)

**Mở:** `work/FR-08-checkout/testing-model.md`, phần "Extended scope".

**Nói:**
> "Đây là Testing Model mình build ra cho FR-08/FR-09. Ví dụ với điều kiện C3 — đủ ngưỡng đơn
> hàng — spec nói rõ là `>=`, tức là bằng ngưỡng vẫn được tính. Nhưng khi mình đọc code ở
> `server.js` dòng 379 thì thấy code dùng dấu `>`, tức là *loại trừ* đúng điểm bằng ngưỡng.
> Đây chính là chỗ spec và code mâu thuẫn nhau — mình ghi lại cả hai, không tự ý chọn cái nào
> đúng ở bước này, để dành cho lúc chạy test thật mới xác nhận."
>
> "Tương tự với C4 — bắt buộc phải đăng nhập — khi đọc code thì thấy endpoint
> `apply-coupon` không hề có middleware xác thực nào cả."

**Chỉ vào đúng dòng "Coupon — C3" và "Coupon — C4" trong file khi nói.**

---

## Cảnh 4 — Equivalence Partitioning + Decision Table (60–75 giây)

**Mở:** `out/reports/FR-08-checkout/domain-testing/report.md`.

**Nói:**
> "Từ model đó, skill thiết kế ra các test case theo Equivalence Partitioning — mỗi lớp giá
> trị hợp lệ/không hợp lệ có một case riêng. Ví dụ `TC-08-EP-007` test trường hợp đơn hàng
> chưa đủ ngưỡng, `TC-08-EP-008` test trường hợp không có token nhưng vẫn giả mạo user_id."
>
> "Và vì FR-09 có 5 điều kiện phải thỏa mãn cùng lúc, skill build thêm một Decision Table —
> đây là phần thể hiện rõ nhất năng lực của skill, vì FR-04 hay FR-15 không có phần này.
> Mình không làm bảng đầy đủ 32 tổ hợp, mà chỉ chọn 7 dòng thật sự cho ra kết quả khác nhau —
> vì code xử lý các điều kiện theo thứ tự lồng nhau, không độc lập."

**Cuộn tới bảng Decision Table, chỉ vào cột kết quả khác nhau ở vài dòng.**

---

## Cảnh 5 — Boundary Value Analysis (45 giây)

**Mở:** `out/reports/FR-08-checkout/boundary-value-analysis/report.md`.

**Nói:**
> "Đây là phần Boundary Value Analysis — ba giá trị quanh ngưỡng 300,000: 299,999 (dưới),
> 300,000 (đúng ngưỡng), và 300,001 (trên ngưỡng). `TC-08-BVA-002` — đúng ngưỡng — chính là
> case quan trọng nhất, vì đây là chỗ spec và code mâu thuẫn nhau ở Cảnh 3."

---

## Cảnh 6 — Execution thật (60–75 giây)

**Mở:** `work/FR-08-checkout/execution-results.md`, kéo tới `ER-08-BVA-002`.

**Nói:**
> "Đây là lúc mình chạy test thật — không phải giả lập, mà gọi API thật trên Docker container
> đang chạy. Với `TC-08-BVA-002` — gửi `total_amount = 300000` — theo spec thì phải được chấp
> nhận. Nhưng response thực tế trả về 400, báo 'chưa đủ giá trị tối thiểu'. Đúng như dự đoán —
> code dùng dấu `>` chứ không phải `>=`."

**Có thể mở thêm terminal, chạy lại 1-2 lệnh `curl` thật để người xem thấy trực tiếp (không
bắt buộc, nhưng tăng độ thuyết phục).**

---

## Cảnh 7 — Bug Reporting Skill + kết quả (45–60 giây)

**Mở:** `.claude/skills/bug-reporting/SKILL.md` (lướt nhanh), rồi
`out/reports/FR-08-checkout/bug-reports/report.md`.

**Nói:**
> "Từ các kết quả FAIL, skill thứ hai — `bug-reporting` — xác nhận đây có phải bug thật không,
> gom các case cùng nguyên nhân gốc lại với nhau, rồi mới đánh severity. Ví dụ hai case khác
> nhau — giả mạo user_id và bỏ trống user_id — được gộp chung vào một bug duy nhất là
> `BUG-08-003`, vì chỉ cần sửa một chỗ trong code là fix được cả hai."
>
> "Tổng cộng FR-08 tìm ra 5 bug được xác nhận, tất cả đều đã được file lên GitHub Issues."

**Mở trình duyệt, vào GitHub Issues của repo, chỉ 1-2 issue (ví dụ #4 hoặc #5) cho người xem
thấy issue thật, có nội dung khớp với report.**

---

## Cảnh 8 — Kết (15–20 giây)

**Nói:**
> "Đó là toàn bộ quy trình — từ spec, qua model, EP, BVA, Decision Table, chạy test thật, cho
> tới bug report và GitHub issue — hoàn toàn qua hai Agent Skill có thể tái sử dụng cho các
> feature khác."

---

## Ghi chú khi quay

- Không cần quay liền một mạch — quay từng Cảnh, cắt ghép lại sau nếu thấy tiện hơn.
- Nếu nói vấp, cứ dừng, hít thở, nói lại câu đó — cắt ở bước edit.
- Ưu tiên **thấy được nội dung thật trên màn hình** (spec, model, report, issue) hơn là nói
  suôn — giám khảo cần thấy bằng chứng, không chỉ nghe mô tả.
- Sau khi quay: xuất video, upload YouTube ở chế độ **Unlisted** (không cần Public, chỉ cần
  ai có link cũng xem được), rồi dán link vào `out/README.md`, mục test summary.
