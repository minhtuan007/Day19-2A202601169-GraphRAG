# Thuyết minh kỹ thuật — GraphRAG vs Flat RAG

## 1. Conservative coreference

Pipeline chỉ chạy LLM coreference trên 5 evidence chunks để spot-check; 46 chunks còn lại giữ nguyên và gắn `NOT_RUN_SCALE_GUARD`. Quy tắc này ưu tiên precision: chỉ thay đại từ khi antecedent xuất hiện rõ trong cùng chunk. Trong sample, 5 chunk đầu không cần thay thế. Failure mode nguy hiểm nhất là gán “it/the company” sang sai doanh nghiệp; lỗi đó tạo false edge và lan sang mọi truy vấn nhiều hop. Vì vậy giữ nguyên một mention mơ hồ tốt hơn tạo một cạnh sai.

## 2. Ngưỡng entity resolution

Ngưỡng vector là `0.90`, sau đó mới áp dụng lexical guard `SequenceMatcher >= 0.72` sau khi bỏ hậu tố công ty. Audit thực tế có 153 candidate và không có cặp nào đủ cả hai điều kiện để merge. Cặp gần nhất là `ChatGPT technology` / `ChatGPT plug-ins` với cosine `0.8021`, bị từ chối vì dưới ngưỡng; đây là quyết định đúng vì công nghệ nền và hệ plug-in không phải cùng một entity.

## 3. Audit và chống false merge

Mọi candidate ANN được log với `similarity`, `decision`, `reason`. Kết quả hiện tại: 153 `REJECT_GUARD`; không có merge vector thiếu chắc chắn. Ví dụ khác: `Llama 2` / `Code Llama` (`0.7835`) và `Aeris Communications` / `Aeris` (`0.7388`). Cặp Aeris là một false negative có chủ ý của cấu hình bảo thủ; muốn tăng recall nên thêm alias thủ công có audit thay vì hạ threshold toàn cục.

## 4. Đặc trưng graph

Graph sau extraction có 56 nodes, 41 edges và 0 edge thiếu provenance. Ba node degree cao nhất:

| Hạng | Entity | Type | Degree |
|---:|---|---|---:|
| 1 | ServiceNow | Company | 7 |
| 2 | Microsoft | Company | 7 |
| 3 | Google Cloud | Company | 4 |

## 5. Super-node mitigation

Sample không có node degree >100, nên notebook kiểm tra boundary tổng hợp `degree=101 -> edge limit=50`; `GLOBAL_EDGE_CAP=250` vẫn được assert. Ưu điểm của việc lấy 50 cạnh mới nhất là giới hạn fan-out/token và ưu tiên thông tin hiện hành. Rủi ro là câu hỏi lịch sử có thể mất cạnh cũ; production nên lọc theo time range của câu hỏi trước, rồi mới dùng recency làm tie-breaker.

## 6. Latency và token

Số đo trên 50 câu đã sinh đáp án:

| Metric | Flat RAG | GraphRAG | Delta Graph-Flat |
|---|---:|---:|---:|
| Latency trung bình (s) | 6.856 | 11.891 | +5.035 |
| Token trung bình | 905.48 | 1243.78 | +338.30 |

GraphRAG đắt hơn do seed matching, BFS và context graph bổ sung. Điểm LLM-as-a-Judge được xuất từ OpenRouter vào `outputs/graphrag_eval_results.csv`; runner dùng batch 5 câu và checkpoint để phù hợp quota free.

## 7. Ca Flat RAG thất bại

`G5000-34` yêu cầu so sánh hệ sinh thái AI của Google Cloud và Amazon. Flat RAG chỉ lấy được các đoạn về Amazon và từ chối liệt kê phía Google. GraphRAG trả đúng chuỗi nhà cung cấp Google Cloud — Meta (`Llama 2`, `Code Llama`), Technology Innovation Institute (`Falcon`), Anthropic (`Claude 2`) — và Amazon/Cohere. Nguyên nhân là evidence nằm rải ở nhiều records; graph context nối các entity/technology trước khi generation.

## 8. Ca GraphRAG thất bại

`G5000-45` là ca lỗi rõ: Graph answer trả `User Safety: safe`, trong khi Flat RAG nhận ra hai reports mô tả cùng một sự kiện Thales chọn LTTS và Qualcomm. Root cause là model free được router chọn ở lượt fallback không tuân thủ instruction generation. Cách khắc phục: validate câu trả lời tối thiểu, retry khi output quá ngắn/không chứa entity seed, pin một model ổn định trong production, và dùng event canonicalization `(participants, normalized predicate, time window)`.

## 9. Kiểm soát AI coding agent

Đề xuất bị từ chối là pairwise cosine O(N²) trên toàn corpus và hạ threshold để ép có merge. Thay vào đó pipeline dùng FAISS top-k, lexical guard và audit. Một sửa quan trọng khác là không chấp nhận JSON “đúng cú pháp nhưng sai shape”: coreference/extraction dùng strict JSON Schema; OpenRouter judge có validation và retry.

## 10. Scale lên 350 MB

Bottleneck đầu tiên là LLM extraction/quota, sau đó là entity resolution và graph fan-out. Kiến trúc đề xuất: queue bất đồng bộ, idempotent chunk checkpoint, cache theo content hash/prompt version, batch extraction, HNSW/FAISS blocking theo entity type, alias registry có human review, Neo4j `UNWIND` theo batch, partition/community theo thời gian/chủ đề, và observability cho retry/rate-limit/provenance drift.

