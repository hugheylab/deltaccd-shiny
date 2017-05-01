library('shiny')
library('foreach')
source('helpers.R')

# reference correlations
	# correlation matrix, order of gene symbols based on first column

# test data
	# first row has gene symbols and one column named condition and one named sample
	# then one row per sample, with expression values and the corresponding condition and sample name

function(input, output) {
	refSquare = reactive({
		if (input$refOption=='human') {
			refFilePath = 'reference_human.csv'
		} else if (input$refOption=='mouse') {
			refFilePath = 'reference_mouse.csv'
		} else if (input$refOption=='custom' && !is.null(input$refFile)) {
			refFilePath = input$refFile$datapath
		} else {
			return(NULL)}
		refTmp = read_csv(refFilePath)
		colnames(refTmp)[1] = 'symbol1'
		return(refTmp)
	})

	output$refDownloadInput = renderUI({
		if (is.null(refSquare())) {
			return(NULL)}
		downloadButton('refDownload', 'Download reference correlations')
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

	refHeatmap = reactive({
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

	output$refHeatmap = renderPlot({
		refHeatmap()
	})

	testFilePath = reactive({
		if (input$testOption=='example') {
			'GSE19188.csv'
		} else if (!is.null(input$testFile)) {
			input$testFile$datapath
		} else {
			NULL}
	})

	testFileName = reactive({
		if (input$testOption=='example') {
			'GSE19188.csv'
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

	testCorr = reactive({
		if (is.null(tst()) || is.null(ref())) {
			return(NULL)}
		tst() %>%
			group_by(condition) %>%
			do(calcCorr(., symbolLevels()))
	})

	output$testCorrDownloadInput = renderUI({
		if (is.null(testCorr())) {
			return(NULL)}
		downloadButton('testCorrDownload', 'Download correlations for test data')
	})

	output$testCorrDownload = downloadHandler(
		function() sprintf('%s_corr.csv', tools::file_path_sans_ext(testFileName())),
		function(file) write_csv(testCorr(), file)
	)

	testHeatmap = reactive({
		if (is.null(testCorr())) {
			return(NULL)}
		testCorr1 = makeSymbolFac(testCorr(), symbolLevels(), reve=TRUE)
		makeHeatmap(ggplot(testCorr1) + facet_wrap(~condition, ncol=2), gc=getLowHigh(testCorr1$rho),
						text=element_text(size=13), axis.text.x=element_text(angle=90, vjust=0.5, hjust=1)) +
			ggtitle(tools::file_path_sans_ext(testFileName()))
	})

	output$testHeatmapUi = renderUI({
		if (is.null(testCorr())) {
			return(NULL)}
		plotOutput('testHeatmap', width=input$testPlotWidth, height=input$testPlotHeight)
	})

	output$testHeatmap = renderPlot({
		testHeatmap()
	})

	output$testConditionInput = renderUI({
		if (is.null(tst())) {
			return(NULL)}
		radioButtons('testConditionInput', 'Condition corresponding to normal:',
						 sort(unique(tst()$condition)))
	})

	output$testSigInput = renderUI({
		if (is.null(testCorr())) {
			return(NULL)}
		checkboxInput('testSigInput', 'Calculate one-sided significance (1000 permutations)')
	})

	testResult = reactive({
		if (is.null(input$testConditionInput)) {
			return(NULL)}
		calcRefDist(testCorr(), ref(), symbolLevels(), input$testConditionInput)
	})

	testResultSig = reactive({
		if (is.null(testCorr())) {
			return(NULL)
		} else if (is.null(input$testConditionInput) || !input$testSigInput) {
			return(testResult())}

		testNormal = filter(tst(), condition==input$testConditionInput)
		conditions = setdiff(tst()$condition, input$testConditionInput)
		nIter = 1000

		testPerm = foreach(conditionNow=conditions, .combine=bind_rows) %do% {
			testNow = tst() %>%
				filter(condition==conditionNow) %>%
				bind_rows(testNormal) %>%
				makePerms(nIter) %>%
				group_by(condition, add=TRUE) %>%
				do(calcCorr(., symbolLevels())) %>%
				calcRefDist(ref(), symbolLevels(), input$testConditionInput) %>%
				filter(condition!=input$testConditionInput)}

		calcPermPval(testResult(), testPerm)
	})

	output$testResultTable = renderTable({
		testResultSig()
	})

	output$testResultDownloadInput = renderUI({
		if (is.null(testResultSig())) {
			return(NULL)}
		downloadButton('testResultDownload', 'Download results for test data')
	})

	output$testResultDownload = downloadHandler(
		function() sprintf('%s_result.csv', tools::file_path_sans_ext(testFileName())),
		function(file) write_csv(testResultSig(), file)
	)
}
