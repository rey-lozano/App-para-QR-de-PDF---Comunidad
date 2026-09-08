-- =====================================================================
--  Integrador QR — enlace de impresión por diseño
--  Proyecto Supabase: embudos-emprenya (ebkbpinafabnyfllswgb)
--
--  Ejecútalo entero en el SQL Editor. Es idempotente: puedes lanzarlo
--  más de una vez sin romper nada. No borra ni cambia datos existentes.
--
--  Qué hace: añade a cada diseño de la galería dos campos opcionales:
--  el enlace para mandarlo a imprimir y la configuración que hay que
--  elegir en la imprenta (plegado, tamaño, material, gramaje...).
--  Los diseños que ya existen quedan con los dos campos vacíos y en el
--  generador no les sale ningún botón, así que nada cambia hasta que
--  tú los rellenes desde el panel.
-- =====================================================================

alter table public.disenos_qr
  add column if not exists enlace_impresion text,
  add column if not exists config_impresion text;

comment on column public.disenos_qr.enlace_impresion is
  'URL opcional para mandar este diseño a imprimir. Si está vacía, el '
  'generador no muestra el botón de imprimir para este diseño.';

comment on column public.disenos_qr.config_impresion is
  'Configuración que el usuario debe elegir en la imprenta, una línea '
  'por dato ("Tipo de plegado: Doble en U"). Se muestra junto al botón '
  'de imprimir. Opcional e independiente del enlace.';

-- Guarda de integridad: si hay enlace, tiene que ser http(s) y no una
-- cadena en blanco. Así un pegado accidental no llega al generador.
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'disenos_qr_enlace_impresion_valido'
  ) then
    alter table public.disenos_qr
      add constraint disenos_qr_enlace_impresion_valido
      check (enlace_impresion is null or enlace_impresion ~* '^https?://.+');
  end if;
end $$;

-- Los permisos ya los tiene la tabla (ver grants_galeria_qr.sql): 'anon'
-- lee y 'authenticated' escribe. Una columna nueva los hereda, así que
-- aquí no hace falta ningún grant.

-- Comprobación:
--   select nombre, enlace_impresion from public.disenos_qr order by orden;
-- =====================================================================
