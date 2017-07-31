run("Close All")
dir = "/home/alessandro/Documents/data/median-filter-test/"
originalName = "tubes-15-pixels-long-with-diameter-1-3-5-and-20-pixels"
for (i=1; i<35; i=i+1) 
{
	open(dir+originalName+".tif");
	run("Median 3D...", "x="+i+" y="+i+" z="+i);
	setOption("BlackBackground", false);
	run("Make Binary", "method=IJ_IsoData background=Dark calculate black");
	run("Purify", "labelling=Mapped chunk=4 make_copy");
	saveAs("Tiff", dir+originalName+"_median_"+i+"_purified.tif");
	selectWindow(originalName+"_median_"+i+"_purified.tif");
	//run("Thickness", "inputimage=[RVC_domestic_cat_head_IJ_isodata_purified_median_"+i+"_purified.tif] mapchoice=[Trabecular thickness] showmaps=false maskartefacts=false croptorois=false logservice=[org.scijava.log.StderrLogService [priority = -100.0]] platformservice=[org.scijava.platform.DefaultPlatformService [priority = 0.0]] uiservice=[org.scijava.ui.DefaultUIService [priority = 0.0]] statusservice=[org.scijava.app.DefaultStatusService [priority = 0.0]]");
	//saveAs("BoneJ Results", "/home/alessandro/Documents/data/ITA/cat-test/binary/thickness/RVC_domestic_cat_head_IJ_isodata_purified_median_"+i+"_purified_thickness.csv");
	run("Connectivity", "inputimage="+originalName+"_median_"+i+"_purified.tif opservice=[net.imagej.ops.DefaultOpService [priority = 0.0]] uiservice=[org.scijava.ui.DefaultUIService [priority = 0.0]] unitservice=[net.imagej.units.DefaultUnitService [priority = 0.0]] statusservice=[org.scijava.app.DefaultStatusService [priority = 0.0]]");
	run("Skeletonise", "inputimage="+originalName+"_median_"+i+"_purified.tif statusservice=[org.scijava.app.DefaultStatusService [priority = 0.0]]");
	selectWindow("Skeleton of "+originalName+"_median_"+i+"_purified.tif");
	saveAs("Tiff", dir+originalName+"_median_"+i+"_purified_skeleton.tif");
	run("Connectivity", "inputimage="+originalName+"_median_"+i+"_purified_skeleton.tif opservice=[net.imagej.ops.DefaultOpService [priority = 0.0]] uiservice=[org.scijava.ui.DefaultUIService [priority = 0.0]] unitservice=[net.imagej.units.DefaultUnitService [priority = 0.0]] statusservice=[org.scijava.app.DefaultStatusService [priority = 0.0]]");
	run("Close All");
}


