library(plyr)
library(smatr)
library(ggplot2)
library(ggrepel)
library(scales)


cbbPalette <-
  c("#E69F00",
    "#56B4E9",
    "#009E73",
    "#CC79A7") #subset of colour-blind friendly palette from cookbook-r.com. Thanks!

shapiroTestWrapper <- function(sample)
{
  n = length(sample)
  dummy.result = list()
  if (n < 3)
  {
    dummy.result$statistic <- NA_real_
    dummy.result$p.value <- NA_real_
    dummy.result$method <- "Shapiro-Wilk wrapper"
    dummy.result$data.name <- deparse(substitute(sample))
    return(dummy.result)
  }
  if (n >= 5000)
    return(shapiro.test(sample[1:5000]))
  else
    return(shapiro.test(sample))
}

getMassFromBinomial <- function(binomial)
{
  mass.index <- grep(binomial, binomial.to.mass.map$MSW05_Binomial)
  if (length(mass.index) != 1)
  {
    print(paste("species not in this database:", binomial, "(", i, ")"))
    mass <- NA
  }
  else
  {
    mass <- binomial.to.mass.map$X5.1_AdultBodyMass_g[mass.index]#in g!
  }
}

printAngleInfo <- function(angles, file.name, histogram) {
  print(getAngleInfo(angles, file.name, histogram))
}

getAngleInfo <- function(angles, file.name, histogram) {
  info <- list()
  info$file.name <- file.name
  info$length <- length(angles)
  info$mean <- mean(angles, na.rm = TRUE)
  info$sd <- sd(angles, na.rm = TRUE)
  info$median <- median(angles, na.rm = TRUE)
  info$upperquartile <- quantile(angles, na.rm = TRUE, 0.75)
  info$lowerquartile <- quantile(angles, na.rm = TRUE, 0.25)
  info$swp <- shapiroTestWrapper(angles)$p
  info$mode <- histogram$mids[which.max(histogram$counts)]
  if (is.null(info$mode))
    info$mode <- NA_real_  
  if (is.null(info$median))
    info$median <- NA_real_
  if (is.null(info$upperquartile))
    info$upperquartile <- NA_real_
  if (is.null(info$median))
    info$lowerquartile <- NA_real_
  return(info)
}

getTotalNodes <- function(angles,valences)
{
  total.number.of.junctions = 0
  for (i in seq(1, dim(angles)[1]))
  {
    current.valence = valences[i]
    number.of.current.valence.angles = sum(is.finite(as.numeric(angles[i,])))
    angle.number.to.node.number.ratio = choose(current.valence, 2)
    number.of.current.valence.junctions = number.of.current.valence.angles /
      angle.number.to.node.number.ratio
    total.number.of.junctions = total.number.of.junctions + number.of.current.valence.junctions
  }
  return(total.number.of.junctions)
}

breakNumber <- function(n)
{
  return(45)
  #ceiling(sqrt(n))
}

doCorrelationTests <- function(masses, data) {
  print(substitute(data))
  if (length(unique(masses)) > 2 && length(unique(data[2,])) > 2)
  {
    for (var.index in 2:8)
    {
      print(var.index)
      print(var.names[var.index])
      test <-
        cor.test(masses, unlist(data[var.index,]), method = "spearman")
      print(c("linear", test$p.value, test$estimate))
      logtest <-
        cor.test(log(masses), log(unlist(data[var.index,])), method = "spearman")
      print(c("logarithmic", logtest$p.value, logtest$estimate))
      log10test <-
        cor.test(log10(masses), log10(unlist(data[var.index,])), method = "spearman")
      print(c("logarithmic", log10test$p.value, log10test$estimate))
    }
  }
  else
  {
    warning("Not enough data points for meaningful correlation. Printing raw data.")
    print(data)
  }
}

robustRadiansReader = function(file.name)
{
  tryCatch(
    read.csv(file.name, header = FALSE),
    error = function(e) {
      print(paste("empty file:", file.name))
      
      c()
    }
  )
}


