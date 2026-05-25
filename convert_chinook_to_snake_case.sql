CREATE OR REPLACE FUNCTION public.to_snake_case(name text)
RETURNS text AS $$
BEGIN
  RETURN lower(
    regexp_replace(
      regexp_replace(name, '([a-z0-9])([A-Z])', '\1_\2', 'g'),
      '([A-Z]+)([A-Z][a-z])', '\1_\2', 'g'
    )
  );
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
    r record;
    new_col_name text;
BEGIN
    FOR r IN
        SELECT table_schema, table_name, column_name
        FROM information_schema.columns
        WHERE table_schema = 'public'
        ORDER BY table_name, ordinal_position
    LOOP
        new_col_name := public.to_snake_case(r.column_name);

        IF r.column_name <> new_col_name THEN
            EXECUTE format(
                'ALTER TABLE %I.%I RENAME COLUMN %I TO %I;',
                r.table_schema,
                r.table_name,
                r.column_name,
                new_col_name
            );
        END IF;
    END LOOP;
END $$;

DO $$
DECLARE
    r record;
    new_table_name text;
BEGIN
    FOR r IN
        SELECT table_schema, table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_type = 'BASE TABLE'
        ORDER BY table_name
    LOOP
        new_table_name := public.to_snake_case(r.table_name);

        IF r.table_name <> new_table_name THEN
            EXECUTE format(
                'ALTER TABLE %I.%I RENAME TO %I;',
                r.table_schema,
                r.table_name,
                new_table_name
            );
        END IF;
    END LOOP;
END $$;

DROP FUNCTION public.to_snake_case(text);