## simple mixed effects model data -library(nlme) ; data(PBG)
source("regression_gprior.r")
source("backselect.r")
#####
pdf("fig9_1.pdf",family="Times",height=3.5,width=7)
par(mar=c(3,3,1,1),mgp=c(1.75,.75,0))

x1<-c(0,0,0,0,0,0,1,1,1,1,1,1)
x2<-c(23,22,22,25,27,20,31,23,27,28,22,24)
y<-c(-0.87,-10.74,-3.27,-1.97,7.50,-7.25,17.05,4.96,10.40,11.05,0.26,2.51)

par(mfrow=c(1,1))
plot(y~x2,pch=16,xlab="age",ylab="change in maximal oxygen uptake", 
     col=c("black","gray")[x1+1])
legend(27,0,legend=c("aerobic","running"),pch=c(16,16),col=c("gray","black"))

dev.off()
#####


#####
pdf("fig9_2.pdf",family="Times",height=5.5,width=6)
par(mfrow=c(2,2),mar=c(3,3,1,1),mgp=c(1.75,.75,0))


plot(y~x2,pch=16,col=c("black","gray")[x1+1],ylab="change in maximal oxygen uptake",xlab="",xaxt="n")
abline(h=mean(y[x1==0]),col="black") 
abline(h=mean(y[x1==1]),col="gray")
mtext(side=3,expression(paste(beta[3]==0,"  ",beta[4]==0)) )

plot(y~x2,pch=16,col=c("black","gray")[x1+1],xlab="",ylab="",xaxt="n",yaxt="n")
abline(lm(y~x2),col="black")
abline(lm((y+.5)~x2),col="gray")
mtext(side=3,expression(paste(beta[2]==0,"  ",beta[4]==0)) )

plot(y~x2,pch=16,col=c("black","gray")[x1+1],
     xlab="age",ylab="change in maximal oxygen uptake" )
fit<-lm( y~x1+x2)
abline(a=fit$coef[1],b=fit$coef[3],col="black")
abline(a=fit$coef[1]+fit$coef[2],b=fit$coef[3],col="gray")
mtext(side=3,expression(beta[4]==0)) 

plot(y~x2,pch=16,col=c("black","gray")[x1+1],
     xlab="age",ylab="",yaxt="n")
abline(lm(y[x1==0]~x2[x1==0]),col="black")
abline(lm(y[x1==1]~x2[x1==1]),col="gray")

dev.off()
#####


##### LS estimation 
n<-length(y)
X<-cbind(rep(1,n),x1,x2,x1*x2)
p<-dim(X)[2]

beta.ols<- solve(t(X)%*%X)%*%t(X)%*%y


## probability of intersection?


####
n<-length(y)
X<-cbind(rep(1,n),x1,x2,x1*x2)
p<-dim(X)[2]

fit.ls<-lm(y~-1+ X)
beta.0<-rep(0,p) ; Sigma.0<-diag(c(150,30,6,5)^2,p)
nu.0<-1 ; sigma2.0<- 15^2

beta.0<-fit.ls$coef
nu.0<-1  ; sigma2.0<-sum(fit.ls$res^2)/(n-p)
Sigma.0<- solve(t(X)%*%X)*sigma2.0*n


S<-5000
####

rmvnorm<-function(n,mu,Sigma) 
{ # samples from the multivariate normal distribution
  E<-matrix(rnorm(n*length(mu)),n,length(mu))
  t(  t(E%*%chol(Sigma)) +c(mu))
}
###

### some convenient quantites
n<-length(y)
p<-length(beta.0)
iSigma.0<-solve(Sigma.0)
XtX<-t(X)%*%X

### store mcmc samples in these objects
beta.post<-matrix(nrow=S,ncol=p)
sigma2.post<-rep(NA,S)

### starting value
set.seed(1)
sigma2<- var( residuals(lm(y~0+X)) )

### MCMC algorithm
for( scan in 1:S) {

#update beta
V.beta<- solve(  iSigma.0 + XtX/sigma2 )
E.beta<- V.beta%*%( iSigma.0%*%beta.0 + t(X)%*%y/sigma2 )
beta<-t(rmvnorm(1, E.beta,V.beta) )

#update sigma2
nu.n<- nu.0+n
ss.n<-nu.0*sigma2.0 + sum(  (y-X%*%beta)^2 )
sigma2<-1/rgamma(1,nu.n/2, ss.n/2)

#save results of this scan
beta.post[scan,]<-beta
sigma2.post[scan]<-sigma2
                        }

