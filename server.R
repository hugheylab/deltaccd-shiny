library('shiny')
library('foreach')
source('helpers.R')

refFilePathHuman = 'reference_human.csv'
refFilePathMouse = 'reference_mouse.csv'
testFileNameExample = 'GSE32863.csv'

# reference correlations
	# correlation matrix, order of gene symbols based on first column

# test data
	# first row has gene symbols and one column named condition and one named sample
	# then one row per sample, with expression values and the corresponding condition and sample name

function(input, output) {
	refSquare = reactive({
		if (input$refOption=='human') {
			refFilePath = refFilePathHuman
		} else if (input$refOption=='mouse') {
			refFilePath = refFilePathMouse
		} else if (input$refOption=='custom' && !is.null(input$refFile)) {
			refFilePath = input$refFile$datapath
		} else {
			return(NULL)}
		refTmp = read_csv(refFilePath)
		colnames(refTmp)[1] = 'symbol1'
		return(refTmp)
	})

	output$refDownload = downloadHandler('reference_corr.csv', function(file) write_csv(refSquare(), file))

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

	output$refHeatmap = renderPlot({
		if (is.null(ref())) {
			return(NULL)}
		ref1 = makeSymbolFac(ref(), symbolLevels(), reve=TRUE)
		makeHeatmap(ggplot(ref1), gc=getLowHigh(ref1$rho), text=element_text(size=13),
						axis.text.x=element_text(angle=90, vjust=0.5, hjust=1)) +
			ggtitle('Reference')
	})

	output$refHeatmapUi = renderUI({
		plotOutput('refHeatmap', width=input$refPlotWidth, height=input$refPlotHeight)
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
		read_csv(testFilePath())
	})

	testFail = reactive({
		length(setdiff(symbolLevels(), setdiff(colnames(tst()), c('sample', 'condition'))))>0
	})

	output$testFailText = renderText({
		if (is.null(tst()) || !testFail()) {
			return(NULL)}
		missingSymbols = setdiff(symbolLevels(), setdiff(colnames(tst()), c('sample', 'condition')))
		errStr = c('Cannot proceed with analysis, because the following genes are in the reference panel,',
					  'but not in the test data: %s. Please revise the reference correlations or the test data.')
		sprintf(paste(errStr, collapse=' '), paste(missingSymbols, collapse=', '))
	})

	output$testDownload = downloadHandler(testFileName(), function(file) write_csv(tst(), file))

	testCorr = reactive({
		if (is.null(ref()) || is.null(tst()) || testFail()) {
			return(NULL)}
		tst() %>%
			group_by(condition) %>%
			do(calcCorr(., symbolLevels()))
	})

	output$testCorrDownload = downloadHandler(
		function() sprintf('%s_corr.csv', tools::file_path_sans_ext(testFileName())),
		function(file) write_csv(testCorr(), file)
	)

	output$testCorrDownloadUi = renderUI({
		if (is.null(testCorr())) {
			return(NULL)}
		list(downloadButton('testCorrDownload', 'Download test data correlations'), p())
	})

	output$testHeatmap = renderPlot({
		if (is.null(testCorr())) {
			return(NULL)}
		testCorr1 = makeSymbolFac(testCorr(), symbolLevels(), reve=TRUE)
		makeHeatmap(ggplot(testCorr1) + facet_wrap(~condition, ncol=3), gc=getLowHigh(testCorr1$rho),
						text=element_text(size=13), axis.text.x=element_text(angle=90, vjust=0.5, hjust=1)) +
			ggtitle(tools::file_path_sans_ext(testFileName()))
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
		checkboxInput('testSig', 'Calculate p-value (takes several seconds)')
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
		nIter = 1000

		testPerm = foreach(conditionNow=conditions, .combine=bind_rows) %do% {
			testNow = tst() %>%
				filter(condition==conditionNow) %>%
				bind_rows(testNormal) %>%
				makePerms(nIter) %>%
				group_by(condition, add=TRUE) %>%
				do(calcCorr(., symbolLevels())) %>%
				calcRefDist(ref(), symbolLevels(), input$testCondition) %>%
				filter(condition!=input$testCondition)}

		calcPermPval(testResult(), testPerm)
	})

	output$testResultTable = renderTable({
		if (is.null(testResultSig())) {
			return(NULL)}
		testResultSig()
	})

	output$testResultDownload = downloadHandler(
		function() sprintf('%s_result.csv', tools::file_path_sans_ext(testFileName())),
		function(file) write_csv(testResultSig(), file)
	)

	output$testResultDownloadUi = renderUI({
		if (is.null(testResultSig())) {
			return(NULL)}
		list(downloadButton('testResultDownload', 'Download results table'), p())
	})
}