saveITAHistogram <-
  function(hist, valence, filename, name, perc.thickness) {
    histogram <- eval(hist)
    no.space.name = gsub(pattern = " ", replacement = "-",filename)
    png(paste0("../../individual-plots/histo-valence",valence,"-",gsub(".csv","",no.space.name),".png"))
    mar.default <- c(5, 4, 4, 2)
    par(mar = mar.default + c(1, 2, 0, 0)) 
    fontSizeFactor <- 2
    valenceTitlePart = paste0(
      "(",
      valence,
      "-valent nodes)\n")
    plot(
      histogram,
      freq = FALSE,
      xaxt = 'n',
      xlim = c(0, 180),
      ylim = c(0,max(7,histogram$density)),
      xlab = "angle [\U00B0]",
      ylab = "bin frequency %",
      cex.lab=fontSizeFactor,
      cex.axis=fontSizeFactor,
      main = substitute({bolditalic(ni)}, list(ni=name)
      ),
      col = cbbPalette[valence - 2]
    )
    axis(
      side = 1,
      cex.axis=fontSizeFactor-0.5,
      at=seq(0, 180,by=30),
      labels=seq(0,180,by=30)
    )
    dev.off()
  }

computeITAStats <- function(file.name, map, verbose)
{
  results <- list()
  
  raw.radians <- robustRadiansReader(file.name)
  if (!length(raw.radians))
    return(c())
  
  valences <- raw.radians[,1]
  radians <- raw.radians[,-1]
  koosh <- 0
  if(strsplit(as.character(valences[length(valences)])," ")[[1]][1]=="Koosh")
  {
    print(paste0("Koosh ball with ",strsplit(as.character(valences[length(valences)])," ")[[1]][10]," connections detected in ",file.name))
    koosh <- strsplit(as.character(valences[length(valences)])," ")[[1]][10]
    valences<-valences[1:length(valences)-1]
    valences<-as.numeric(as.character(valences))
    radians<-radians[1:length(valences),]
  }
  
  angles <- radians / pi * 180
  
  if(!is.na(valences[1]) & valences[1]==3) angles3 <- as.numeric(angles[1,]) else angles3 <-c()
  if(!is.na(valences[2]) & valences[2]==4) angles4 <- as.numeric(angles[2,]) else angles4 <-c()
  if(!is.na(valences[3]) & valences[3]==5) angles5 <- as.numeric(angles[3,]) else angles5 <-c()
  if(!is.na(valences[4]) & valences[4]==6) angles6 <- as.numeric(angles[4,]) else angles6 <-c()
  
  angles3 = angles3[which(is.finite(as.numeric(angles[1,])))]
  angles4 = angles4[which(is.finite(as.numeric(angles[2,])))]
  angles5 = angles5[which(is.finite(as.numeric(angles[3,])))]
  angles6 = angles6[which(is.finite(as.numeric(angles[4,])))]
  
  histogram3 <- c()
  histogram4 <- c()
  histogram5 <- c()
  histogram6 <- c()
  
  current.perc.thickness <-
    as.numeric(strsplit(file.name, "-")[[1]][3])
  tiff.file.name <-
    gsub(pattern = "-skeleton.csv", replacement = ".tif", file.name)
  tiff.file.name <-
    gsub(
      pattern = paste0("angles-percThick-", current.perc.thickness, "-"),
      replacement = "",
      tiff.file.name
    )
  
  local.map <- eval(map)
  index <- which(tiff.file.name == file.to.binomial.map$file.name)
  binomial <- file.to.binomial.map$file.name[index]
  plot.title.name <- file.name
  if (run==2)
  {
    unlisted.file.name <- unlist(strsplit(file.name,"-"))
    plot.title.name <- paste0(current.noise.removal.operation," ", gsub(pattern = "\\D", replacement = "", unlisted.file.name[length(unlisted.file.name)-1]))
  }
  if (run==3)
  {
    binary.file <- gsub("useClusters-True-","",tiff.file.name)
    binary.file <- gsub(".tif","-binary.tif",binary.file)
    index <- which(binary.file == file.to.binomial.map$file.name)
    plot.title.name <- file.to.binomial.map$binomial[index]
  }
    
  if (length(angles3) > 0)
  {
      histogram3 <-
      hist(angles3, breaks = seq(0,180,4), plot = F)
    histogram3$density = histogram3$counts / sum(histogram3$counts) * 100
    val <- 3
    saveITAHistogram(
      histogram3,
      valence = val,
      filename = file.name,
      name = plot.title.name,
      perc.thickness = current.perc.thickness
    )
  }
  if (length(angles4) > 0)
  {
    histogram4 <-
      hist(angles4, breaks = seq(0,180,4), plot = F)
    histogram4$density = histogram4$counts / sum(histogram4$counts) * 100
    val <- 4
    saveITAHistogram(
      histogram4,
      valence = val,
      filename = file.name,
      name = plot.title.name,
      perc.thickness = current.perc.thickness
    )
  }
  if (length(angles5) > 0)
  {
    histogram5 <-
      hist(angles5, breaks = seq(0,180,4), plot = F)
    histogram5$density = histogram5$counts / sum(histogram5$counts) * 100
    val <- 5
    saveITAHistogram(
      histogram5,
      valence = val,
      filename = file.name,
      name = plot.title.name,
      perc.thickness = current.perc.thickness
    )
  }
  if (length(angles6) > 0)
  {
    histogram6 <-
      hist(angles6, breaks = seq(0,180,4), plot = F)
    histogram6$density = histogram6$counts / sum(histogram6$counts) * 100
    val <- 6
    saveITAHistogram(
      histogram6,
      valence = val,
      filename = file.name,
      name = plot.title.name,
      perc.thickness = current.perc.thickness
    )
  }
  angles3info <- getAngleInfo(angles3, file.name, histogram3)
  angles4info <- getAngleInfo(angles4, file.name, histogram4)
  angles5info <- getAngleInfo(angles5, file.name, histogram5)
  angles6info <- getAngleInfo(angles6, file.name, histogram6)
  
  results <- cbind(results, angles3info)
  results <- cbind(results, angles4info)
  results <- cbind(results, angles5info)
  results <- cbind(results, angles6info)
  number.of.nodes <- getTotalNodes(angles,valences)
  proportions <- 100.0 / number.of.nodes * c(
    length(angles3) / 3.0,
    length(angles4) / 6.0,
    length(angles5) / 10.0,
    length(angles6) / 15.0
  )
  #basic plot
  
  plot.proportions <- data.frame(
    percentages=proportions,
    valences=1:length(proportions)+2,
    type = factor(c("3-N", "4-N", "5-N", "6-N")))
  plot <-
    ggplot()+geom_point(data = plot.proportions,
           aes(
             x = valences,
             y = percentages,
             colour = type,
             size = 3
           ))
  
  #add Koosh ball connectivity if present
  if(koosh>0)
  {
    plot <- plot + annotate("text", x=5, y=75, size=6, label=paste0(koosh,"-valent node!"))
  }
  
  #beautify plot
  plot <- plot + annotate("text", x=5, y=95, size=6, label=paste0("% higher valence: ",round(100-sum(plot.proportions$percentages))))
  plot <- plot + annotate("text", x=5, y=85, size=6, label=paste0("total # nodes: ",number.of.nodes))
  plot <- plot + scale_colour_manual(values = cbbPalette) +ylim(0,100)
  plot <-
    plot + theme_bw(base_size = 20) + theme(
      panel.border = element_blank(),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      axis.line = element_line(colour = "black"),
      legend.position="none"
    )
  #plot <- plot + ggtitle(binomial)
  plot <- plot + xlab("node valence") + ylab("node type %")
  
  #plot <- plot + scale_colour_hue(c=hue.vector, l=luminescence.vector)
  ggsave(
    filename = paste0(
      "../../individual-plots/proportions-",gsub(pattern='.csv', replacement="",file.name),".png"),width = 12, height = 12, units = "cm"
  )
  
  results <-
    rbind(
      results,
      proportions
    )
  results <- as.data.frame(results)
  row.names(results)[length(row.names(results))] <- "proportion"
  
  if (verbose) {
    print("3-connected")
    printAngleInfo(angles3, file.name, histogram3)
    print("4-connected")
    printAngleInfo(angles4, file.name, histogram4)
    print("5-connected")
    printAngleInfo(angles5, file.name, histogram5)
    print("6-connected")
    printAngleInfo(angles6, file.name, histogram6)
  }
  
  return(results)
}


