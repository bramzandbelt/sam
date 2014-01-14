% Script for checking fits
clear all;close all;clc;

% Adjust the following settings
% =========================================================================
iSubj           = 8;                % Subject index
choiceMechType  = 'race';
inhibMechType   = 'race';
condParam       = 'v';
simGoal         = 'explore';
simScope        = 'all';
iX              = 1;
solverType      = 'fminsearchcon';

jobFileName     = sprintf('job_optimize_%strials_c%s_i%s_p%s_iX%.3d.*.mat',simScope,choiceMechType,inhibMechType,condParam,iX);
XFileName       = sprintf('finalLog_obs_c%s_i%s_%s_%strials_iX%.3d.*.mat',choiceMechType,inhibMechType,condParam,simScope,iX);

% jobFileName     = 'job_optimize_gotrials_crace_irace_pv_iX001_2013-10-04-T131933.mat';
% XFileName       = 'finalLog_obs_crace_irace_v_goTrials_iX001_2013-10-04-T131933.mat'


[~,hostName] = system('hostname');
switch lower(strtrim(hostName))
  case 'bram-zandbelts-macbook-pro-2.local'
    rootDir     = '/Users/bramzandbelt/Documents/Dropbox/SAM/data/';
  case 'dhcp-129-59-230-168.n1.vanderbilt.edu'
    rootDir     = '/Users/bramzandbelt/Dropbox/SAM/data/';
  otherwise
    if regexp(hostName,'.*vampire')
      rootDir   = '/scratch/zandbeb/sam/';
    else
      error('Unknown host')
    end
end
    
% Keep the following settings fixed
% =========================================================================

% Empty arrays
% -------------------------------------------------------------------------

% Structure for logging predicted trial probabilities and response times
prdData  = struct('P',[],...
                  'rt',[]);

% Structure for logging data for optimization
obsData  = struct('rt',[],...
                  'N',[],...
                  'P',[],...
                  'rtQ',[],...
                  'f',[],...
                  'pM',[]);

% Load files
% -------------------------------------------------------------------------

% Load the job file (SAM)
load(char(regexpdir(fullfile(rootDir,sprintf('subj%.2d/jobs/',iSubj)),jobFileName)));

% Load the log file
load(char(regexpdir(fullfile(rootDir,sprintf('subj%.2d/fitLogs/',iSubj)),XFileName)));

% Load the observations file
load(fullfile(rootDir,sprintf('subj%.2d/',iSubj),'obs.mat'));


% Setup plotSAM
% -------------------------------------------------------------------------

% Copy the relevant fields from SAM into plotSAM
plotSAM     = struct();
plotSAM.io  = SAM.io;
plotSAM.des = SAM.des;
plotSAM.sim = SAM.sim;

% Modify paths to data
plotSAM.io.outDir     = fullfile(rootDir,sprintf('subj%.2d/',iSubj));
plotSAM.io.obsFile    = fullfile(rootDir,sprintf('subj%.2d/obs.mat',iSubj));

% Modify simulation goal and scope
plotSAM.sim.goal = simGoal;
plotSAM.sim.scope = simScope;

% Add the explore field
plotSAM.explore.X                          = X;
plotSAM.explore.XName                      = SAM.optim.XName;
plotSAM.explore.tWinGo                     = [-250 2250];
plotSAM.explore.tWinStop                   = [-250 2250];  
plotSAM.explore.tWinResp                   = [-500 0];
plotSAM.explore.doPlot                     = false;

%%%%%
% This is for testing parameter settings only, otherwise comment this out
%%%%%
% plotSAM.sim.nSim = 200;
% plotSAM.des.choiceMech.type = 'li';
% plotSAM.des.inhibMech.type = 'li';
% plotSAM.des.condParam = 'v';
% [~,~,X0] = sam_get_bnds(plotSAM.des.choiceMech.type,plotSAM.des.inhibMech.type,plotSAM.des.condParam,'optimize',simScope,solverType,iSubj);
% plotSAM.explore.X = X0;

% Simulate data
[prd,modelMat] = sam_run_job(plotSAM);

% Characterize observations and comput RT bin stats
% -------------------------------------------------------------------------

cumProb     = SAM.optim.cumProb;
minBinSize  = SAM.optim.minBinSize;

switch lower(simScope)
  case 'go'
    
    obsData.N   = [obs.nGo,obs.nGo];
    obsData.P   = [obs.pGoCorr,obs.pGoComm];
    obsData.rt  = [obs.rtGoCorr,obs.rtGoComm];
    
  case 'all'
    
    obsData.N   = [obs.nGo,obs.nGo,obs.nStop];
    obsData.P   = [obs.pGoCorr,obs.pGoComm,obs.pStopFailure];
    obsData.rt  = [obs.rtGoCorr,obs.rtGoComm,obs.rtStopFailure];
end

[obsData.rtQ, ...         % Quantiles
 obsData.pDefect, ...     % Defective probabilities
 obsData.f, ...           % Frequencies
 obsData.pM] ...          % Probability masses
 = cellfun(@(a,b,c) sam_bin_data(a,b,c,cumProb,minBinSize), ...
 obsData.rt, ...          % Response times
 num2cell(obsData.P), ... % Response probabilities
 num2cell(obsData.N), ... % Response frequencies
 'Uni',0);

% Characterize observations and compute RT bin stats
% -------------------------------------------------------------------------

switch lower(simScope)
  case 'go'
    prdData.P       = [prd.pGoCorr,prd.pGoComm];
    prdData.rt      = [prd.rtGoCorr,prd.rtGoComm];
  case 'all'
    prdData.P       = [prd.pGoCorr,prd.pGoComm,prd.pStopFailure];
    prdData.rt      = [prd.rtGoCorr,prd.rtGoComm,prd.rtStopFailure];
end

nSim = SAM.sim.nSim;
nSimCell = num2cell(nSim*ones(size(prdData.P)));

prdData.pM  = cellfun(@(a,b,c) histc(a(:),[-Inf,b,Inf])./c,prdData.rt,obsData.rtQ,nSimCell,'Uni',0);
prdData.pM  = cellfun(@(a) a(1:end-1),prdData.pM,'Uni',0);
prdData.pM  = cellfun(@(a) a(:),prdData.pM,'Uni',0);


% Plot the RT distributions
% -------------------------------------------------------------------------
sam_plot_obs_prd(plotSAM,obsData,prdData)
% sam_plot_obs_prd_poster_tryout(plotSAM,obsData,prdData,obs,prd)