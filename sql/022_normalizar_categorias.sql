-- 022: Normalización de categorías (slugs sin acentos) para TODOS los tenants
-- Ejecutar en Supabase (SQL editor) como snippet nuevo. No agrega columnas ni toca otros datos.

-- Normaliza categorías de servicios a los slugs oficiales
UPDATE services
SET categoria = CASE
  WHEN translate(lower(categoria), 'áéíóúüñ', 'aeiouun') = 'unas' THEN 'unas'
  WHEN translate(lower(categoria), 'áéíóúüñ', 'aeiouun') = 'pestanas' THEN 'pestanas'
  WHEN translate(lower(categoria), 'áéíóúüñ', 'aeiouun') = 'cejas' THEN 'cejas'
  WHEN translate(lower(categoria), 'áéíóúüñ', 'aeiouun') = 'depilacion' THEN 'depilacion'
  WHEN translate(lower(categoria), 'áéíóúüñ', 'aeiouun') = 'maquillaje' THEN 'maquillaje'
  WHEN translate(lower(categoria), 'áéíóúüñ', 'aeiouun') = 'masajes' THEN 'masajes'
  WHEN translate(lower(categoria), 'áéíóúüñ', 'aeiouun') = 'facial' THEN 'facial'
  WHEN translate(lower(categoria), 'áéíóúüñ', 'aeiouun') = 'cabello' THEN 'cabello'
  WHEN translate(lower(categoria), 'áéíóúüñ', 'aeiouun') = 'corporal' THEN 'corporal'
  ELSE categoria
END;

-- Normaliza categorías de bloqueos (deja NULL si está vacío)
UPDATE blocks
SET categoria = CASE
  WHEN translate(lower(categoria), 'áéíóúüñ', 'aeiouun') = 'unas' THEN 'unas'
  WHEN translate(lower(categoria), 'áéíóúüñ', 'aeiouun') = 'pestanas' THEN 'pestanas'
  WHEN translate(lower(categoria), 'áéíóúüñ', 'aeiouun') = 'cejas' THEN 'cejas'
  WHEN translate(lower(categoria), 'áéíóúüñ', 'aeiouun') = 'depilacion' THEN 'depilacion'
  WHEN translate(lower(categoria), 'áéíóúüñ', 'aeiouun') = 'maquillaje' THEN 'maquillaje'
  WHEN translate(lower(categoria), 'áéíóúüñ', 'aeiouun') = 'masajes' THEN 'masajes'
  WHEN translate(lower(categoria), 'áéíóúüñ', 'aeiouun') = 'facial' THEN 'facial'
  WHEN translate(lower(categoria), 'áéíóúüñ', 'aeiouun') = 'cabello' THEN 'cabello'
  WHEN translate(lower(categoria), 'áéíóúüñ', 'aeiouun') = 'corporal' THEN 'corporal'
  WHEN categoria IS NULL OR btrim(categoria) = '' THEN NULL
  ELSE categoria
END;
