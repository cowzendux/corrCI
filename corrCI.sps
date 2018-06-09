* Encoding: UTF-8.
* Calculate a correlation matrix including a CI
* By Jamie DeCoster

* This program allows users to calculate a correlation matrix
* that includes a confidence interval.

**** Usage: corrCI(varList1, varList2, confidence = .95, datasetLabels = [])
**** "varList1" and "varList2" are lists of strings indicating the variables 
* for the correlation matrix. varList1 is required, but varList2 is optional. 
* If you only provide varList1, then the function will calculate the 
* intercorrelations among all of the variables in this list. If you provide 
* both varList1 and varList2, the function will correlate the variables in 
* varList1 with the variables in varList2, but will not calculate the correlations 
* within the two lists.
**** "confidence" is the proportion of the area that is to be covered by
* the confidence interval. By default, this is .95.
**** "datasetLabels" is a list of strings providing labels for a particular analysis.
* This allows analyses to performed on multiple subgroups or data
* sets and still appended to the same output data set.

* Example 1: 
**** corrIC (varList1 = ["age", "iq", "pretest"], 
varList2 = ["posttest"],
confidence = .80,
datasetLabels = ["Males"])
* This would provide the correlations of age, iq, and the pretest score 
* with the posttest score. It would not provide the correlations among age, iq,
* and the pretest score. Note that even though we only have one variable
* in varList2, we still have to represent it as a list by including it in brackets.
* The analysis would create 80% confidence intervals. There would be
* a single label in the output dataset that would take on the value of "Males".

* Example 2
**** corrCI(["CO", "ES", "ES])
* This would provide the correlations and CIs among the three 
* variables CO, ES, and IS. Since the confidence level was not 
* specified, the program will create 95% CIs. The output dataset
* would not contain any labels.

************
* Version History
************
* 2018-02-10 Created
* 2018-02-11 Added SPSS syntax work

set printback = off.
begin program python.
import spss, spssaux, math

def corrCI(varList1, varList2 = None, confidence = .95, datasetLabels = []):
    if (varList2 == None):
        varList2 = varList1

# Using the regression procedure to get the individual correlations
# Storing the results in lists

    v1List = []
    v2List = []
    rList = []
    nList = []
    pList = []
    ZrList = []
    seZList = []
    for var1 in varList1:
        for var2 in varList2:
            cmd = """REGRESSION
  /MISSING LISTWISE
  /STATISTICS R ANOVA
  /CRITERIA=PIN(.05) POUT(.10)
  /NOORIGIN 
  /DEPENDENT %s
  /METHOD=ENTER %s.""" %(var1, var2)
            handle,failcode=spssaux.CreateXMLOutput(
		cmd,
		omsid="Regression",
		visible=False)
            modelsummary=spssaux.GetValuesFromXMLWorkspace(
		handle,
		tableSubtype="Model Summary",
		cellAttrib="text")
            anovatable=spssaux.GetValuesFromXMLWorkspace(
		handle,
		tableSubtype="ANOVA",
		cellAttrib="text")
            if (len(modelsummary) > 0):
                r = float(modelsummary[0])
                p = float(anovatable[4])
                n = float(anovatable[6])
                Zr = .5*math.log((1 + r)/(1 - r))
                seZ = 1/math.sqrt(n-3)
            else:
                r = None
                p = None
                n = None
                Zr = None
                seZ = None
            v1List.append(var1)
            v2List.append(var2)
            rList.append(r)
            pList.append(p)
            nList.append(n)
            ZrList.append(Zr)
            seZList.append(seZ)

# Create list for export
    dt = []
    for (a, b, c, d, e, f, g) in zip(v1List, 
v2List, rList, pList, nList, ZrList, seZList):
        line = [a, b, c, d, e, f, g]
        line.extend([None,None,None,None,None])
        line.extend(datasetLabels)
        dt.append(line)
        
# Add to correlations data set
# Determine active data set so we can return to it when finished
    activeName = spss.ActiveDataset()
# Set up data set if it doesn't already exist
    tag,err = spssaux.createXmlOutput('Dataset Display',
omsid='Dataset Display', subtype='Datasets')
    datasetList = spssaux.getValuesFromXmlWorkspace(tag, 'Datasets')

    if ("Correlations" not in datasetList):
        spss.StartDataStep()
        datasetObj = spss.Dataset(name=None)
        dsetname = datasetObj.name
        datasetObj.varlist.append("Var1", 25)
        datasetObj.varlist.append("Var2", 25)
        datasetObj.varlist.append("r", 0)
        datasetObj.varlist.append("p", 0)
        datasetObj.varlist.append("n", 0)
        datasetObj.varlist.append("Zr", 0)
        datasetObj.varlist.append("seZ", 0)
        datasetObj.varlist.append("Zcrit", 0)
        datasetObj.varlist.append("lowerZr", 0)
        datasetObj.varlist.append("upperZr", 0)
        datasetObj.varlist.append("lower_r", 0)
        datasetObj.varlist.append("upper_r", 0)

# Label variables
        datasetVariableList =[]
        for t in range(spss.GetVariableCount()):
            datasetVariableList.append(spss.GetVariableName(t))
        for t in range(len(datasetLabels)):
            if ("label{0}".format(str(t)) not in datasetVariableList):
                datasetObj.varlist.append("label{0}".format(str(t)), 50)

        spss.EndDataStep()
        submitstring = """dataset activate {0}.
dataset name Correlations.""".format(dsetname)
        spss.Submit(submitstring)

    spss.StartDataStep()     
    datasetObj = spss.Dataset(name = "Correlations")
    for line in dt:
       datasetObj.cases.append(line)
    spss.EndDataStep()


# Calculate lower and upper bounds using SPSS functions
    submitstring = """dataset activate Correlations.
compute Zcrit = abs(idf.normal(((1-{0})/2), 0, 1)).
compute lowerZr = Zr - Zcrit*seZ.
compute upperZr = Zr + Zcrit*seZ.
compute lower_r = (exp(2*lowerZr)-1)/(exp(2*lowerZr)+1).
compute upper_r = (exp(2*upperZr)-1)/(exp(2*upperZr)+1).
execute.
alter type n (f8).
alter type p (f8.3).""".format(confidence)
    spss.Submit(submitstring)    

# Return to original data set
    spss.StartDataStep()
    datasetObj = spss.Dataset(name = activeName)
    spss.SetActive(datasetObj)
    spss.EndDataStep()
end program python.

set printback = on.