#####
round( apply(beta.post,2,mean), 3)

#####
tmp<-lm.gprior(y,X )
beta.post<-tmp$beta
beta.ols<-lm(y~-1+X)$coef
g<-n ; nu0=1 ; s20<-summary( lm(y~ -1+X))$sigma^2 
beta.ols*g/(g+1)
iXX<-solve(t(X)%*%X)

mdt<-function(t,mu,sig,nu){ 

gamma(.5*(nu+1))*(1+ ( (t-mu)/sig )^2/nu )^(-.5*(nu+1))/ 
( sqrt(nu*pi)*sig* gamma(nu/2)  )
                            }

#####
pdf("fig9_3.pdf",family="Times",height=1.75,width=5)
par(mfrow=c(1,3),mar=c(2.75,2.75,.5,.5),mgp=c(1.7,.7,0))

x<-seq(-85,130,length=200)
plot(density(beta.post[,2],adj=2),xlab=expression(beta[2]),main="",ylab="",lwd=2)
abline(v=0,col="gray")
lines(x,mdt(x,0,sqrt(n*s20*iXX[2,2]),nu0 ),col="gray")

x<-seq(-5,5,length=100)
plot(density(beta.post[,4],adj=2),xlab=expression(beta[4]),main="",ylab="",lwd=2)
abline(v=0,col="gray")
lines(x,mdt(x,0,sqrt(n*s20*iXX[4,4]),nu0 ),col="gray")


source("hdr_2d.r")
plot.hdr2d( beta.post[,c(2,4)],xlab=expression(beta[2]),
   ylab=expression(beta[4]))
abline(h=0,col="gray") ; abline(v=0,col="gray")
dev.off()
#####

BX<-NULL
for(s in 1:dim(beta.post)[1]) { 
  BX<-rbind(BX, beta.post[s,2] + (min(X[,3]):max(X[,3]))*beta.post[s,4] )
              }

###
########

###
qboxplot<-function(x,at=0,width=.5,probs=c(.025,.25,.5,.75,.975))
{
  qx<-quantile(x,probs=probs)
  segments(at,qx[1],at,qx[5])
  polygon(x=c(at-width,at+width,at+width,at-width),
          y=c(qx[2],qx[2],qx[4],qx[4]) ,col="gray")
  segments(at-width,qx[3],at+width,qx[3],lwd=3)
  segments(at-width/2,qx[1],at+width/2,qx[1],lwd=1)
  segments(at-width/2,qx[5],at+width/2,qx[5],lwd=1)
} 
###



######
pdf("fig9_4.pdf",family="Times",height=3.5,width=7)
par(mfrow=c(1,1),mar=c(3,3,1,1),mgp=c(1.75,.75,0))
plot(range(X[,3]),range(y),type="n",xlab="age",
#   ylab="expected difference in change score")
    ylab=expression(paste( beta[2] + beta[4],"age",sep="") ) )
for( age  in  1:dim(BX)[2]  ) {
  qboxplot( BX[,age] ,at=age+19 , width=.25) }  
   
abline(h=0,col="gray")
dev.off() 
########



####################
library(lars) ; data(diabetes)
yf<-diabetes$y
yf<-(yf-mean(yf))/sd(yf)

Xf<-diabetes[[3]]
Xf<-t( (t(Xf)-apply(Xf,2,mean))/apply(Xf,2,sd))

###
n<-length(yf)
set.seed(1)

i.te<-sample(1:n,100)
i.tr<-(1:n)[-i.te]

y<-yf[i.tr] ; y.te<-yf[i.te]
X<-Xf[i.tr,]; X.te<-Xf[i.te,]

yperm<-sample(y)
######################


pdf("fig9_5.pdf",family="Times",height=1.75,width=5)
par(mfrow=c(1,3),mar=c(2.75,2.75,.5,.5),mgp=c(1.5,.5,0))
olsfit<-lm(y~-1+X)
y.te.ols<-X.te%*%olsfit$coef
plot(y.te,y.te.ols,xlab=expression(italic(y)[test]),
     ylab=expression(hat(italic(y))[test])) ; abline(0,1)
