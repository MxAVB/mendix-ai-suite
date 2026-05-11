-- =====================================================================
-- MENDIX AI SUITE — Supabase Schema
-- =====================================================================
-- Run this in Supabase SQL Editor (Database > SQL Editor > New query)
-- =====================================================================

-- Enable UUID generation
create extension if not exists "pgcrypto";

-- =====================================================================
-- ACCOUNTS
-- =====================================================================
create table accounts (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid references auth.users(id) on delete cascade,
  name          text not null,
  region        text default 'België & Luxemburg',
  email_format  text default '',
  tone          text default 'formeel',
  lang          text default 'NL',
  archived      boolean default false,
  dos_account   text default '',
  dos_icp       text default '',
  dos_personas  text default '',
  dos_signals   text default '',
  dos_competitors text default '',
  dos_deal      text default '',
  dos_approach  text default '',
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

-- =====================================================================
-- CONTACTS
-- =====================================================================
create table contacts (
  id              uuid primary key default gen_random_uuid(),
  account_id      uuid references accounts(id) on delete cascade,
  name            text not null,
  title           text default '',
  role            text default 'Influencer',
  email           text default '',
  phone           text default '',
  linkedin        text default '',
  lang            text default '',
  source          text default 'manual',  -- manual | mapping | research
  insight         text default '',
  strategy        text default '',
  name_edited     boolean default false,
  mapping_idx     integer,
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);

-- =====================================================================
-- SEQUENCES (per contact)
-- =====================================================================
create table sequences (
  id          uuid primary key default gen_random_uuid(),
  contact_id  uuid references contacts(id) on delete cascade,
  account_id  uuid references accounts(id) on delete cascade,
  touches     integer default 0,
  linked      boolean default false,
  created_at  timestamptz default now()
);

-- =====================================================================
-- HISTORIES (agent chat messages)
-- =====================================================================
create table histories (
  id          uuid primary key default gen_random_uuid(),
  account_id  uuid references accounts(id) on delete cascade,
  agent_tab   text not null,  -- research|signal|mapping|bdr|sequence|email|battle|objection|pipeline
  role        text not null,  -- user | agent
  html        text not null,
  pair_id     text,
  contact_id  uuid references contacts(id) on delete set null,
  created_at  timestamptz default now()
);

-- =====================================================================
-- TASKS
-- =====================================================================
create table tasks (
  id              uuid primary key default gen_random_uuid(),
  account_id      uuid references accounts(id) on delete cascade,
  contact_id      uuid references contacts(id) on delete set null,
  contact_name    text default '',
  text            text not null,
  date            date,
  prio            text default 'mid',  -- high | mid | low
  done            boolean default false,
  touch_type      text default '',     -- Email | LinkedIn | Bel
  touch_content   text default '',
  touch_subject   text default '',
  outreach_status text default 'none', -- none | sent | replied | noreply
  outreach_date   date,
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);

-- =====================================================================
-- NOTES
-- =====================================================================
create table notes (
  id          uuid primary key default gen_random_uuid(),
  account_id  uuid references accounts(id) on delete cascade,
  text        text not null,
  created_at  timestamptz default now()
);

-- =====================================================================
-- FAVORITES
-- =====================================================================
create table favorites (
  id          uuid primary key default gen_random_uuid(),
  account_id  uuid references accounts(id) on delete cascade,
  agent_tab   text not null,
  html        text not null,
  created_at  timestamptz default now()
);

-- =====================================================================
-- ACCOUNT MAPPING (stakeholder cards)
-- =====================================================================
create table mapping (
  id          uuid primary key default gen_random_uuid(),
  account_id  uuid references accounts(id) on delete cascade,
  name        text not null,
  title       text default '',
  role        text default '',
  insight     text default '',
  strategy    text default '',
  created_at  timestamptz default now()
);

-- =====================================================================
-- USAGE LOGS (per API call)
-- =====================================================================
create table usage_logs (
  id            uuid primary key default gen_random_uuid(),
  account_id    uuid references accounts(id) on delete cascade,
  user_id       uuid references auth.users(id) on delete cascade,
  agent_tab     text not null,
  input_tokens  integer default 0,
  output_tokens integer default 0,
  cost_eur      numeric(10,6) default 0,
  created_at    timestamptz default now()
);

-- =====================================================================
-- USER SETTINGS (suite-level, niet per account)
-- =====================================================================
create table user_settings (
  user_id   uuid primary key references auth.users(id) on delete cascade,
  region    text default 'België & Luxemburg',
  tone      text default 'formeel',
  lang      text default 'NL',
  updated_at timestamptz default now()
);

-- =====================================================================
-- INDEXES (performance)
-- =====================================================================
create index idx_accounts_user     on accounts(user_id);
create index idx_contacts_account  on contacts(account_id);
create index idx_histories_account on histories(account_id);
create index idx_histories_tab     on histories(account_id, agent_tab);
create index idx_tasks_account     on tasks(account_id);
create index idx_tasks_contact     on tasks(contact_id);
create index idx_tasks_date        on tasks(date);
create index idx_usage_account     on usage_logs(account_id);
create index idx_usage_created     on usage_logs(created_at);
create index idx_sequences_contact on sequences(contact_id);

-- =====================================================================
-- ROW LEVEL SECURITY (RLS)
-- Users can only access their own data
-- =====================================================================
alter table accounts     enable row level security;
alter table contacts     enable row level security;
alter table sequences    enable row level security;
alter table histories    enable row level security;
alter table tasks        enable row level security;
alter table notes        enable row level security;
alter table favorites    enable row level security;
alter table mapping      enable row level security;
alter table usage_logs   enable row level security;
alter table user_settings enable row level security;

-- Accounts: own rows only
create policy "accounts_own" on accounts
  for all using (auth.uid() = user_id);

-- Contacts: via account ownership
create policy "contacts_own" on contacts
  for all using (
    account_id in (select id from accounts where user_id = auth.uid())
  );

-- Sequences: via account ownership
create policy "sequences_own" on sequences
  for all using (
    account_id in (select id from accounts where user_id = auth.uid())
  );

-- Histories: via account ownership
create policy "histories_own" on histories
  for all using (
    account_id in (select id from accounts where user_id = auth.uid())
  );

-- Tasks: via account ownership
create policy "tasks_own" on tasks
  for all using (
    account_id in (select id from accounts where user_id = auth.uid())
  );

-- Notes: via account ownership
create policy "notes_own" on notes
  for all using (
    account_id in (select id from accounts where user_id = auth.uid())
  );

-- Favorites: via account ownership
create policy "favorites_own" on favorites
  for all using (
    account_id in (select id from accounts where user_id = auth.uid())
  );

-- Mapping: via account ownership
create policy "mapping_own" on mapping
  for all using (
    account_id in (select id from accounts where user_id = auth.uid())
  );

-- Usage logs: own rows only
create policy "usage_own" on usage_logs
  for all using (auth.uid() = user_id);

-- User settings: own row only
create policy "settings_own" on user_settings
  for all using (auth.uid() = user_id);

-- =====================================================================
-- AUTO-UPDATE updated_at trigger
-- =====================================================================
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger accounts_updated_at before update on accounts
  for each row execute function update_updated_at();
create trigger contacts_updated_at before update on contacts
  for each row execute function update_updated_at();
create trigger tasks_updated_at before update on tasks
  for each row execute function update_updated_at();
create trigger settings_updated_at before update on user_settings
  for each row execute function update_updated_at();

