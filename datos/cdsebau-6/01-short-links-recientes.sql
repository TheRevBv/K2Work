SELECT id, code, case_id, created_at, LEFT(target_url, 120) AS target_url
FROM short_links ORDER BY id DESC LIMIT 20;
