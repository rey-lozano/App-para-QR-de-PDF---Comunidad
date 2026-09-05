-- =====================================================================
--  Integrador QR — permisos que faltaban tras la primera migración
--  Proyecto Supabase: embudos-emprenya (ebkbpinafabnyfllswgb)
--
--  Ejecútalo en el SQL Editor. Son dos GRANT, no borra ni cambia nada.
--
--  Por qué hace falta: RLS decide QUÉ filas ve cada rol, pero el rol
--  necesita además el permiso base sobre la tabla. Las tablas nuevas
--  nacieron sin él, así que 'anon' recibía "permission denied" y el
--  generador no habría visto la galería.
--  Es el mismo reparto que ya tienen settings y commission_rates.
-- =====================================================================

grant select
  on public.disenos_qr_categorias, public.disenos_qr
  to anon;

grant select, insert, update, delete
  on public.disenos_qr_categorias, public.disenos_qr
  to authenticated;

-- Comprobación (debe devolver 13 filas):
-- select nombre from public.disenos_qr order by orden;
