# Failure analysis — Flat RAG và GraphRAG

## Case A — Flat RAG thiếu evidence cross-document (`G5000-34`)

**Triệu chứng:** Flat chỉ thấy phía Amazon nên trả rằng context không có Google Cloud. GraphRAG liệt kê được Meta/Llama 2/Code Llama, TII/Falcon, Anthropic/Claude 2 và Amazon/Cohere.

**Root cause:** top-k vector search xếp các chunks có từ khóa Amazon cao hơn; sáu vị trí retrieval không bảo đảm phủ cả hai nửa của câu hỏi so sánh. Evidence Google Cloud nằm ở record khác và dùng từ vựng model/provider không hoàn toàn trùng câu hỏi.

**Vì sao graph giúp:** seed `Google Cloud`, `Amazon` mở hai vùng lân cận; các cạnh technology/provider bổ sung evidence ngoài ranking vector đơn lẻ.

**Khắc phục cho Flat:** query decomposition theo từng entity, retrieve riêng mỗi sub-query, reciprocal-rank fusion và diversity/MMR trước generation.

## Case B — GraphRAG/model fallback tạo output không hợp lệ (`G5000-45`)

**Triệu chứng:** Graph answer chỉ là `User Safety: safe`; Flat trả đúng chiến lược canonicalize một event và giữ nhiều provenance records.

**Root cause:** Groq hết TPD, generation chuyển sang `openrouter/free`; model ngẫu nhiên được route ở lượt đó tạo output kiểu classifier thay vì answer. Đây là failure của model routing/output validation, không phải retrieval.

**Khắc phục:** pin model trong production; schema hóa output answer; reject câu trả lời quá ngắn hoặc không chứa entity quan trọng; retry provider khác; lưu model ID/provider vào từng result để audit.

## Case C — Provenance drift trong batch extraction

**Triệu chứng:** strict JSON hợp lệ nhưng model đôi khi gom quan hệ của nhiều input records dưới `chunk_id` đầu batch.

**Root cause:** JSON Schema bảo đảm shape/type nhưng không thể bảo đảm foreign-key semantic constraint “mỗi relation thuộc đúng input chunk”.

**Khắc phục đã áp dụng:** `repair_triple_provenance()` xếp hạng toàn bộ 51 evidence chunks theo entity containment và evidence-token overlap, rồi cập nhật `source_chunk_id`, `published_date`, `evidence`. Sau repair: 41/41 edges có provenance; spot-check AP/OpenAI, Samsung/Aqara, DEWA/ChatGPT trở về đúng chunk/date.

