for iC = 1:2
  for iI = 1:3
    for iP = 1:3
      
      keep iC iI iP
      clc
      
      switch iC
        case 1
          choiceMechType  = 'race';
        case 2
          choiceMechType  = 'li';
      end
      
      switch iI
        case 1
          inhibMechType   = 'race';
        case 2
          inhibMechType   = 'bi';
        case 3
          inhibMechType   = 'li';
      end
      
      switch iP
        case 1
          condParam       = 'v';
        case 2
          condParam       = 't0';
        case 3
          condParam       = 'zc';
      end

      % Adjust the following settings
      % =========================================================================
      simGoal         = 'explore';
      simScope        = 'all';
      iX              = 1;
      solverType      = 'fminsearchcon';

      jobFileName     = sprintf('job_optimize_%strials_c%s_i%s_p%s_iX%.3d.*.mat',simScope,choiceMechType,inhibMechType,condParam,iX);
      % XFileName       = sprintf('finalLog_obs_c%s_i%s_%s_%strials_iX%.3d.*.mat',choiceMechType,inhibMechType,condParam,simScope,iX);

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
          elseif regexp(hostName,'.*vmps')
            rootDir   = '/scratch/zandbeb/sam/';
          else
            error('Unknown host')
          end
      end

      % Keep the following settings fixed
      % =========================================================================

      prd       = cell(1,13);
      modelMat  = cell(1,13);

      % Empty arrays
      % -------------------------------------------------------------------------

      % Structure for logging predicted trial probabilities and response times
      prdData  = struct('P',[],...
                        'rt',[]);

      prdData = repmat({prdData},1,13);                

      % Structure for logging data for optimization
      obsData  = struct('rt',[],...
                        'N',[],...
                        'P',[],...
                        'rtQ',[],...
                        'f',[],...
                        'pM',[]);

      obsData = repmat({obsData},1,13);

      for iSubj = 8:13

        % Load files
        % -------------------------------------------------------------------------

        % Load the job file (SAM)
        load(char(regexpdir(fullfile(rootDir,sprintf('subj%.2d/jobs/',iSubj)),jobFileName)));

      %   % Load the log file
      %   load(char(regexpdir(fullfile(rootDir,sprintf('subj%.2d/fitLogs/',iSubj)),XFileName)));

        % Load the best X file
        XFileName       = sprintf('bestFValX_%strials_c%s_i%s_p%s_subj%.2d.txt',simScope,choiceMechType,inhibMechType,condParam,iSubj)
        X               = importdata(char(regexpdir(fullfile(rootDir,sprintf('subj%.2d/',iSubj)),XFileName)));
        X               = X(2:end); % N.B. first element is Chi-square

        % Load the observations file
        load(fullfile(rootDir,sprintf('subj%.2d/',iSubj),'obs.mat'));


        % Some settings
        % -------------------------------------------------------------------------
        cumProb     = SAM.optim.cumProb;
        minBinSize  = SAM.optim.minBinSize;

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

        %%%%%
        % This is for plotting quantile-averaged data
        %%%%%
        plotSAM.sim.nSim = 2000;

        % Simulate data
        [prd{iSubj},modelMat{iSubj}] = sam_run_job(plotSAM);

        % Characterize observations and comput RT bin stats
        % -------------------------------------------------------------------------

        switch lower(simScope)
          case 'go'

            obsData{iSubj}.N   = [obs.nGo,obs.nGo];
            obsData{iSubj}.P   = [obs.pGoCorr,obs.pGoComm];
            obsData{iSubj}.rt  = [obs.rtGoCorr,obs.rtGoComm];

          case 'all'

            obsData{iSubj}.N   = [obs.nGo,obs.nGo,obs.nStop];
            obsData{iSubj}.P   = [obs.pGoCorr,obs.pGoComm,obs.pStopFailure];
            obsData{iSubj}.rt  = [obs.rtGoCorr,obs.rtGoComm,obs.rtStopFailure];
        end

        [obsData{iSubj}.rtQ, ...         % Quantiles
         obsData{iSubj}.pDefect, ...     % Defective probabilities
         obsData{iSubj}.f, ...           % Frequencies
         obsData{iSubj}.pM] ...          % Probability masses
         = cellfun(@(a,b,c) sam_bin_data(a,b,c,cumProb,minBinSize), ...
         obsData{iSubj}.rt, ...          % Response times
         num2cell(obsData{iSubj}.P), ... % Response probabilities
         num2cell(obsData{iSubj}.N), ... % Response frequencies
         'Uni',0);

        % Characterize observations and compute RT bin stats
        % -------------------------------------------------------------------------
        switch lower(simScope)
          case 'go'
            prdData{iSubj}.P       = [prd{iSubj}.pGoCorr,prd{iSubj}.pGoComm];
            prdData{iSubj}.rt      = [prd{iSubj}.rtGoCorr,prd{iSubj}.rtGoComm];
          case 'all'
            prdData{iSubj}.P       = [prd{iSubj}.pGoCorr,prd{iSubj}.pGoComm,prd{iSubj}.pStopFailure];
            prdData{iSubj}.rt      = [prd{iSubj}.rtGoCorr,prd{iSubj}.rtGoComm,prd{iSubj}.rtStopFailure];
        end

        nSim = SAM.sim.nSim;
        nSimCell = num2cell(nSim*ones(size(prdData{iSubj}.P)));

        prdData{iSubj}.pM  = cellfun(@(a,b,c) histc(a(:),[-Inf,b,Inf])./c,prdData{iSubj}.rt,obsData{iSubj}.rtQ,nSimCell,'Uni',0);
        prdData{iSubj}.pM  = cellfun(@(a) a(1:end-1),prdData{iSubj}.pM,'Uni',0);
        prdData{iSubj}.pM  = cellfun(@(a) a(:),prdData{iSubj}.pM,'Uni',0);


      end

      saveFile = fullfile(rootDir,'qaveragedata',sprintf('qaverage_data_allsubjects_%strials_c%s_i%s_p%s.mat',simScope,choiceMechType,inhibMechType,condParam));
      save(saveFile,'prd','prdData','modelMat','obsData');
      
    end
  end
end

% Plot the RT distributions
% -------------------------------------------------------------------------
% sam_plot_obs_prd(plotSAM,obsData,prdData)
% sam_plot_obs_prd_poster_tryout(plotSAM,obsData,prdData,obs,prd)