run <- 3 #enum variable: 1=test on metal prints, 2=run as validation study, 3=run as scaling study
#hue.vector <- c(100,100,50,100) #default:100
#luminescence.vector <- c(65,65,40,65) #default:65

current.noise.removal.operation <- "unknown"
if (run==1)
{
  working.directory <- "~/Documents/data/ITA/metal-test-order-dependent/"
} else if (run==2)
{
  #working.directory <- "~/Documents/data/ITA/cat-test/despeckle/"
  #current.noise.removal.operation <- "despeckle operations"
  
  #working.directory <- "~/Documents/data/ITA/cat-test/median-increasing-radius/"
  #current.noise.removal.operation <- "3D median filter radius [voxels]"
  
  #working.directory <- "~/Documents/data/ITA/cat-test/erode-dilate/"
  #current.noise.removal.operation <- "erode and dilate operations"

  #working.directory <- "~/Documents/data/ITA/cat-test/median-3x3x3/"
  #current.noise.removal.operation <- "3D median filter (radius 1) operations"

  #working.directory <- "~/Documents/data/ITA/cat-test/median-5x5x5/"
  #current.noise.removal.operation <- "3D median filter (radius 2) operations"
  
  #working.directory <- "~/Documents/data/ITA/cat-test/median-7x7x7/"
  #current.noise.removal.operation <- "3D median filter (radius 3) operations"
  
  working.directory <- "/media/alessandro/A6E8FE87E8FE5551/Users/afelder/Desktop/ITA-cow-at-various-resolutions/"
  current.noise.removal.operation <- "resampling factor"
  
  #alpaca test
  #working.directory <- "/media/rvc_projects/Research_Storage/Doube_Michael/Felder/images/ITA-alpaca/"
  #current.noise.removal.operation <- "3D median filter (radius 2) operations"
  
} else if (run==3)
{
  working.directory <- "/media/alessandro/A6E8FE87E8FE5551/Users/afelder/Desktop/ITA-samples-resampled-after-binarization/"
} else 
{
    stop("invalid value for variable run")
}

