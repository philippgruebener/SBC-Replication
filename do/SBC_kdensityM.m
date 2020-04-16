%SBC
%This version, April 16, 2020. 
%Matlab code to calculate kernel densities. 
%Data creation and cleaning is done in SBC_ReplicaEmpirics.do
%See SBC_ReplicaEmpirics.do for additional details

clear all
close all
cd '.../SBC-Replication/'


% COVID period 
T = readtable('figs/z0covid.csv','HeaderLines',1);
mcap = T(:,1);
mcap = mcap{:,:};
zd0 = T(:,2);
zd0 = zd0{:,:};
[f,xi] = ksdensity(zd0,'weights',mcap,'Bandwidth',0.08);
plot(xi,f);
writematrix([f;xi]','replicationxls/z0CO.csv');

% Great Recession period
T = readtable('figs/z0gr.csv','HeaderLines',1);
mcap = T(:,1);
mcap = mcap{:,:};
zd0 = T(:,2);
zd0 = zd0{:,:};
[f,xi] = ksdensity(zd0,'weights',mcap,'Bandwidth',0.08);
plot(xi,f);
writematrix([f;xi]','replicationxls/z0GRec.csv');

% 2015-2019 period
T = readtable('figs/z0yr1519.csv','HeaderLines',1);
mcap = T(:,1);
mcap = mcap{:,:};
zd0 = T(:,2);
zd0 = zd0{:,:};
[f,xi] = ksdensity(zd0,'weights',mcap,'Bandwidth',0.08);
plot(xi,f);
writematrix([f;xi]','replicationxls/z0Pre.csv');


