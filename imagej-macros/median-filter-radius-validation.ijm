run("Close All")
dir = "/home/alessandro/Documents/data/median-filter-test/"
originalName = "tubes-32-pixels-long-with-diameter-1-3-5-13-26-and-52-pixels"
for (i=35; i<52; i=i+1) 
{
	open(dir+originalName+".tif");
	run("Median 3D...", "x="+i+" y="+i+" z="+i);
	run("Make Binary", "method=IJ_IsoData background=Dark calculate black");
	run("Purify", "labelling=Mapped chunk=4 make_copy");
	saveAs("Tiff", dir+originalName+"_median_"+i+"_purified.tif");
	selectWindow(originalName+"_median_"+i+"_purified.tif");
	run("Connectivity", "inputimage="+originalName+"_median_"+i+"_purified.tif opservice=[net.imagej.ops.DefaultOpService [priority = 0.0]] uiservice=[org.scijava.ui.DefaultUIService [priority = 0.0]] statusservice=[org.scijava.app.DefaultStatusService [priority = 0.0]]");
	run("Close All");
}


