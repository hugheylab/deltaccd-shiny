library('shiny')

fluidPage(
	titlePanel('Circadian Clock Correlation Distance'),
	fluidRow(
		column(3,
				 wellPanel(
				 	h4('Reference correlations'),
				 	radioButtons('refOption', NULL,
				 					 c('Default for human'='human',
				 					   'Default for mouse'='mouse',
				 					   'Supply my own'='custom')),
				 	conditionalPanel(
				 		condition = "input.refOption != 'custom'",
				 		downloadButton('refDownload', 'Download reference correlations'),
				 		p()
				 	),
				 	conditionalPanel(
				 		condition = "input.refOption == 'custom'",
				 		fileInput('refFile', 'CSV file:',
				 					 accept=c('text/csv', 'text/comma-separated-values,text/plain', '.csv'))
				 	),

				 	sliderInput('refPlotWidth', 'Plot width (px)', min=200, max=400, value=280, step=20),
				 	sliderInput('refPlotHeight', 'Plot height (px)', min=200, max=400, value=240, step=20)

				 ),
				 wellPanel(
				 	p('For details of the method and our results, please check out the ',
				 	  a('preprint.', href='https://doi.org/10.1101/130765')),
				 	p('If you have questions or issues, please email me at jakejhughey#gmail.com.')
				 )
		),
		column(3,
				 wellPanel(
				 	h4('Test data'),
				 	radioButtons('testOption', NULL,
				 					 c('Example data (GSE32863)'='example',
				 					   'Supply my own'='custom')),
				 	conditionalPanel(
				 		condition = "input.testOption != 'custom'",
				 		downloadButton('testDownload', 'Download example test data'),
				 		p()
				 	),
				 	conditionalPanel(
				 		condition = "input.testOption == 'custom'",
				 		fileInput('testFile', 'CSV file:',
				 					 accept=c('text/csv', 'text/comma-separated-values,text/plain', '.csv'))
				 	),
				 	span(textOutput('testFailText'), style='color:blue'),
				 	uiOutput('testCorrDownloadUi'),
				 	uiOutput('testConditionUi'),
				 	uiOutput('testSigUi'),
				 	uiOutput('testResultDownloadUi'),
				 	sliderInput('testPlotWidth', 'Plot width (px)', min=400, max=600, value=440, step=20),
				 	sliderInput('testPlotHeight', 'Plot height (px)', min=200, max=600, value=260, step=20)
				 )
		),
		column(6,
				 tabsetPanel(
				 	tabPanel(
				 		'Results',
				 		tableOutput('testResultTable'),
				 		uiOutput('refHeatmapUi'),
				 		uiOutput('testHeatmapUi')
				 	),
				 	tabPanel(
				 		'Readme',
				 		includeMarkdown('readme.md')
				 	)
				 )
		)
	)
)
