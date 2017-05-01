library('shiny')

fluidPage(
	titlePanel('Clock Correlation Distance'),
	fluidRow(
		column(3,
				 wellPanel(
				 	h4('Reference correlations'),
				 	radioButtons('refOption', NULL,
				 					 c('Default for human'='human',
				 					   'Default for mouse'='mouse',
				 					   'Supply my own'='custom')),
				 	fileInput('refFile', 'CSV file:',
				 				 accept=c('text/csv', 'text/comma-separated-values,text/plain', '.csv')),

				 	sliderInput('refPlotWidth', 'Plot width (px)', min=200, max=400, value=300, step=20),
				 	sliderInput('refPlotHeight', 'Plot height (px)', min=200, max=400, value=260, step=20),

				 	uiOutput('refDownloadInput')
				 )
		),
		column(3,
				 wellPanel(
				 	h4('Test data'),
				 	radioButtons('testOption', NULL,
				 					 c('Example data (GSE19188)'='example',
				 					   'Supply my own'='custom')),
				 	fileInput('testFile', 'CSV file:',
				 				 accept=c('text/csv', 'text/comma-separated-values,text/plain', '.csv')),
				 	uiOutput('testConditionInput'),
				 	uiOutput('testSigInput'),

				 	sliderInput('testPlotWidth', 'Plot width (px)', min=400, max=600, value=480, step=20),
				 	sliderInput('testPlotHeight', 'Plot height (px)', min=200, max=600, value=280, step=20),

				 	uiOutput('testCorrDownloadInput'),
				 	uiOutput('testResultDownloadInput')
				 )
		),
		column(6,
				 uiOutput('refHeatmapUi'),
				 uiOutput('testHeatmapUi'),
				 tableOutput('testResultTable')
		)
	)
)
