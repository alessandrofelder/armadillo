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
  info$swp <- shapiroTestWrapper(angles)$p
  info$logswp <- shapiroTestWrapper(log(angles))$p
  info$mode <- histogram$mids[which.max(histogram$counts)]
  if (is.null(info$mode))
    info$mode <- NA_real_
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
  if (length(unique(masses)) > 2)
  {
    for (var.index in 2:9)
    {
      print(var.index)
      print(var.names[var.index])
      test <-
        cor.test(masses, unlist(data[var.index,]), method = "spearman")
      print(c("linear", test$p.value, test$estimate))
      logtest <-
        cor.test(log(masses), log(unlist(three.node.data[var.index,])), method = "spearman")
      print(c("logarithmic", logtest$p.value, logtest$estimate))
      log10test <-
        cor.test(log10(masses), log10(unlist(three.node.data[var.index,])), method = "spearman")
      print(c("logarithmic", log10test$p.value, log10test$estimate))
    }
  }
  else
  {
    warning("Not enough data points for meaningful correlation.")
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
  function(hist, valence, name, perc.thickness) {
    histogram <- eval(hist)
    no.space.name = gsub(pattern = " ", replacement = "-",name)
    pdf(paste0("../../individual-plots/histo-valence",valence,"-thickness-",perc.thickness,"-",no.space.name,".pdf"))
    plot(
      histogram,
      freq = FALSE,
      xlim = c(0, 180),
      xaxt = 'n',
      xlab = "angle [\U00B0]",
      ylab = "bin frequency %",
      main = paste0(
        "ITA distribution (",
        valence,
        "-valent-nodes)\n",
        name,
        " ",
        perc.thickness
      ),
      col = cbbPalette[valence - 2]
    )
    axis(
      side = 1,
      at = seq(0, 180, 30),
      labels = seq(0, 180, 30)
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
  angles <- radians / pi * 180
  
  if(valences[1]==3) angles3 <- as.numeric(angles[1,]) else angles3 <-c()
  if(valences[2]==4) angles4 <- as.numeric(angles[2,]) else angles4 <-c()
  if(valences[3]==5) angles5 <- as.numeric(angles[3,]) else angles5 <-c()
  if(valences[4]==6) angles6 <- as.numeric(angles[4,]) else angles6 <-c()
  
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
  
  if (length(angles3) > 0)
  {
      histogram3 <-
      hist(angles3, breaks = 45, plot = F)
    histogram3$density = histogram3$counts / sum(histogram3$counts) * 100
    val <- 3
    saveITAHistogram(
      histogram3,
      valence = val,
      name = file.name,
      perc.thickness = current.perc.thickness
    )
  }
  if (length(angles4) > 0)
  {
    histogram4 <-
      hist(angles4, breaks = 45, plot = F)
    histogram4$density = histogram4$counts / sum(histogram4$counts) * 100
    val <- 4
    saveITAHistogram(
      histogram4,
      valence = val,
      name = file.name,
      perc.thickness = current.perc.thickness
    )
  }
  if (length(angles5) > 0)
  {
    histogram5 <-
      hist(angles5, breaks = 45, plot = F)
    histogram5$density = histogram5$counts / sum(histogram5$counts) * 100
    val <- 5
    saveITAHistogram(
      histogram5,
      valence = val,
      name = file.name,
      perc.thickness = current.perc.thickness
    )
  }
  if (length(angles6) > 0)
  {
    histogram6 <-
      hist(angles6, breaks = 45, plot = F)
    histogram6$density = histogram6$counts / sum(histogram6$counts) * 100
    val <- 6
    saveITAHistogram(
      histogram6,
      valence = val,
      name = file.name,
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
  
  #beautify plot
  plot <- plot + annotate("text", x=5.5, y=95, size=6, label=paste0("% higher valence: ",round(100-sum(plot.proportions$percentages))))
  plot <- plot + annotate("text", x=5.5, y=90, size=6, label=paste0("total # nodes: ",number.of.nodes))
  plot <- plot + scale_colour_manual(values = cbbPalette) +ylim(0,100)
  plot <-
    plot + theme_bw(base_size = 20) + theme(
      panel.border = element_blank(),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      axis.line = element_line(colour = "black"),
      legend.position="none"
    )
  plot <-
    plot + ggtitle(binomial) +
    xlab("node connectivity") + ylab("node type %")
  
  #plot <- plot + scale_colour_hue(c=hue.vector, l=luminescence.vector)
  ggsave(
    filename = paste0(
      "../../individual-plots/proportions-",gsub(pattern=' ', replacement="-",file.name),"-thickness-",current.perc.thickness,".pdf"
    )
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
    print(results)
    print("6-connected")
    printAngleInfo(angles6, file.name, histogram6)
  }
  
  return(results)
}


testrun <- FALSE
#hue.vector <- c(100,100,50,100) #default:100
#luminescence.vector <- c(65,65,40,65) #default:65


if (testrun)
{
  working.directory <- "~/Documents/data/ITA-test/"
} else
{
  working.directory <- "~/Documents/data/ITA/cat-test/despeckle/"
}

setwd(working.directory)
for (current.perc.thickness in ((1:19) * 10))
{
  binomial.to.mass.map <- c()
  file.to.binomial.map <- c()
  
  if (!testrun)
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
  }
  else{
    binomial.to.mass.map$MSW05_Binomial = c("Rhombic dodecahedron", "Stochastic lattice")
    binomial.to.mass.map$X5.1_AdultBodyMass_g = c(10, 100)
    
    file.to.binomial.map$file.name = c("Dod Ti binary1_purified-dilated-purified-eroded.tif",
                                       "Stoch Ti binary.tif")
    file.to.binomial.map$binomial = c("Rhombic dodecahedron", "Stochastic lattice")
    
    abbreviated.names <- vector(mode = "character", length = 2)
    mass.data <- vector(mode = "numeric", length = 2)
  }
  
  path.of.interest <-
    paste0("./angles/cutOff", current.perc.thickness, "Percent/")
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
  difference <- original.length-length(raw.results)
  if(difference>0) warning(paste("Warning: deleted ",difference," null entries."))
  
  raw.data.frame <- as.data.frame(raw.results)
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
  
  # temp.col.names <- c()
  # if(length(dim(three.node.data))==2)
  #   temp.col.names <- unlist(three.node.data[1,])
  # else
  #   temp.col.names <- three.node.data[1]
  # colnames(three.node.data) <- temp.col.names
  # 
  # if(length(dim(four.node.data))==2)
  #   temp.col.names <- unlist(four.node.data[1,])
  # else
  #   temp.col.names <- four.node.data[1]
  # colnames(four.node.data) <- temp.col.names
  # 
  # if(length(dim(five.node.data))==2)
  #   temp.col.names <- unlist(five.node.data[1,])
  # else
  #   temp.col.names <- five.node.data[1]
  # colnames(five.node.data) <- temp.col.names
  # 
  # if(length(dim(six.node.data))==2)
  #   temp.col.names <- unlist(six.node.data[1,])
  # else
  #   temp.col.names <- six.node.data[1]
  # colnames(six.node.data) <- temp.col.names
  # 
  # unlisted <- c()
  # if(length(dim(three.node.data))==2)
  #   unlisted <- unlist(three.node.data[1,])
  # else
  #   unlisted <- three.node.data[1]
  
  for (i in 1:length(colnames(three.node.data)))
  {
    current.file <- unlisted[i]
    binary.file <-
      gsub(pattern = "_skeleton.csv", replacement = ".tif", current.file)
    binary.file <-
      gsub(
        pattern = paste0("angles-percThick-", current.perc.thickness, "-"),
        replacement = "",
        binary.file
      )
    binary.file <-
      gsub(pattern = path.of.interest, replacement = "", binary.file)
    index <- which(binary.file == file.to.binomial.map$file.name)
    abbreviated.names[i] <-
      abbreviate(file.to.binomial.map$binomial[index])
    mass.data[i] <-
      getMassFromBinomial(file.to.binomial.map$binomial[index])
  }
  
  abbreviated.names[which(abbreviated.names=="")]<-"NA"
  abbreviated.names <- abbreviated.names[!abbreviated.names=="NA"]
  mass.data <- Filter(function(m) m>0.0, mass.data)
  mass.data <- as.matrix(mass.data)
  
  var.names <-
    c(
      "file name",
      "angle number",
      "mean",
      "standard deviation",
      "median",
      "SW test p value",
      "logarithmic SW test p value",
      "mode",
      "proportion"
    )
  
  sink(
    file = paste0(
      "comparative-summaries/cut-off-at-",
      current.perc.thickness,
      "-percent-avg-thickness-3-node-data-summary.txt"
    )
  )
  doCorrelationTests(mass.data, three.node.data)
  sink()
  sink(
    file = paste0(
      "comparative-summaries/cut-off-at-",
      current.perc.thickness,
      "-percent-avg-thickness-4-node-data-summary.txt"
    )
  )
  doCorrelationTests(mass.data, four.node.data)
  sink()
  sink(
    file = paste0(
      "comparative-summaries/cut-off-at-",
      current.perc.thickness,
      "-percent-avg-thickness-5-node-data-summary.txt"
    )
  )
  doCorrelationTests(mass.data, five.node.data)
  sink()
  sink(
    file = paste0(
      "comparative-summaries/cut-off-at-",
      current.perc.thickness,
      "-percent-avg-thickness-6-node-data-summary.txt"
    )
  )
  doCorrelationTests(mass.data, six.node.data)
  sink()
  
  indices.to.keep = mass.data[,1]>1e3 & mass.data[,1]<15e3
  mass.data <- mass.data[indices.to.keep]
  abbreviated.names <- abbreviated.names[indices.to.keep]
  three.node.data <- as.matrix(three.node.data[,indices.to.keep])
  four.node.data <- as.matrix(four.node.data[,indices.to.keep])
  
  for (var.index in c(2, 3, 5, 9, 4, 6, 7, 8))
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
             )) + geom_point()+geom_text_repel(aes(x = mass,y = ydata,label=name))
    
    #beautify plot
    plot <- plot + scale_colour_manual(values = cbbPalette)# + scale_colour_hue(c=hue.vector, l=luminescence.vector)
    plot <-
      plot + theme_bw(base_size = 20) + theme(
        panel.border = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        axis.line = element_line(colour = "black")
      ) + guides(size=FALSE)
    plot <-
      plot + ggtitle(var.names[var.index])+ ylab(var.names[var.index])
    
    if (testrun)
    {
      plot <-
        plot + scale_x_log10(breaks = c(1, 2),
                             labels = c("Rh. 12-hedron", "Stochastic")) +
        xlab("lattice") 
    }
    else{
      plot <-
        plot +scale_x_log10()+xlab("mass")
    }
    ggsave(
      filename = paste0(
        "comparative-plots/plot-thickness-perc",
        current.perc.thickness,
        "-",
        var.names[var.index],
        ".pdf"
      )
    )
  }
}


#lines(log(mass.data), rep(0.05, length(log(mass.data))))

#lapply(angles.files, shapiro.test)
#wilcox.test(cow.angles, elephant.angles)
