run("Close All")
dir = "/home/alessandro/Documents/data/ITA/cat-test/"
originalName = "RVC_domestic_cat_head_IJ_isodata_purified"
for (i=12; i<20; i=i+1) 
{
	open(dir+originalName+".tif");
	for(j=0; j<i;j++)
	{
		run("Median 3D...", "x=2 y=2 z=2");
	}
	setOption("BlackBackground", false);
	run("Make Binary", "method=IJ_IsoData background=Dark calculate black");
	run("Purify", "labelling=Mapped chunk=4 make_copy");
	saveAs("Tiff", dir+originalName+"_5x5x5-median_"+i+"_purified.tif");
	selectWindow(originalName+"_5x5x5-median_"+i+"_purified.tif");
	run("Connectivity", "inputimage="+originalName+"_5x5x5-median_"+i+"_purified.tif opservice=[net.imagej.ops.DefaultOpService [priority = 0.0]] uiservice=[org.scijava.ui.DefaultUIService [priority = 0.0]] unitservice=[net.imagej.units.DefaultUnitService [priority = 0.0]] statusservice=[org.scijava.app.DefaultStatusService [priority = 0.0]]");
	run("Skeletonise", "inputimage="+originalName+"_5x5x5-median_"+i+"_purified.tif statusservice=[org.scijava.app.DefaultStatusService [priority = 0.0]]");
	selectWindow("Skeleton of "+originalName+"_5x5x5-median_"+i+"_purified.tif");
	saveAs("Tiff", dir+originalName+"_5x5x5-median_"+i+"_purified_skeleton.tif");
	run("Connectivity", "inputimage="+originalName+"_5x5x5-median_"+i+"_purified_skeleton.tif opservice=[net.imagej.ops.DefaultOpService [priority = 0.0]] uiservice=[org.scijava.ui.DefaultUIService [priority = 0.0]] unitservice=[net.imagej.units.DefaultUnitService [priority = 0.0]] statusservice=[org.scijava.app.DefaultStatusService [priority = 0.0]]");
	run("Close All");
}


