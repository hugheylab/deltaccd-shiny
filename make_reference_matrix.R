library('tidyverse')

cg = read_csv('genes_clock.csv')

refSpread = read_csv('result_mouse_ref.csv') %>%
	transmute(symbol1 = factor(symbol1, cg$symbol_mm),
				 symbol2 = factor(symbol2, cg$symbol_mm),
				 rho = rhoMeta) %>%
	spread(key=symbol2, value=rho)
write_csv(refSpread, 'reference_mouse.csv')

refSpread = read_csv('result_mouse_ref.csv') %>%
	transmute(symbol1 = factor(toupper(symbol1), cg$symbol_hs),
				 symbol2 = factor(toupper(symbol2), cg$symbol_hs),
				 rho = rhoMeta) %>%
	spread(key=symbol2, value=rho)
write_csv(refSpread, 'reference_human.csv')
