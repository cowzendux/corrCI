# corrCI
SPSS Python Extension program to generate a correlation matrix including confidence intervals

## Usage: corrCI(varList1, varList2, confidence = .95, datasetLabels = [])
* "varList1" and "varList2" are lists of strings indicating the variables for the correlation matrix. varList1 is required, but varList2 is optional. If you only provide varList1, then the function will calculate the intercorrelations among all of the variables in this list. If you provide both varList1 and varList2, the function will correlate the variables in varList1 with the variables in varList2, but will not calculate the correlations within the two lists.
* "confidence" is the proportion of the area that is to be covered by the confidence interval. By default, this is .95.
* "datasetLabels" is a list of strings providing labels for a particular analysis. This allows analyses to performed on multiple subgroups or data sets and still appended to the same output data set.

## Example 1: 
**corrCI (varList1 = ["age", "iq", "pretest"],  
varList2 = ["posttest"],  
confidence = .80,  
datasetLabels = ["Males"])**
* This would provide the correlations of age, iq, and the pretest score with the posttest score. It would not provide the correlations among age, iq, and the pretest score. 
* Note that even though we only have one variable in varList2, we still have to represent it as a list by including it in brackets.
* The analysis would create 80% confidence intervals. There would be a single label in the output dataset that would take on the value of "Males".

## Example 2
**corrCI(["CO", "ES", "ES])**
* This would provide the correlations and CIs among the three variables CO, ES, and IS. 
* Since the confidence level was not specified, the program will create 95% CIs. 
* The output dataset would not contain any labels.