mean( (y.te-y.te.ols )^2 )
plot(olsfit$coef,type="h",lwd=2,xlab="regressor index",ylab=expression(hat(beta)[ols]))
###

### back elim
vars<-bselect.tcrit(y,X,tcrit=1.65)
bslfit<-lm(y~-1+X[,vars$remain])
y.te.bsl<-X.te[,vars$remain]%*%bslfit$coef
mean( (y.te-y.te.bsl)^2)
plot(y.te,y.te.bsl,ylim=range( c(y.te.bsl,y.te.ols)),
 xlab=expression(italic(y)[test]),ylab=expression(hat(italic(y))[test]))
 abline(0,1)
###
dev.off()




#####
### back elim with permuted data
pdf("fig9_6.pdf",family="Times",height=3.5,width=7)
par(mfrow=c(1,2),mar=c(3,3,1,1),mgp=c(1.75,.75,0))
fit.perm<-lm(yperm~-1+X)
t.perm<-summary(fit.perm)$coef[,3]
b.perm<-summary(fit.perm)$coef[,1]
plot(t.perm,type="h",lwd=2,xlab="regressor index",ylab="t-statistic",ylim=c(-4.8,4.8))

vars.perm<-bselect.tcrit(yperm,X,tcrit=1.65)
bslfit.perm<-lm(yperm~-1+X[,vars.perm$remain])
t.bslperm<-t.perm*0
b.bslperm<-b.perm*0
t.bslperm[vars.perm$remain]<-summary(bslfit.perm)$coef[,3]
b.bslperm[vars.perm$remain]<-summary(bslfit.perm)$coef[,1]
plot(t.bslperm,type="h",lwd=2,xlab="regressor index",ylab="t-statistic",
     ylim=c(-4.8,4.8) )
dev.off()
#####



#####
source("regression_gprior.r")
#load("diabetes.bma")
tmp<-dget("diabetes.bma")
if(2==3) {
par(mfrow=c(1,2))
p<-dim(X)[2]
S<-10000
BETA<-Z<-matrix(NA,S,p)
z<-rep(1,dim(X)[2] )
lpy.c<-lpy.X(y,X[,z==1,drop=FALSE])

for(s in 1:S)
{
      for(j in sample(1:p))
    {
      zp<-z ; zp[j]<-1-zp[j]
      lpy.p<-lpy.X(y,X[,zp==1,drop=FALSE])
      r<- (lpy.p - lpy.c)*(-1)^(zp[j]==0)
      z[j]<-rbinom(1,1,1/(1+exp(-r)))
      if(z[j]==zp[j]) {lpy.c<-lpy.p}
     }
  beta<-z;if(sum(z)>0){beta[z==1]<-lm.gprior(y,X[,z==1,drop=FALSE],S=1)$beta }
  Z[s,]<-z
  BETA[s,]<-beta
  if(s>1 ) {
   bpm<-apply(BETA[1:s,],2,mean) ; plot(bpm)
   cat(s,mean(z), mean( (y.te-X.te%*%bpm)^2),"\n")
   Zcp<- apply(Z[1:s,,drop=FALSE],2,cumsum)/(1:s)
   plot(c(1,s),range(Zcp),type="n") ; apply(Zcp,2,lines)
            }

}
save.image("diabetes.bma")
  }


BETA<-tmp$BETA ; Z<-tmp$Z

#####

pdf("fig9_7.pdf",family="Times",height=1.75,width=5)
par(mar=c(2.75,2.75,.5,.5),mgp=c(1.7,.7,0))

beta.bma<-apply(BETA,2,mean,na.rm=TRUE)
y.te.bma<-X.te%*%beta.bma
mean( (y.te-y.te.bma)^2)

layout( matrix(c(1,1,2),nrow=1,ncol=3) )

plot(apply(Z,2,mean,na.rm=TRUE),xlab="regressor index",ylab=expression(
       paste( "Pr(",italic(z[j] == 1),"|",italic(y),",X)",sep="")),type="h",lwd=2)

plot(y.te,y.te.bma,xlab=expression(italic(y)[test]),
     ylab=expression(hat(italic(y))[test])) ; abline(0,1)

dev.off()


