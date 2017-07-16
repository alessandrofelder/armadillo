run("Close All")
dir = getDirectory("Choose a Directory ");
files = getFileList(dir);

setBatchMode(true);
newImage("dummyImageToSetGlobalScale", "16-bit black", 1, 1, 1);
run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel global");
run("Close");
for (i=0; i<files.length; i++) 
{
    if (endsWith(files[i], "tif"))
    {	
		open(dir+files[i]);
		run("Thickness", "thickness");
		saveAs("Results", dir+"/thickness/"+replace(files[i],".tif","-thickness.csv"));
		run("Close All");
		setKeyDown("none");
    }
}
setBatchMode(false);
run("Close All")