library('shiny')
library('foreach')
source('helpers.R')

refFilePathHuman = 'reference_human.csv'
refFilePathMouse = 'reference_mouse.csv'
testFileNameExample = 'GSE32863.csv'
plotScale = 70

# reference correlations
	# correlation matrix, order of gene symbols based on first column

# test data
	# first row has gene symbols and one column named condition and one named sample
	# then one row per sample, with expression values and the corresponding condition and sample name

function(input, output) {
	refFilePath = reactive({
		if (input$refOption=='human') {
			refFilePathHuman
		} else if (input$refOption=='mouse') {
			refFilePathMouse
		} else if (input$refOption=='custom' && !is.null(input$refFile)) {
			input$refFile$datapath
		} else {
			NULL}
	})

	refFileName = reactive({
		if (input$refOption=='human') {
			refFilePathHuman
		} else if (input$refOption=='mouse') {
			refFilePathMouse
		} else if (input$refOption=='custom' && !is.null(input$refFile)) {
			input$refFile$name
		} else {
			NULL}
	})

	refSquare = reactive({
		if (is.null(refFilePath())) {
			return(NULL)}
		refTmp = read_csv(refFilePath(), col_types=cols())
		colnames(refTmp)[1] = 'symbol1'
		return(refTmp)
	})

	symbolLevels = reactive({
		if (is.null(refSquare())) {
			return(NULL)}
		refSquare()$symbol1
	})

	ref = reactive({
		if (is.null(refSquare())) {
			return(NULL)}
		refSquare() %>%
			gather(-symbol1, key=symbol2, value=rho) %>%
			filter(symbol1!=symbol2)
	})

	refHeatmap = reactive({
		if (is.null(ref())) {
			return(NULL)}
		ref1 = makeSymbolFac(ref(), symbolLevels(), reve=TRUE)
		makeHeatmap(ggplot(ref1), gc=getColorsHeat(ref1$rho), text=element_text(size=13),
						axis.text.x=element_text(angle=90, vjust=0.5, hjust=1)) +
			ggtitle('Reference')
	})

	output$refHeatmap = renderPlot({
		refHeatmap()
	})

	output$refHeatmapUi = renderUI({
		plotOutput('refHeatmap', width=input$refPlotWidth, height=input$refPlotHeight)
	})

	output$refPlotSliders = renderUI({
		if (is.null(ref())) {
			return(NULL)}
		list(sliderInput('refPlotWidth', 'Plot width (px)', min=200, max=400, value=280, step=10),
			  sliderInput('refPlotHeight', 'Plot height (px)', min=200, max=400, value=240, step=10))
	})

	#######################################################################

	testFilePath = reactive({
		if (input$testOption=='example') {
			testFileNameExample
		} else if (!is.null(input$testFile)) {
			input$testFile$datapath
		} else {
			NULL}
	})

	testFileName = reactive({
		if (input$testOption=='example') {
			testFileNameExample
		} else if (!is.null(input$testFile)) {
			input$testFile$name
		} else {
			NULL}
	})

	tst = reactive({
		if (is.null(testFilePath())) {
			return(NULL)}
		read_csv(testFilePath(), col_types=cols())
	})

	testFail = reactive({
		x = rep(NA, 4)
		x[1] = length(setdiff(symbolLevels(), setdiff(colnames(tst()), c('sample', 'condition')))) > 0
		x[2] = !('condition' %in% colnames(tst()))
		if (!x[2]) {
			df = count(tst(), condition)
			x[3] = nrow(df) < 2
			x[4] = any(df$n < 2)
		} else {
			x[3:4] = FALSE}
		x
	})

	output$testFailText = renderText({
		if (is.null(tst()) || all(!testFail())) {
			return(NULL)}
		errVec = 'Cannot proceed with analysis.'
		if (testFail()[1]) {
			missingSymbols = setdiff(symbolLevels(), setdiff(colnames(tst()), c('sample', 'condition')))
			errStr = c('The test data must contain every gene in the reference panel,',
						  'but is currently missing the following gene(s): %s.')
			errVec = c(errVec, sprintf(paste(errStr, collapse=' '), paste(missingSymbols, collapse=', ')))}
		if (testFail()[2]) {
			errVec = c(errVec, "The test data must have a column named 'condition'.")}
		if (testFail()[3]) {
			errVec = c(errVec, 'The test data must include samples from at least two conditions.')}
		if (testFail()[4]) {
			errVec = c(errVec, 'The test data must have at least two samples for each condition.')}
		paste(errVec, collapse=' ')
	})

	testCorr = reactive({
		if (is.null(ref()) || is.null(tst()) || any(testFail())) {
			return(NULL)}
		tst() %>%
			group_by(condition) %>%
			do(calcCorr(., symbolLevels()))
	})

	testHeatmap = reactive({
		if (is.null(testCorr())) {
			return(NULL)}
		testCorr1 = makeSymbolFac(testCorr(), symbolLevels(), reve=TRUE)
		makeHeatmap(ggplot(testCorr1) + facet_wrap(~condition, ncol=3), gc=getColorsHeat(testCorr1$rho),
						text=element_text(size=13), axis.text.x=element_text(angle=90, vjust=0.5, hjust=1)) +
			ggtitle(tools::file_path_sans_ext(testFileName()))
	})

	output$testHeatmap = renderPlot({
		testHeatmap()
	})

	output$testHeatmapUi = renderUI({
		plotOutput('testHeatmap', width=input$testPlotWidth, height=input$testPlotHeight)
	})

	output$testConditionUi = renderUI({
		if (is.null(testCorr())) {
			return(NULL)}
		radioButtons('testCondition', 'Condition corresponding to normal:',
						 sort(unique(tst()$condition)))
	})

	output$testSigUi = renderUI({
		if (is.null(testCorr())) {
			return(NULL)}
		checkboxInput('testSig', 'Calculate p-value (takes a few seconds)')
	})

	output$testPlotSliders = renderUI({
		if (is.null(testCorr())) {
			return(NULL)}
		list(sliderInput('testPlotWidth', 'Plot width (px)', min=400, max=600, value=460, step=10),
			  sliderInput('testPlotHeight', 'Plot height (px)', min=200, max=600, value=260, step=10))
	})

	testResult = reactive({
		if (is.null(input$testCondition)) {
			return(NULL)}
		calcRefDist(testCorr(), ref(), symbolLevels(), input$testCondition)
	})

	testResultSig = reactive({
		if (is.null(testCorr())) {
			return(NULL)
		} else if (is.null(input$testCondition) || !input$testSig) {
			return(testResult())}

		testNormal = filter(tst(), condition==input$testCondition)
		conditions = setdiff(tst()$condition, input$testCondition)

		testPerm = foreach(conditionNow=conditions, .combine=bind_rows) %do% {
			tst() %>%
				filter(condition==conditionNow) %>%
				bind_rows(testNormal) %>%
				makePerms(nIter, seed) %>%
				group_by(condition, add=TRUE) %>%
				do(calcCorr(., symbolLevels())) %>%
				calcRefDist(ref(), symbolLevels(), input$testCondition) %>%
				filter(condition!=input$testCondition)}

		testComb = tst() %>%
			count(condition) %>%
			mutate(nComb = choose(n + n[condition==input$testCondition], n))

		calcPermPval(testResult(), testPerm, testComb)
	})

	output$testResultTable = renderTable({
		if (is.null(testResultSig())) {
			return(NULL)}
		testResultSig()
	}, digits=3)

	#######################################################################

	output$allResultsDownload = downloadHandler(
		'deltaCCD_results.zip',
		function(file) {
			tmpdir = tempdir()
			fs = c()

			if (!is.null(refSquare())) {
				fp = file.path(tmpdir, sprintf('%s_corr.csv', tools::file_path_sans_ext(refFileName())))
				fs = c(fs, fp)
				write_csv(refSquare(), fp)}

			if (!is.null(refHeatmap())) {
				fp = file.path(tmpdir, sprintf('%s_heatmap.pdf', tools::file_path_sans_ext(refFileName())))
				fs = c(fs, fp)
				ggsave(fp, refHeatmap(), width=input$refPlotWidth / plotScale,
						 height=input$refPlotHeight / plotScale)}

			if (!is.null(tst())) {
				fp = file.path(tmpdir, sprintf('%s_data.csv', tools::file_path_sans_ext(testFileName())))
				fs = c(fs, fp)
				write_csv(tst(), fp)}

			if (!is.null(testCorr())) {
				fp = file.path(tmpdir, sprintf('%s_corr.csv', tools::file_path_sans_ext(testFileName())))
				fs = c(fs, fp)
				write_csv(testCorr(), fp)}

			if (!is.null(testHeatmap())) {
				fp = file.path(tmpdir, sprintf('%s_heatmap.pdf', tools::file_path_sans_ext(testFileName())))
				fs = c(fs, fp)
				ggsave(fp, testHeatmap(), width=input$testPlotWidth / plotScale,
						 height=input$testPlotHeight / plotScale)}

			if (!is.null(testResultSig())) {
				fp = file.path(tmpdir, sprintf('%s_result.csv', tools::file_path_sans_ext(testFileName())))
				fs = c(fs, fp)
				write_csv(testResultSig(), fp)}

			zip(zipfile=file, files=fs, flags='-j9X')
		},
		contentType='application/zip'
	)

	output$allResultsDownloadUi = renderUI({
		if (is.null(refSquare()) && is.null(tst())) {
			return(NULL)}
		list(downloadButton('allResultsDownload', 'Download results'))#, p())
	})
}
