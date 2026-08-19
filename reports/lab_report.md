# Báo cáo Lab 19 — Production GraphRAG vs Flat RAG

Pipeline đã hoàn thiện năm module chính, không chạy bonus theo yêu cầu.

## Kết quả pipeline

- Corpus retrieval: first 5,000 records đúng scope golden; 5,000 chunks trong FAISS.
- Golden evidence: 51/51 records có trong extraction corpus.
- Coreference: 5-chunk conservative spot-check; 46 chunks giữ nguyên theo scale guard.
- Knowledge graph: 56 nodes, 41 edges, 0 edge thiếu provenance.
- Entity resolution audit: 153 candidates, tất cả bị guard/threshold từ chối; không có unsafe merge.
- Generation: 50/50 câu hoàn tất và checkpoint.
- Bonus: không chạy.

## Benchmark vận hành

| Metric | Flat RAG | GraphRAG |
|---|---:|---:|
| Latency trung bình (s) | 6.856 | 11.891 |
| Token trung bình | 905.48 | 1243.78 |

Kết quả judge chi tiết và summary được xuất vào `outputs/` bởi OpenRouter runner. Phân tích kỹ thuật đầy đủ nằm tại:

- `reports/technical_defense.md`
- `reports/failure_analysis.md`
- `reports/reflection_student.md`

