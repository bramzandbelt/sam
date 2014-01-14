clear all;close all;clc;

for iSubj = 8:13
  choiceMechType  = 'li';
  inhibMechType   = 'race';
  condParam       = 't0';
  simGoal         = 'optimize';
  simScope        = 'go';
  solverType      = 'fminsearchcon';
  nStartPoints    = 19;

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

  % Get the number of parameters
  LB = sam_get_bnds(choiceMechType,inhibMechType,condParam,simGoal,simScope,solverType,iSubj);
  nX = numel(LB);
  clear LB

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % MERGE GO FINALLOG FILES INTO ONE DATASET(?) ARRAY
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  srcDir          = fullfile(rootDir,sprintf('subj%.2d/fitLogs',iSubj))
  expStr          = sprintf('finalLog.*c%s_i%s_%s_%sTrials.*.mat$',choiceMechType,inhibMechType,condParam,simScope);
  fls             = regexpdir(srcDir,expStr);

  allBestFits     = nan(numel(fls),nX + 3);

  for i = 1:numel(fls)

    load(fls{i});
    allBestFits(i,1) = i;
    allBestFits(i,2) = exitFlag;
    allBestFits(i,3) = fVal;
    allBestFits(i,4:end) = X;

    clear exitFlag fVal X
  end

  % Sort by exitsFlag, then by fVal
  allBestFits = sortrows(allBestFits,[2,3]);

  allBestFits(1,:)
  bestX = allBestFits(1,4:end)
  
  % Take a pause to check the fits and parameter values
  pause;

  

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % GET X0 AND CONSTRAINTS FOR MODEL OF ALL TRIALS AND FIX GO PARAMETERS
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  simScope        = 'all';

  % Inhibition mechanism is a race
  % =========================================================================
  inhibMechType   = 'race';


  [LB,UB,X0,tg,linConA,linConB,nonLinCon] = sam_get_bnds(choiceMechType,inhibMechType,condParam,simGoal,simScope,solverType,iSubj);

  % Sanity check: are all starting values between bounds?
  if any(LB > X0) | any(UB < X0)
    error('At least one starting value is not between bounds')
  end

  iGoParam = find(cellfun(@(a) ~isempty(regexp(a,'G')),tg));
  iSe = find(cellfun(@(a) ~isempty(regexp(a,'se')),tg));
  iSi = find(cellfun(@(a) ~isempty(regexp(a,'si')),tg));
  iGoS = sort([iGoParam,iSe,iSi]);

  XNoS = bestX;

  LB(iGoS) = XNoS;
  UB(iGoS) = XNoS;
  X0(iGoS) = XNoS;

  % Check this
  [tg;num2cell(LB);num2cell(X0);num2cell(UB)]

  pause;

  % Sample additional uniformly distributed starting values between LB and UB
  X0 = [X0;sam_sample_uniform_constrained_x0(nStartPoints,LB,UB,linConA,linConB,nonLinCon,solverType)];

  % Save starting values
  fNameX0 = sprintf('x0_%strials_c%s_i%s_p%s.mat',simScope, ...
                  choiceMechType,inhibMechType,condParam);
  save(fullfile(rootDir,sprintf('subj%.2d',iSubj),fNameX0),'X0','tg');

  % Save constraints
  fNameCon = sprintf('constraints_%strials_c%s_i%s_p%s.mat',simScope, ...
                  choiceMechType,inhibMechType,condParam);
  save(fullfile(rootDir,sprintf('subj%.2d',iSubj),fNameCon),'LB','UB','linConA','linConB','nonLinCon');              


  % Inhibition mechanism is 'lateral inhibition'
  % =========================================================================
  inhibMechType   = 'bi';

  [LB,UB,X0,tg,linConA,linConB,nonLinCon] = sam_get_bnds(choiceMechType,inhibMechType,condParam,simGoal,simScope,solverType,iSubj);

  % Sanity check: are all starting values between bounds?
  if any(LB > X0) | any(UB < X0)
    error('At least one starting value is not between bounds')
  end


  iGoParam = find(cellfun(@(a) ~isempty(regexp(a,'G')),tg));
  iSe = find(cellfun(@(a) ~isempty(regexp(a,'se')),tg));
  iSi = find(cellfun(@(a) ~isempty(regexp(a,'si')),tg));
  iGoS = sort([iGoParam,iSe,iSi]);

  XNoS = bestX;

  LB(iGoS) = XNoS;
  UB(iGoS) = XNoS;
  X0(iGoS) = XNoS;

  % Check this
  [tg;num2cell(LB);num2cell(X0);num2cell(UB)]

  pause;

  % Sample additional uniformly distributed starting values between LB and UB
  X0 = [X0;sam_sample_uniform_constrained_x0(nStartPoints,LB,UB,linConA,linConB,nonLinCon,solverType)];

  % Save starting values
  fNameX0 = sprintf('x0_%strials_c%s_i%s_p%s.mat',simScope, ...
                  choiceMechType,inhibMechType,condParam);
  save(fullfile(rootDir,sprintf('subj%.2d',iSubj),fNameX0),'X0','tg');

  % Save constraints
  fNameCon = sprintf('constraints_%strials_c%s_i%s_p%s.mat',simScope, ...
                  choiceMechType,inhibMechType,condParam);
  save(fullfile(rootDir,sprintf('subj%.2d',iSubj),fNameCon),'LB','UB','linConA','linConB','nonLinCon'); 

  % Inhibition mechanism is 'lateral inhibition'
  % =========================================================================
  inhibMechType   = 'li';

  [LB,UB,X0,tg,linConA,linConB,nonLinCon] = sam_get_bnds(choiceMechType,inhibMechType,condParam,simGoal,simScope,solverType,iSubj);

  % Sanity check: are all starting values between bounds?
  if any(LB > X0) | any(UB < X0)
    error('At least one starting value is not between bounds')
  end


  iGoParam = find(cellfun(@(a) ~isempty(regexp(a,'G')),tg));
  iSe = find(cellfun(@(a) ~isempty(regexp(a,'se')),tg));
  iSi = find(cellfun(@(a) ~isempty(regexp(a,'si')),tg));
  iGoS = sort([iGoParam,iSe,iSi]);

  XNoS = bestX;

  LB(iGoS) = XNoS;
  UB(iGoS) = XNoS;
  X0(iGoS) = XNoS;

  % Check this
  [tg;num2cell(LB);num2cell(X0);num2cell(UB)]

  pause;

  % Sample additional uniformly distributed starting values between LB and UB
  X0 = [X0;sam_sample_uniform_constrained_x0(nStartPoints,LB,UB,linConA,linConB,nonLinCon,solverType)];

  % Save starting values
  fNameX0 = sprintf('x0_%strials_c%s_i%s_p%s.mat',simScope, ...
                  choiceMechType,inhibMechType,condParam);
  save(fullfile(rootDir,sprintf('subj%.2d',iSubj),fNameX0),'X0','tg');

  % Save constraints
  fNameCon = sprintf('constraints_%strials_c%s_i%s_p%s.mat',simScope, ...
                  choiceMechType,inhibMechType,condParam);
  save(fullfile(rootDir,sprintf('subj%.2d',iSubj),fNameCon),'LB','UB','linConA','linConB','nonLinCon');              
end