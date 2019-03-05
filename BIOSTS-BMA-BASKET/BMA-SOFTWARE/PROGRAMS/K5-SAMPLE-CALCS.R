options(echo=TRUE) # if you want see commands in output file
args <- commandArgs(trailingOnly = TRUE)
node.idx = as.numeric(args[1]);


if (.Platform$OS.type == "windows") { node.idx = 1 }


if (.Platform$OS.type == "windows") { root.path = "C:/Users/psioda/Documents/GitHub/BIOSTS-BMA-BASKET/BMA-SOFTWARE/SOURCE";   }
if (.Platform$OS.type == "unix")    { root.path = "/proj/psiodalab/projects/BMA/SOURCE";                                      }

setwd(root.path);
source("./bma.rcpp");


y = c( 3, 3, 5,10,10)
n = c(12,12,12,20,20)

epsilon   = 0; 
mu0       = c(0.45);
phi0      = c(0.50);
pmp0      = c(0.00); a = BMA_PMP(y,n,pmp0,mu0,phi0,epsilon);  a$post.prob.equiv;
pmp0      = c(1.00); a = BMA_PMP(y,n,pmp0,mu0,phi0,epsilon);  #a$post.prob.equiv;
pmp0      = c(2.00); a = BMA_PMP(y,n,pmp0,mu0,phi0,epsilon);  a$post.prob.equiv;
pmp0      = c(3.00); a = BMA_PMP(y,n,pmp0,mu0,phi0,epsilon);  #a$post.prob.equiv;


 a = data.frame(cbind(c(a$post.mod.prob),a$models));
 colnames(a)<-c("pmp","b1","b2","b3","b4","b5");
