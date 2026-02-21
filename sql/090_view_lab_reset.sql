-- phase: 9
-- topic: view_labスキーマのリセット
-- dataset: ec-v1（publicは触らない。view_labだけ削除）
DROP SCHEMA IF EXISTS view_lab CASCADE;

-- 確認（任意）
-- SELECT nspname FROM pg_namespace WHERE nspname = 'view_lab';
