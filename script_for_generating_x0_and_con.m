rootDir         = '/Users/bramzandbelt/Documents/PROJECTS/SAM/output/';

iSubj           = 8;
choiceMechType  = 'race';
inhibMechType   = 'race';
condParam       = 'v';
simGoal         = 'optimize';
simScope        = 'go';
solverType      = 'fminsearchcon';
nStartPoints    = 19;

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