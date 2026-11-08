import { createDb, sql } from './packages/database/dist/index.js';

const databaseUrl = process.env.DATABASE_URL;
const coreToken = process.env.SB_API_TOKEN;

if (!databaseUrl) {
  throw new Error('DATABASE_URL is required');
}

// Brings the UI database up to the current schema (ui/packages/database/src/schema.ts).
// A new database gets the tables created; a database from the older UI (users
// with a plain password column, roles and user_roles tables) is migrated in place.
// Every statement is safe to run on every start.
const statements = [
  `
    CREATE TABLE IF NOT EXISTS users (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
      username text NOT NULL UNIQUE,
      password_hash text NOT NULL,
      role text NOT NULL DEFAULT 'viewer',
      created_at timestamp without time zone NOT NULL DEFAULT now(),
      updated_at timestamp without time zone NOT NULL DEFAULT now()
    )
  `,
  `
    ALTER TABLE users
    ADD COLUMN IF NOT EXISTS password_hash text
  `,
  `
    ALTER TABLE users
    ADD COLUMN IF NOT EXISTS role text
  `,
  `
    ALTER TABLE users
    ADD COLUMN IF NOT EXISTS created_at timestamp without time zone DEFAULT now()
  `,
  `
    DO $$
    BEGIN
      IF EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_schema = current_schema() AND table_name = 'users' AND column_name = 'password') THEN
        UPDATE users SET password_hash = password
        WHERE password_hash IS NULL AND password IS NOT NULL;
      END IF;
      IF to_regclass('user_roles') IS NOT NULL AND to_regclass('roles') IS NOT NULL THEN
        UPDATE users AS u
        SET role = r.name
        FROM user_roles ur
        JOIN roles r ON r.id = ur.role_id
        WHERE u.id = ur.user_id
          AND (u.role IS NULL OR u.role = '');
      END IF;
    END
    $$
  `,
  `
    UPDATE users
    SET role = 'viewer'
    WHERE role IS NULL OR role = ''
  `,
  `
    CREATE TABLE IF NOT EXISTS tokens (
      id text PRIMARY KEY,
      name text NOT NULL,
      scopes jsonb NOT NULL,
      token text NOT NULL,
      created_at timestamp without time zone NOT NULL
    )
  `,
  `
    CREATE TABLE IF NOT EXISTS app_state (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
      name text NOT NULL,
      payload jsonb DEFAULT '{}'::jsonb NOT NULL,
      updated_at timestamp without time zone DEFAULT now()
    )
  `,
];

const db = createDb(databaseUrl);
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

let lastError;

for (let attempt = 1; attempt <= 10; attempt += 1) {
  try {
    for (const statement of statements) {
      await db.execute(sql.raw(statement));
    }
    if (coreToken) {
      await db.execute(sql.raw(`
        INSERT INTO tokens (id, name, scopes, token, created_at)
        SELECT
          'slidebolt-core',
          'SlideBolt Core',
          '["read","write","control","admin"]'::jsonb,
          '${coreToken.replace(/'/g, "''")}',
          now()
        WHERE NOT EXISTS (SELECT 1 FROM tokens)
      `));
    }
    process.exit(0);
  } catch (error) {
    lastError = error;
    await sleep(1000 * attempt);
  }
}

throw lastError;
