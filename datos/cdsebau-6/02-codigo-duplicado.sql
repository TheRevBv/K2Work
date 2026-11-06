SELECT code, COUNT(*) n FROM short_links GROUP BY code HAVING n > 1;
