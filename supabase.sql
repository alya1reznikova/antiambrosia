-- Вставьте этот текст целиком в Supabase: раздел SQL Editor -> New query -> Run.

create table if not exists reports (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  lat double precision not null,
  lng double precision not null,
  address text,
  place text,
  size text,
  comment text,
  photo_url text,
  after_url text,
  status text not null default 'pending' check (status in ('pending','work','done','rejected')),
  demo boolean not null default false
);

alter table reports enable row level security;

-- Читать карту могут все; отклонённые заявки видит только исполнитель (вошедший в кабинет)
create policy "reports_read" on reports for select
  using (status <> 'rejected' or auth.role() = 'authenticated');

-- Любой житель может отправить новую заявку, но только со статусом «на проверке»
create policy "reports_insert" on reports for insert
  with check (status = 'pending' and after_url is null);

-- Менять статус может только вошедший исполнитель
create policy "reports_update" on reports for update
  to authenticated using (true) with check (true);

-- Хранилище для фото
insert into storage.buckets (id, name, public) values ('photos', 'photos', true)
  on conflict (id) do nothing;

create policy "photos_insert" on storage.objects for insert
  to anon, authenticated with check (bucket_id = 'photos');
create policy "photos_read" on storage.objects for select
  using (bucket_id = 'photos');

-- Настройки сайта (уровень пыльцы, который вручную указывает команда)
create table if not exists settings (
  key text primary key,
  value jsonb not null default '{}',
  updated_at timestamptz not null default now()
);
alter table settings enable row level security;
create policy "settings_read" on settings for select using (true);
create policy "settings_insert" on settings for insert to authenticated with check (true);
create policy "settings_update" on settings for update to authenticated using (true) with check (true);
