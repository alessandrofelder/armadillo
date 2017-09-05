run("Close All")
dir = "/media/alessandro/A6E8FE87E8FE5551/Users/afelder/Desktop/ITA-alpaca/binary/"
originalName = "RVC_alpaca_1_head_IJ_Isodata_purified"

max = 10;
radius = 2;

open(dir+originalName+".tif");
for (i=0; i<max; i=i+1) 
{
	run("Median 3D...", "x="+radius+" y="+radius+" z="+radius);
	run("Make Binary", "method=IJ_IsoData background=Dark calculate black");
	saveAs("Tiff", dir+originalName+"-"+i+"-iterations"+"_median_"+radius+".tif");
	selectWindow(originalName+"-"+i+"-iterations"+"_median_"+radius+".tif");
	run("Skeletonise", "inputimage="+originalName+"-"+i+"-iterations"+"_median_"+radius+".tif statusservice=[org.scijava.app.DefaultStatusService [priority = 0.0]]");
	selectWindow("Skeleton of "+originalName+"-"+i+"-iterations"+"_median_"+radius+".tif");
	saveAs("Tiff", dir+originalName+"-"+i+"-iterations"+"_median_"+radius+"_skeleton.tif");
	run("Connectivity", "inputimage="+originalName+"-"+i+"-iterations"+"_median_"+radius+".tif opservice=[net.imagej.ops.DefaultOpService [priority = 0.0]] uiservice=[org.scijava.ui.DefaultUIService [priority = 0.0]] statusservice=[org.scijava.app.DefaultStatusService [priority = 0.0]]");
	run("Close");
	selectWindow(originalName+"-"+i+"-iterations"+"_median_"+radius+".tif");
}


