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
def writeITAsForAllTiffsInDirectory(directory,percentageThickness,orderIndependent):
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
	
	print(thicknessNames)

	#other setting up
	percentThicknessUsedAsCutoff = str(int(percentageThickness*100))
	edgeCoordsFilePrefix = '../edge-coordinates/edge-coordinates-percThick-'+percentThicknessUsedAsCutoff+'-useClusters-'+str(orderIndependent)
	anglesFilePrefix = '../angles/angles-percThick-'+percentThicknessUsedAsCutoff+'-useClusters-'+str(orderIndependent)
	percentageFileName = '../perc-output/percentages-percThick'+percentThicknessUsedAsCutoff+'-useClusters-'+str(orderIndependent)+'.csv'
	open(percentageFileName, 'w').close() #delete contents from previous run

	counter=0
	for fileName in os.listdir(directory):
	    if fileName.endswith(".tif"):
	    	#get trabecular thickness
	    	print(fileName)
	    	thicknessName = fileName.replace("-skeleton.tif","-binary.tif")
	    	print(thicknessName)
	    	currentThickness = thicknessMeasurements[[i for i, t in enumerate(thicknessNames) if t==thicknessName][0]]
	    	print(currentThickness)
	    	counter=counter+1
			
	        #execute ITA	
	        IJ.run("Clear BoneJ results");    
	        currentImageName = os.path.join(directory, fileName)
	        currentImage = IJ.openImage(currentImageName)
	        IJ.run(currentImage, "Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	        print(currentImage)
	        print(percentageThickness)
	        print(currentThickness)
	        print(round(float(percentageThickness*currentThickness)))
	        wrapper = cs.run("org.bonej.wrapperPlugins.IntertrabecularAngleWrapper", True, ["inputImage",currentImage, "minimumValence", 3, "maximumValence", 50, "minimumTrabecularLength", round(float(percentageThickness*currentThickness)),"marginCutOff",round(float(percentageThickness*currentThickness)),"iteratePruning", True, "useClusters", orderIndependent, "printCentroids", True,"printCulledEdgePercentages", True])
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
	        			if(int(currentAnglesList.getColumnHeader(i))<20):
	        				anglesWriter.writerow([int(currentAnglesList.getColumnHeader(i))]+angles)
		        		else:
		        			anglesWriter.writerow([int(currentAnglesList.getColumnHeader(i))]+angles)
		        			anglesWriter.writerow(['Koosh ball alert: there is a node with valence '+currentAnglesList.getColumnHeader(i)])
		        			currentAnglesList.setRowCount(0)
		        			break
	        	currentAnglesList.setRowCount(0)
	        anglesFile.close()
				
	       		

	        #save edge coordinates
	        currentEdgeList = wrapperInstance.getOutput("centroidTable")
	        edgeFile = open(edgeCoordsFilePrefix+os.path.splitext(fileName)[0]+'.csv',"w")
	        edgeWriter = csv.writer(edgeFile, delimiter=',')
	        if currentEdgeList:
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

workingDirectories = ["/media/alessandro/A6E8FE87E8FE5551/Users/afelder/Desktop/ITA-cow-at-various-resolutions/skeleton/"]
#workingDirectories = ["/home/alessandro/Documents/data/ITA/cat-test/median-increasing-radius/skeleton/"]

for j in range(0,len(workingDirectories)):
	os.chdir(workingDirectories[j])
	for i in [4,5,6,7,10]:
		print(workingDirectories[j])	
		writeITAsForAllTiffsInDirectory(workingDirectories[j],float(i)/10.0,True)

