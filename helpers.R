library('tidyverse')

theme_set(theme_light() +
			 	theme(axis.text=element_text(color='black'), strip.text=element_text(color='black'),
			 			panel.grid.minor=element_blank(), legend.margin=margin(t=0, r=0, b=0, l=0, unit='cm')))


calcCorr = function(df, features, method='spearman') {
	data.frame(cor(as.matrix(df[,features]), method=method),
				  symbol1 = features, stringsAsFactors=FALSE) %>%
		gather(-symbol1, key=symbol2, value=rho) %>%
		filter(symbol1!=symbol2)}


makeSymbolFac = function(df, levs, reve=FALSE) {
	df = mutate(df, symbol1Fac = factor(symbol1, levels=levs))
	if (reve) {
		mutate(df, symbol2Fac = factor(symbol2, levels=rev(levs)))
	} else {
		mutate(df, symbol2Fac = factor(symbol2, levels=levs))}}


calcDist = function(r1, r2) sqrt(sum((r1-r2)^2, na.rm=TRUE))


getLowHigh = function(vals, vLow=-1, vMid=0, vHigh=1, cLow='#e66101', cMid='#f7f7f7', cHigh='#5e3c99') {
	valRange = seq(0, 1, length.out=101)
	colorScale = scales::div_gradient_pal(low=cLow, mid=cMid, high=cHigh)(valRange)

	minVal = (min(vals) - vLow) / (vHigh - vLow)
	idxLow = which.min(abs(minVal - valRange))

	maxVal = (max(vals) - vLow) / (vHigh - vLow)
	idxHigh = which.min(abs(maxVal - valRange))
	return(colorScale[c(idxLow, idxHigh)])}


makeHeatmap = function(ggObj, gc, x='symbol1Fac', y='symbol2Fac', fill='rho', guideBool=TRUE, ...) {
	scaleArgs = list(low=gc[1], mid='#f7f7f7', high=gc[2], breaks=seq(-1, 1, 0.5), name='rho')
	if (guideBool) {
		sfg = do.call(scale_fill_gradient2, scaleArgs)
	} else {
		sfg = do.call(scale_fill_gradient2, c(scaleArgs, guide=FALSE))}
	ggObj + geom_tile(aes_string(x=x, y=y, fill=fill)) + sfg + labs(x='Gene', y='Gene') + theme(...)}


calcRefDist = function(df, ref, symbolLevels, conditionNormal) {
	df %>%
		inner_join(rename(ref, rhoRef=rho), by=c('symbol1', 'symbol2')) %>%
		makeSymbolFac(symbolLevels) %>%
		filter(as.numeric(symbol1Fac) < as.numeric(symbol2Fac)) %>%
		summarize(CCD = calcDist(rho, rhoRef)) %>%
		mutate(deltaCCD = CCD - CCD[condition==conditionNormal]) %>%
		mutate(deltaCCD = ifelse(condition==conditionNormal, NA, deltaCCD)) %>%
		arrange(condition)}


makePerms = function(df, nIter, seed) {
	if (!is.na(seed)) {
		set.seed(seed)}
	df %>%
		mutate(dummy = 1) %>%
		full_join(tibble(idx = 1:nIter, dummy = 1), by='dummy') %>%
		select(-dummy) %>%
		group_by(idx) %>%
		mutate(condition = sample(condition, length(condition)))}


calcPermPval = function(obs, perm) {
	jn = perm %>%
		inner_join(obs, by='condition') %>%
		group_by(condition) %>%
		summarize(`p-value` = sum(deltaCCD.x >= deltaCCD.y) / n())
	left_join(obs, jn, by='condition')}
