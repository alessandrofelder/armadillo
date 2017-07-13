# @CommandService cs

import csv
from math import floor
import os
from ij import IJ

# directory needs to have: 
# 	../angles
# 	../edge-coordinates
# 	../perc-output
# parallel directories
# pre-existing files in those directories will be overwritten if they match the chosen names
def writeITAsForAllTiffsInDirectory(directory,percentageThickness):
	#precalculate thickness stuff
	thicknessFile = open("../binary/thickness/all-thickness-measurements.csv",'rb')
	thicknessReader = csv.reader(thicknessFile, delimiter=',')
	thicknessReader.next()
	thicknessNames = []
	thicknessMeasurements = []
	for thicknessTuple in thicknessReader:
		print(thicknessTuple[1],floor(float(thicknessTuple[2])))
		thicknessNames.append(thicknessTuple[1])
		thicknessMeasurements.append(floor(float(thicknessTuple[2])))
	
	#other setting up
	percentThicknessUsedAsCutoff = str(int(percentageThickness*100))
	edgeCoordsFilePrefix = '../edge-coordinates/edge-coordinates-percThick-'+percentThicknessUsedAsCutoff
	anglesFilePrefix = '../angles/angles-percThick-'+percentThicknessUsedAsCutoff
	percentageFileName = '../perc-output/percentages-percThick'+percentThicknessUsedAsCutoff+'.csv'
	open(percentageFileName, 'w').close() #delete contents from previous run

	counter=0
	for fileName in os.listdir(directory):
	    if fileName.endswith(".tif"):
	    	#get trabecular thickness
	    	print(fileName)
	    	thicknessName = fileName.replace("purified_skeleton.tif","purified.tif")
	    	print(thicknessName)
	    	currentThickness = thicknessMeasurements[[i for i, t in enumerate(thicknessNames) if t==thicknessName][0]]
	    	print(currentThickness)
	    	counter=counter+1
			
			#execute ITA	    
	        currentImageName = os.path.join(directory, fileName)
	        currentImage = IJ.openImage(currentImageName)
	        IJ.run(currentImage, "Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	        print(currentImage)
	        print(percentageThickness)
	        print(currentThickness)
	        print(round(float(percentageThickness*currentThickness)))
	        wrapper = cs.run("org.bonej.wrapperPlugins.IntertrabecularAngleWrapper", True, ["inputImage",currentImage, "minimumValence", 3, "maximumValence", 50, "minimumTrabecularLength", round(float(percentageThickness*currentThickness)),"marginCutOff",round(float(percentageThickness*currentThickness)),"iteratePruning", False, "useClusters", True, "printCentroids", True,"printCulledEdgePercentages", True])
	        currentImage.close()
	        wrapperInstance = wrapper.get()
	        
	        #save angles
	        currentAnglesList = wrapperInstance.getOutput("anglesTable")
	        anglesFile = open(anglesFilePrefix+'-'+os.path.splitext(fileName)[0]+'.csv',"w")
	        anglesWriter = csv.writer(anglesFile, delimiter=',')
	        if currentAnglesList: #"is not empty"
	        	for i,angles in enumerate(currentAnglesList):
	        		if(i>0):
	        			print([int(currentAnglesList.getColumnHeader(i))])
	        			anglesWriter.writerow([int(currentAnglesList.getColumnHeader(i))]+angles)
	       		currentAnglesList.setRowCount(0)
	        anglesFile.close()

	        #save edge coordinates
	        currentEdgeList = wrapperInstance.getOutput("centroidTable")
	        edgeFile = open(edgeCoordsFilePrefix+os.path.splitext(fileName)[0]+'.csv',"w")
	        edgeWriter = csv.writer(edgeFile, delimiter=',')
	        for i in range(len(currentEdgeList[0])):
	        	edgeRow = [currentEdgeList[0][i],currentEdgeList[1][i],currentEdgeList[2][i],currentEdgeList[3][i],currentEdgeList[4][i],currentEdgeList[5][i]]
	        	edgeWriter.writerow(edgeRow)
	        edgeFile.close()
				
	        #save percentages
	        currentPercentageList =	wrapperInstance.getOutput("culledEdgePercentagesTable")
	        percentageFile  = open(percentageFileName, "a")
	        percentageWriter = csv.writer(percentageFile, delimiter=',')
	        percentageRow = [item for sublist in currentPercentageList for item in sublist]
	        percentageRow.insert(0, fileName)
	        percentageWriter.writerow(percentageRow)
	        percentageFile.close()
	        continue
	    else:
	        continue

workingDirectory = "/home/alessandro/Documents/data/ITA/cat-test/skeleton/"
os.chdir(workingDirectory)

for i in range(1,9):
	writeITAsForAllTiffsInDirectory(workingDirectory,float(i)/10.0)
