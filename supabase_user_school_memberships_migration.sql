-- ═══════════════════════════════════════════════════════════════════
-- user_school_memberships tablosu — Supabase'de oluşturma
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.user_school_memberships (
    id          SERIAL PRIMARY KEY,
    user_id     VARCHAR(255) NOT NULL,
    school_id   INTEGER      NOT NULL,
    role        VARCHAR(50)  NOT NULL DEFAULT 'admin',
    CONSTRAINT  uq_user_school UNIQUE (user_id, school_id)
);

-- İndeksler
CREATE INDEX IF NOT EXISTS ix_user_school_memberships_user_id
    ON public.user_school_memberships (user_id);
CREATE INDEX IF NOT EXISTS ix_user_school_memberships_school_id
    ON public.user_school_memberships (school_id);

-- ═══════════════════════════════════════════════════════════════════
-- RLS (Row Level Security)
-- ═══════════════════════════════════════════════════════════════════

ALTER TABLE public.user_school_memberships ENABLE ROW LEVEL SECURITY;

-- Kullanıcılar sadece kendi üyeliklerini görebilir
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'user_school_memberships'
          AND policyname = 'Users can view own memberships'
    ) THEN
        EXECUTE 'CREATE POLICY "Users can view own memberships"
            ON public.user_school_memberships
            FOR SELECT
            USING (auth.uid()::text = user_id)';
    END IF;
END $$;

-- Kullanıcılar kendi üyeliklerini ekleyebilir
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'user_school_memberships'
          AND policyname = 'Users can insert own memberships'
    ) THEN
        EXECUTE 'CREATE POLICY "Users can insert own memberships"
            ON public.user_school_memberships
            FOR INSERT
            WITH CHECK (auth.uid()::text = user_id)';
    END IF;
END $$;
