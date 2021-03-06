library('shiny')
library('markdown')

fluidPage(
	titlePanel('Quantifying circadian clock function using clock gene co-expression'),
	fluidRow(
		column(3,
				 wellPanel(
				 	h4('Reference correlations'),
				 	radioButtons('refOption', NULL,
				 					 c('Default for human'='human',
				 					   'Default for mouse'='mouse',
				 					   'Supply my own'='custom')),
				 	conditionalPanel(
				 		condition = "input.refOption == 'custom'",
				 		fileInput('refFile', 'CSV file:',
				 					 accept=c('text/csv', 'text/comma-separated-values,text/plain', '.csv'))
				 	),
				 	uiOutput('refPlotSliders')
				 ),
				 wellPanel(
				 	p('For details of the method and our results, please check out the ',
				 	  a('paper.', href='https://doi.org/10.7717/peerj.4327')),
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
				 		condition = "input.testOption == 'custom'",
				 		fileInput('testFile', 'CSV file:',
				 					 accept=c('text/csv', 'text/comma-separated-values,text/plain', '.csv'))
				 	),
				 	span(textOutput('testFailText'), style='color:blue'),
				 	uiOutput('testConditionUi'),
				 	uiOutput('testSigUi'),
				 	uiOutput('testPlotSliders'),
				 	uiOutput('allResultsDownloadUi')
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
