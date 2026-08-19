# Reflection & Action Plan

## Mapping bài giảng vào code

| Khái niệm | Module | Hàm/khối code | Quan sát thực tế |
|---|---|---|---|
| Conservative coreference | M1 | `resolve_coref_batch()`, `run_coref()` | Spot-check 5 chunks; phần ngoài budget giữ nguyên và được đánh dấu. |
| Exact dedup + chunking | M1 | `standardize_news()`, `chunk_text()`, `build_chunks()` | 9,644 records đủ text giảm còn 8,350 unique; benchmark index đúng first-5000 scope. |
| Schema/allowlist | M2 | `EXTRACT_JSON_SCHEMA`, `ALLOWED_*` | Strict schema ngăn JSON sai type; semantic provenance vẫn cần hậu kiểm. |
| Bulk ingestion | M2 | `bulk_insert_nodes()`, `bulk_insert_edges()` | Cypher dùng `UNWIND`; backend memory cho phép chạy khi Aura credential lỗi. |
| Entity resolution | M3 | `build_resolution_map()`, `UF`, `merge_guard()` | 153 candidates bị từ chối; không ép merge khi thiếu bằng chứng. |
| Flat retrieval | M4 | `build_flat_index()`, `retrieve_flat_context()` | Index 5,000 chunks bằng cosine/IP. |
| Graph traversal | M4 | `match_seeds()`, `retrieve_graph_context()` | BFS 2 hops, cap 50/250, context 14K chars. |
| LLM judge | M5 | `judge_batch()`, `run_evaluation()` | OpenRouter free, batch 5, strict validation, checkpoint/resume. |

## Debugging và bài học

Lỗi khó nhất không phải syntax mà là tương tác giữa quota và tính đúng semantic. JSON hợp lệ vẫn có thể gán sai `chunk_id`; free router có thể đổi model và trả output khác hẳn kỳ vọng. Cách xử lý hiệu quả là kiểm tra invariants tại ranh giới: schema type, foreign-key provenance, evidence overlap, output length/entity coverage, cùng checkpoint theo `run_signature` để không chạy lại các tầng tốn tiền.

## Action plan đồ án

**Đồ án giả định:** trợ lý nghiên cứu tin công nghệ theo thời gian.

Flat/Hybrid RAG đủ cho factoid một tài liệu; GraphRAG cần thiết cho câu hỏi về chuỗi đầu tư–mua lại–đối tác, trạng thái sự kiện thay đổi, và tổng hợp nhiều nguồn.

- Nodes: `Company`, `Person`, `Technology`, về sau thêm `Event` để canonicalize cùng một giao dịch qua nhiều bài.
- Relations: `ACQUIRED`, `INVESTED_IN`, `DEVELOPED`, `PARTNERED_WITH`, `USES`, kèm event-state và temporal validity.
- Entity resolution: alias registry + ANN blocking theo type + lexical guard + human review cho vùng xám.
- Super-node: query-time temporal/type filter, per-node top-N, global edge cap, community partition.
- Vận hành: content-hash cache, retry queue, model/version lineage và dashboard tỷ lệ missing/repair provenance.

