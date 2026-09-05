-- =====================================================================
--  Integrador QR — galería de diseños administrable
--  Proyecto Supabase: embudos-emprenya (ebkbpinafabnyfllswgb)
--
--  Ejecuta este archivo entero en el SQL Editor de Supabase.
--  Es idempotente: puedes lanzarlo más de una vez sin romper nada.
-- =====================================================================

-- ---------------------------------------------------------------- tablas
create table if not exists public.disenos_qr_categorias (
  id         uuid primary key default gen_random_uuid(),
  nombre     text not null unique,
  orden      int  not null default 0,
  visible    boolean not null default true,
  created_at timestamptz not null default now()
);

comment on table public.disenos_qr_categorias is
  'Grupos del desplegable de diseños del Integrador QR (los <optgroup>).';

create table if not exists public.disenos_qr (
  id           uuid primary key default gen_random_uuid(),
  categoria_id uuid not null references public.disenos_qr_categorias(id) on delete cascade,
  nombre       text not null,
  -- URL que carga el generador: ruta relativa del repo ('pdf/...') para los
  -- diseños de siempre, o la URL pública de Storage para los que se suban.
  url          text not null,
  origen       text not null default 'storage' check (origen in ('storage','repo')),
  storage_path text,
  orden        int  not null default 0,
  visible      boolean not null default true,
  created_at   timestamptz not null default now()
);

comment on table public.disenos_qr is
  'Diseños que aparecen en el desplegable del Integrador QR.';
comment on column public.disenos_qr.origen is
  'repo = el archivo vive en la carpeta pdf/ del repositorio; storage = subido desde el panel.';

create index if not exists disenos_qr_categoria_idx on public.disenos_qr (categoria_id, orden);
create unique index if not exists disenos_qr_url_idx on public.disenos_qr (url);

-- ------------------------------------------------------------------- RLS
alter table public.disenos_qr_categorias enable row level security;
alter table public.disenos_qr            enable row level security;

-- Lectura pública de lo visible; el admin ve también lo oculto.
drop policy if exists "lectura publica" on public.disenos_qr_categorias;
create policy "lectura publica" on public.disenos_qr_categorias
  for select to anon, authenticated
  using (visible or public.is_admin());

drop policy if exists "escritura admin" on public.disenos_qr_categorias;
create policy "escritura admin" on public.disenos_qr_categorias
  for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

drop policy if exists "lectura publica" on public.disenos_qr;
create policy "lectura publica" on public.disenos_qr
  for select to anon, authenticated
  using (visible or public.is_admin());

drop policy if exists "escritura admin" on public.disenos_qr;
create policy "escritura admin" on public.disenos_qr
  for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- --------------------------------------------------------------- storage
-- Bucket público: el generador descarga los PDF sin sesión.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('disenos-qr', 'disenos-qr', true, 52428800, array['application/pdf'])
on conflict (id) do update
  set public             = true,
      file_size_limit    = 52428800,
      allowed_mime_types = array['application/pdf'];

drop policy if exists "disenos_qr lectura publica" on storage.objects;
create policy "disenos_qr lectura publica" on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'disenos-qr');

drop policy if exists "disenos_qr escritura admin" on storage.objects;
create policy "disenos_qr escritura admin" on storage.objects
  for all to authenticated
  using (bucket_id = 'disenos-qr' and public.is_admin())
  with check (bucket_id = 'disenos-qr' and public.is_admin());

-- ------------------------------------------------- semilla: lo que ya hay
-- Las 4 categorías y los 13 diseños que hoy están escritos a mano en el
-- index.html, para que el panel arranque enseñando lo que ya existe.
insert into public.disenos_qr_categorias (nombre, orden) values
  ('emprenYA',   1),
  ('Banners A2', 2),
  ('Banners A3', 3),
  ('Banners A4', 4)
on conflict (nombre) do nothing;

insert into public.disenos_qr (categoria_id, nombre, url, origen, orden)
select c.id, d.nombre, d.url, 'repo', d.orden
from (values
  ('emprenYA',   'TRÍPTICO Original',        'pdf/TRÍPTICO Original.pdf',        1),
  ('emprenYA',   'TRÍPTICO QR Básico',       'pdf/TRÍPTICO QR Básico.pdf',       2),
  ('emprenYA',   'TRÍPTICO QR y plan',       'pdf/TRÍPTICO QR y plan.pdf',       3),
  ('emprenYA',   'TRÍPTICO Teléfono y Plan', 'pdf/TRÍPTICO Teléfono y Plan.pdf', 4),
  ('Banners A2', 'TOMAYA-01-Formato-A2',     'pdf/TOMAYA-01-Formato-A2.pdf',     1),
  ('Banners A2', 'viajaYA-01-Formato-A2',    'pdf/viajaYA-01-Formato-A2.pdf',    2),
  ('Banners A2', 'NATURKIN-01-Formato-A2',   'pdf/NATURKIN-01-Formato-A2.pdf',   3),
  ('Banners A3', 'TOMAYA-01-Formato-A3',     'pdf/TOMAYA-01-Formato-A3.pdf',     1),
  ('Banners A3', 'viajaYA-01-Formato-A3',    'pdf/viajaYA-01-Formato-A3.pdf',    2),
  ('Banners A3', 'NATURKIN-01-Formato-A3',   'pdf/NATURKIN-01-Formato-A3.pdf',   3),
  ('Banners A4', 'TOMAYA-01-Formato-A4',     'pdf/TOMAYA-01-Formato-A4.pdf',     1),
  ('Banners A4', 'viajaYA-01-Formato-A4',    'pdf/viajaYA-01-Formato-A4.pdf',    2),
  ('Banners A4', 'NATURKIN-01-Formato-A4',   'pdf/NATURKIN-01-Formato-A4.pdf',   3)
) as d(cat, nombre, url, orden)
join public.disenos_qr_categorias c on c.nombre = d.cat
where not exists (select 1 from public.disenos_qr x where x.url = d.url);

-- ------------------------------------------------------------ comprobación
-- select c.nombre as categoria, d.nombre, d.origen, d.visible
-- from public.disenos_qr d
-- join public.disenos_qr_categorias c on c.id = d.categoria_id
-- order by c.orden, d.orden;
