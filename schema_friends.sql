-- 친구 · 자랑하기 · 교환 기능용 테이블 (schema.sql 을 먼저 실행한 뒤 한 번만 실행하세요)
-- Supabase 대시보드 > SQL Editor 에 통째로 붙여 넣고 Run

-- 1) 공개 프로필: 로그인한 사람은 모두 읽을 수 있고, 쓰기는 본인 행만 가능합니다.
create table if not exists public.profiles (
  user_id       uuid primary key references auth.users(id) on delete cascade,
  account       text not null unique,
  look          text,
  stage_cleared int  not null default 0,
  caught        int  not null default 0,
  owned         jsonb not null default '[]'::jsonb,
  party         jsonb not null default '[]'::jsonb,
  streak        int  not null default 0,
  questions     int  not null default 0,
  lessons       int  not null default 0,
  wins          int  not null default 0,
  updated_at    timestamptz not null default now()
);
alter table public.profiles enable row level security;
drop policy if exists "profiles read" on public.profiles;
drop policy if exists "profiles insert own" on public.profiles;
drop policy if exists "profiles update own" on public.profiles;
create policy "profiles read" on public.profiles for select to authenticated using (true);
create policy "profiles insert own" on public.profiles for insert to authenticated with check (auth.uid() = user_id);
create policy "profiles update own" on public.profiles for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 2) 교환 제안: 보낸 사람과 받는 사람만 볼 수 있습니다. 상대가 수락(accepted)해야 성사됩니다.
create table if not exists public.trades (
  id            uuid primary key default gen_random_uuid(),
  from_user     uuid not null references auth.users(id) on delete cascade,
  to_user       uuid not null references auth.users(id) on delete cascade,
  from_account  text not null,
  to_account    text not null,
  offer_no      int  not null,
  offer_lv      int  not null default 5,
  offer_nick    text,
  want_no       int  not null,
  want_lv       int  not null default 5,
  want_nick     text,
  status        text not null default 'pending' check (status in ('pending','accepted','declined','cancelled')),
  from_applied  boolean not null default false,
  to_applied    boolean not null default false,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
alter table public.trades enable row level security;
drop policy if exists "trades read" on public.trades;
drop policy if exists "trades insert" on public.trades;
drop policy if exists "trades update" on public.trades;
create policy "trades read" on public.trades for select to authenticated using (auth.uid() in (from_user, to_user));
create policy "trades insert" on public.trades for insert to authenticated with check (auth.uid() = from_user and status = 'pending');
create policy "trades update" on public.trades for update to authenticated using (auth.uid() in (from_user, to_user)) with check (auth.uid() in (from_user, to_user));

-- 3) 전체 공지(전설 가챠 축하): 로그인한 사람은 모두 읽을 수 있고, 쓰기는 본인 이름으로만 가능합니다.
create table if not exists public.announcements (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  account     text not null,
  kind        text not null default 'legend',
  text        text not null,
  created_at  timestamptz not null default now()
);
alter table public.announcements enable row level security;
drop policy if exists "announcements read" on public.announcements;
drop policy if exists "announcements insert" on public.announcements;
create policy "announcements read" on public.announcements for select to authenticated using (true);
create policy "announcements insert" on public.announcements for insert to authenticated with check (auth.uid() = user_id);

-- 4) 버그 제보: 로그인한 사람이 자기 이름으로 쓰고, 개발자(점검용)가 읽을 수 있도록 공개 읽기를 허용합니다. 개인정보는 적지 마세요.
create table if not exists public.bug_reports (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  account     text not null,
  text        text not null,
  ctx         jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now()
);
alter table public.bug_reports enable row level security;
drop policy if exists "bugs read" on public.bug_reports;
drop policy if exists "bugs insert" on public.bug_reports;
create policy "bugs read" on public.bug_reports for select to anon, authenticated using (true);
create policy "bugs insert" on public.bug_reports for insert to authenticated with check (auth.uid() = user_id);
