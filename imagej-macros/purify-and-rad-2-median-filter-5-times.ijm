run("Close All")
dir = "/media/alessandro/A6E8FE87E8FE5551/Users/afelder/Desktop/ITA-samples/binary/"
outputdir = "/media/alessandro/A6E8FE87E8FE5551/Users/afelder/Desktop/ITA-samples/"

iterations = 5;
radius = 2;

files = getFileList(dir);

for(i=0; i<files.length; i++) {
	if(!endsWith(files[i], ".tif")) {
		continue;
	}
	open(dir+files[i]);
	run("Purify", "labelling=Mapped chunk=4");
	for (j=0; j<iterations; j=j+1) 
	{
		run("Median 3D...", "x="+radius+" y="+radius+" z="+radius);
	}
	run("Make Binary", "method=IJ_IsoData background=Dark calculate black");
	saveAs("Tiff", outputdir+files[i]+"-purified-"+iterations+"-iterations"+"_median_"+radius+".tif");
	selectWindow(files[i]+"-purified-"+iterations+"-iterations"+"_median_"+radius+".tif");
	run("Skeletonise", "inputimage="+files[i]+"-purified-"+iterations+"-iterations"+"_median_"+radius+".tif statusservice=[org.scijava.app.DefaultStatusService [priority = 0.0]]");
	selectWindow("Skeleton of "+files[i]+"-purified-"+iterations+"-iterations"+"_median_"+radius+".tif");
	saveAs("Tiff", outputdir+files[i]+"-purified-"+iterations+"-iterations"+"_median_"+radius+"_skeleton.tif");
	run("Connectivity", "inputimage="+files[i]+"-purified-"+iterations+"-iterations"+"_median_"+radius+".tif opservice=[net.imagej.ops.DefaultOpService [priority = 0.0]] uiservice=[org.scijava.ui.DefaultUIService [priority = 0.0]] statusservice=[org.scijava.app.DefaultStatusService [priority = 0.0]]");
	run("Close All");
}	

