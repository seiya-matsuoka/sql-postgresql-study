-- phase: 7
-- topic: labスキーマのリセット（壊して学ぶ前提の初期化）
-- dataset: ec-v1（同じDB内の lab を消すだけ。ec-v1本体は触らない）
DROP SCHEMA IF EXISTS lab CASCADE;

-- 確認（任意）
-- SELECT nspname FROM pg_namespace WHERE nspname = 'lab';
