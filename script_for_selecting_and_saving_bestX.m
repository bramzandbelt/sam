for iSubj = 8:13

  keep iSubj;close all;clc;

  choiceMechType  = 'race';
  inhibMechType   = 'race';
  condParam       = 'v';
  simGoal         = 'optimize';
  simScope        = 'all';
  solverType      = 'fminsearchcon';

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

  srcDir          = fullfile(rootDir,sprintf('subj%.2d/fitLogs/',iSubj))
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
  allBestFits = sortrows(allBestFits,[2,3])

  allBestFits(1,:)

  % Save as ASCII text
  fValX = allBestFits(1,3:end);
  FValXFName = fullfile(rootDir,sprintf('subj%.2d',iSubj),sprintf('bestFValX_%strials_c%s_i%s_p%s_subj%.2d.txt',simScope,choiceMechType,inhibMechType,condParam,iSubj));
  save(FValXFName,'fValX','-ascii');

end