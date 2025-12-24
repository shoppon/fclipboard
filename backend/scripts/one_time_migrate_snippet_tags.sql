BEGIN;

CREATE TABLE IF NOT EXISTS snippet_tags (
  snippet_id UUID NOT NULL REFERENCES snippets(id) ON DELETE CASCADE,
  tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (snippet_id, tag_id)
);

INSERT INTO snippet_tags (snippet_id, tag_id)
SELECT id, tag_id
FROM snippets
WHERE tag_id IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO snippet_tags (snippet_id, tag_id)
SELECT s.id, t.id
FROM snippets s
JOIN LATERAL jsonb_array_elements_text(COALESCE(s.tags, '[]'::jsonb)) AS tag_name
  ON true
JOIN tags t
  ON t.user_id = s.user_id
 AND lower(t.name) = lower(tag_name)
WHERE tag_name IS NOT NULL AND length(trim(tag_name)) > 0
ON CONFLICT DO NOTHING;

COMMIT;
