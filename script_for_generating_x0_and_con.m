for iSubj = 8:13

choiceMechType  = 'li';
inhibMechType   = 'li';
condParam       = 'zc';
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

% Get bounds and X0
[LB,UB,X0,tg,linConA,linConB,nonLinCon] = sam_get_bnds(choiceMechType,inhibMechType,condParam,simGoal,simScope,solverType,iSubj);

% Check this
[tg;num2cell(X0);num2cell(LB);num2cell(UB)]

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