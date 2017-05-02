This app can be used to infer the function of the circadian clock based on the co-expression of clock genes. It can be applied to datasets in which the samples are not labeled with time of day and were not acquired throughout the 24-h cycle.

The default reference correlations (for both mouse and human) are based on circadian gene expression from multiple mouse organs. To see how to format your own reference correlations, please download the default correlations for either mouse or human.

To see how to format your test data, please download the example data. The gene expression values can be from microarray or RNA-seq, and can be log-transformed or not. The test data must contain every gene used in the reference correlations, and must include samples from at least two conditions.

In the heatmaps, "rho" refers to the Spearman correlation between pairs of genes. The colors in the heatmaps for reference and test data are directly comparable. The genes are ordered based on the order in the reference correlations file.

In the results table, CCD corresponds to the Euclidean distance between the correlations for each test condition ...
deltaCCD corresponds to ...
p-value will be NA for ...