setwd(working.directory)
enumerationOfThicknessFiles = (c(4:7,10) * 10)

for (perc.thickness in enumerationOfThicknessFiles)
{
  binomial.to.mass.map <- c()
  file.to.binomial.map <- c()
  
  if (run==3)#scaling
  {
    binomial.to.mass.map <-
      read.table(
        "PanTHERIA-extended.csv",
        header = TRUE,
        row.names = NULL,
        stringsAsFactors = FALSE,
        sep = ","
      )
    file.to.binomial.map <-
      read.table(
        "file-to-binomial-map.csv",
        header = TRUE,
        row.names = NULL,
        stringsAsFactors = FALSE,
        sep = ","
      )
    mass.data <-
      vector(mode = "numeric",
             length = length(file.to.binomial.map$file.name))
    abbreviated.names <-
      vector(mode = "character",
             length = length(file.to.binomial.map$file.name))
  } else if (run==2)
  {
    binomial.to.mass.map <-
      read.table(
        "PanTHERIA-extended.csv",
        header = TRUE,
        row.names = NULL,
        stringsAsFactors = FALSE,
        sep = ","
      )
    file.to.binomial.map <-
      read.table(
        "file-to-binomial-map.csv",
        header = TRUE,
        row.names = NULL,
        stringsAsFactors = FALSE,
        sep = ","
      )
    mass.data <-
      vector(mode = "numeric",
             length = length(file.to.binomial.map$file.name))
    abbreviated.names <-
      vector(mode = "character",
             length = length(file.to.binomial.map$file.name))
  } else
      {
    binomial.to.mass.map$MSW05_Binomial = c("Rhombic dodecahedron", "Stochastic lattice")
    binomial.to.mass.map$X5.1_AdultBodyMass_g = c(10, 100)
    
    file.to.binomial.map$file.name = c("useClusters-False-Dod Ti binary1.tif",
                                       "useClusters-False-Stoch Ti binary.tif")
    file.to.binomial.map$binomial = c("Rhombic dodecahedron", "Stochastic lattice")
    
    abbreviated.names <- vector(mode = "character", length = 2)
    mass.data <- vector(mode = "numeric", length = 2)
  }
  
  path.of.interest <-
    paste0("./angles/cutOff", perc.thickness, "Percent/")
  angles.files <-
    list.files(path = path.of.interest, pattern = 'angles*')
  setwd(path.of.interest)
  raw.results <-
    lapply(angles.files,
           computeITAStats,
           verbose = FALSE,
           map = file.to.binomial.map)
  setwd(working.directory)
  
  original.length <- length(raw.results)
  raw.results <- compact(raw.results)
  if(length(raw.results)==0)
  {
    warning(paste0("ITA: no data for ",perc.thickness," % thickness cutoff"))
    break
  }
  difference <- original.length-length(raw.results)
  if(difference>0) warning(paste("Warning: deleted ",difference," null entries."))
  
  raw.data.frame <- as.data.frame(raw.results)
  indicesOfEmptyFiles <- match(setdiff(angles.files, unique(unlist(raw.data.frame[1,]))),angles.files)
  
  three.node.data <- raw.data.frame[, 1:4 == 1]
  four.node.data <- raw.data.frame[, 1:4 == 2]
  five.node.data <- raw.data.frame[, 1:4 == 3]
  six.node.data <- raw.data.frame[, 1:4 == 4]
  
  three.node.data <- as.matrix(three.node.data)
  four.node.data <- as.matrix(four.node.data)
  five.node.data <- as.matrix(five.node.data)
  six.node.data <- as.matrix(six.node.data)

  colnames(three.node.data) <- unlist(three.node.data[1,])
  colnames(four.node.data) <- unlist(four.node.data[1,])
  colnames(five.node.data) <- unlist(five.node.data[1,])
  colnames(six.node.data) <- unlist(six.node.data[1,])
  unlisted <- unlist(three.node.data[1,])
  
  for (i in 1:length(colnames(three.node.data)))
  {
    current.file <- unlisted[i]
    binary.file <-
      gsub(pattern = "-skeleton.csv", replacement = "-binary.tif", current.file)
    binary.file <-
      gsub(
        pattern = paste0("angles-percThick-", perc.thickness, "-"),
        replacement = "",
        binary.file
      )
    binary.file <-
      gsub(
        pattern = paste0("useClusters-True-"),
        replacement = "",
        binary.file
      )
    binary.file <-
      gsub(pattern = path.of.interest, replacement = "", binary.file)
    index <- which(binary.file == file.to.binomial.map$file.name)
    abbreviated.names[i] <-
      abbreviate(file.to.binomial.map$binomial[index])
    mass.data[i] <-
      getMassFromBinomial(file.to.binomial.map$binomial[index])/1000.0
    if(run==2)
    {
      #for cat and cow
      number.of.noise.removal.operations <- unlist(strsplit(file.to.binomial.map$file.name[index],"-"))
      number.of.noise.removal.operations <- number.of.noise.removal.operations[length(number.of.noise.removal.operations)-1]
      #for alpaca
      #number.of.noise.removal.operations <- unlist(strsplit(file.to.binomial.map$file.name[index],"_"))
      #number.of.noise.removal.operations <- number.of.noise.removal.operations[2]
      mass.data[i] <- as.numeric(number.of.noise.removal.operations)
      abbreviated.names[i] <- " ";
    }
  }
  
  abbreviated.names[which(abbreviated.names=="")]<-"NA"
  abbreviated.names <- abbreviated.names[!abbreviated.names=="NA"]
  if(run!=2) mass.data <- Filter(function(m) m>0.0, mass.data)
  
  mass.data <- as.matrix(mass.data)
  mass.data <- as.matrix(mass.data[1:(length(mass.data)-length(indicesOfEmptyFiles))])
  var.names <-
    c(
      "file name",
      "angle number",
      "mean",
      "standard deviation",
      "median",
      "upper quartile",
      "lower quartile",
      "SW test p value",
      "mode",
      "proportion"
    )
  
  sink(
    file = paste0(
      "comparative-summaries/cut-off-at-",
      perc.thickness,
      "-percent-avg-thickness-3-node-data-summary.txt"
    )
  )
  doCorrelationTests(mass.data, three.node.data)
  sink()
  sink(
    file = paste0(
      "comparative-summaries/cut-off-at-",
      perc.thickness,
      "-percent-avg-thickness-4-node-data-summary.txt"
    )
  )
  doCorrelationTests(mass.data, four.node.data)
  sink()
  sink(
    file = paste0(
      "comparative-summaries/cut-off-at-",
      perc.thickness,
      "-percent-avg-thickness-5-node-data-summary.txt"
    )
  )
  doCorrelationTests(mass.data, five.node.data)
  sink()
  sink(
    file = paste0(
      "comparative-summaries/cut-off-at-",
      perc.thickness,
      "-percent-avg-thickness-6-node-data-summary.txt"
    )
  )
  doCorrelationTests(mass.data, six.node.data)
  sink()
  
  if(run==2)#possibility to look at specific size range
  {
    indices.to.keep = mass.data[,1]>0 & mass.data[,1]<1e10
    mass.data <- mass.data[indices.to.keep]
    abbreviated.names <- abbreviated.names[indices.to.keep]
    three.node.data <- as.matrix(three.node.data[,indices.to.keep])
    four.node.data <- as.matrix(four.node.data[,indices.to.keep])
  }
  
  for (var.index in c(2, 3, 4, 5, 6, 7, 9, 10))
  {
    #set up data for plotting
    current.data <- data.frame(
      mass = rep(mass.data, 2),
      valence = factor(rep(
        c("3-N", "4-N"), each = length(mass.data)
      )),
      ydata = c(
        unlist(three.node.data[var.index,]),
        unlist(four.node.data[var.index,])
      ),
      name = rep(abbreviated.names,2)
    )
    
    
    #basic plot
    plot <-
      ggplot(data = current.data,
             aes(
               x = mass,
               y = ydata,
               group = valence,
               colour = valence,
               label = name,
               size=3
             )) + geom_point(size=3)
    
    if(run!=2) 
    {
      plot <- plot + geom_text_repel(aes(x = mass,y = ydata,label=name),show.legend = FALSE)
    }
    
    #beautify plot
    plot <- plot + scale_colour_manual(values = cbbPalette)# + scale_colour_hue(c=hue.vector, l=luminescence.vector)
    plot <-
      plot + theme_bw(base_size = 20) + theme(
        panel.border = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        axis.line = element_line(colour = "black"),
        legend.position = "none"
      ) + guides(size=FALSE)
    
    ylabel <- var.names[var.index]
    if(var.index %in% c(3,4,5,7))
    {
      ylabel <- paste0(ylabel," [\U00B0]")
      if(var.index!=4)
      {
        plot <- plot + scale_y_continuous(breaks=c(60,90,120,150), labels=c(60,90,120,150)) +ylim(c(60,150))
      }
    }
    plot <-plot + ylab(ylabel)
    
    if(var.index==10)
    {
      plot <- plot + ylim(c(0,100))
    }
    
    if (run==1)
    {
      plot <-
        plot + scale_x_log10(breaks = c(1, 2),
                             labels = c("Rh. 12-hedron", "Stochastic")) +
        xlab("lattice type") 
    }
    else if(run==2)
    {
        plot <- plot+xlab(current.noise.removal.operation)+scale_x_continuous(breaks=mass.data)
    }
    else if (run==3){
      plot <-
        plot +scale_x_log10(labels=function(n){format(n, scientific = FALSE)})+xlab("adult body mass [kg]")
    }
    ggsave(
      filename = paste0(
        "comparative-plots/plot-thickness-perc",
        perc.thickness,
        "-",
        var.names[var.index],
        ".png"
      ),
      width = 8.02,
      height = 8.02,
      units = "in"
    )
  }
}


#lines(log(mass.data), rep(0.05, length(log(mass.data))))

#lapply(angles.files, shapiro.test)
#wilcox.test(cow.angles, elephant.angles)
