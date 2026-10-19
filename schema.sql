-- 외노자가 되기 위한 모험: 진도 저장 테이블
-- Supabase 대시보드 > SQL Editor 에 통째로 붙여 넣고 Run 하세요.

create table if not exists public.progress (
  user_id       uuid primary key references auth.users(id) on delete cascade,
  account       text not null,
  data          jsonb not null default '{}'::jsonb,   -- 게임 전체 저장 데이터
  stage_cleared int  not null default 0,               -- 보스를 이긴 스테이지 수 (0~30)
  stage_name    text,                                  -- 마지막으로 클리어한 회사
  coins         int  not null default 0,
  wins          int  not null default 0,
  caught        int  not null default 0,               -- 잡은 포켓몬 수
  last_login    text,
  updated_at    timestamptz not null default now()
);

alter table public.progress enable row level security;

-- 로그인한 본인 행만 읽고 쓸 수 있습니다.
drop policy if exists "own select" on public.progress;
drop policy if exists "own insert" on public.progress;
drop policy if exists "own update" on public.progress;
create policy "own select" on public.progress for select using (auth.uid() = user_id);
create policy "own insert" on public.progress for insert with check (auth.uid() = user_id);
create policy "own update" on public.progress for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 전체 현황 보기(대시보드 Table Editor 또는 SQL Editor에서 실행하면 3명 모두 보입니다)
-- select account, stage_cleared, stage_name, coins, wins, caught, last_login, updated_at
-- from public.progress order by account;
