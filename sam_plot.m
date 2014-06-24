function sam_plot(SAM,prd);

obs = SAM.optim.obs;

trialCat    = SAM.optim.obs.trialCat;
nTrialCat   = size(trialCat,1);

nHorPanel = 4;

% Set up panel
% figure('units','normalized','outerposition',[0 0 1 1]);
p = panel();
p.pack(ceil(nTrialCat/nHorPanel),nHorPanel);

plotType = 'normal';


for iTrialCat = 1:nTrialCat
    
    if ~isempty(regexp(trialCat{iTrialCat},'goTrial.*', 'once'))
        
        % Numbers
        nTotalPrd                       = prd.nTotal(iTrialCat);
        nGoCCorrPrd                     = prd.nGoCCorr(iTrialCat);
        nGoCErrorPrd                    = prd.nGoCError(iTrialCat);
        
        nGoCCorrObs                     = obs.nGoCCorr(iTrialCat);
        nGoCErrorObs                    = obs.nGoCError(iTrialCat);
        
        % Trial probabilities
        pGoCCorrPrd                     = prd.pGoCCorr(iTrialCat);
        pGoCErrorPrd                    = prd.pGoCError(iTrialCat);
        
        pGoCCorrObs                     = obs.pGoCCorr(iTrialCat);
        pGoCErrorObs                    = obs.pGoCError(iTrialCat);
        
        % Reaction times
        switch lower(plotType)
            case 'normal'
                rtGoCCorrPrd                    = prd.rtGoCCorr{iTrialCat};
                rtGoCErrorPrd                   = prd.rtGoCError{iTrialCat};
            case 'defective'
                rtGoCCorrPrd                    = nan(nTotalPrd,1);
                rtGoCCorrPrd(1:nGoCCorrPrd)     = prd.rtGoCCorr{iTrialCat};
                rtGoCErrorPrd                   = nan(nTotalPrd,1);
                rtGoCErrorPrd(1:nGoCErrorPrd)   = prd.rtGoCError{iTrialCat};
        end
        
        rtQGoCCorrObs                   = obs.rtQGoCCorr{iTrialCat};
        rtQGoCErrorObs                  = obs.rtQGoCError{iTrialCat};
        
        % Probabilities
        switch lower(plotType)
            case 'normal'
                cumProbGoCCor          = obs.cumProbGoCCorr{iTrialCat};
                cumProbGoCError        = obs.cumProbGoCError{iTrialCat};
            case 'defective'
                cumProbGoCCor          = obs.cumProbDefectiveGoCCorr{iTrialCat};
                cumProbGoCError        = obs.cumProbDefectiveGoCError{iTrialCat};
        end
        
        % Plot
        [iColumn,iRow] = ind2sub([nHorPanel,ceil(nTrialCat/nHorPanel)],iTrialCat);
        p(iRow,iColumn).select();
        p(iRow,iColumn).hold('on');
        
        % Predictions as lines
        if ~isempty(rtQGoCCorrObs)
            plot(rtGoCCorrPrd,cmtb_edf(rtGoCCorrPrd(:),rtGoCCorrPrd(:)),'Color','k','LineStyle','-');
        end
        
        if ~isempty(rtQGoCErrorObs)
            plot(rtGoCErrorPrd,cmtb_edf(rtGoCErrorPrd(:),rtGoCErrorPrd(:)),'Color','k','LineStyle','--');
        end
        
        % Observations as circles
        if ~isempty(rtQGoCCorrObs)
            plot(rtQGoCCorrObs,cumProbGoCCor,'ko');
        end
        
        if ~isempty(rtQGoCErrorObs)
            plot(rtQGoCErrorObs,cumProbGoCError,'kd');
        end
        
        % Print trial probabilities
        fprintf(1,'GoCCorrObs = %.2f, GoCCorrPrd = %.2f \n',pGoCCorrObs,pGoCCorrPrd);
        fprintf(1,'GoCErrorObs = %.2f, GoCErrorPrd = %.2f \n',pGoCErrorObs,pGoCErrorPrd);
        
    elseif ~isempty(regexp(trialCat{iTrialCat},'stopTrial.*', 'once'))
        
        % Numbers
        nTotalPrd                       = prd.nTotal(iTrialCat);
        nStopICorr                      = prd.nStopICorr(iTrialCat);
        nStopIErrorCCorr                = prd.nStopIErrorCCorr(iTrialCat);
        nStopIErrorCError               = prd.nStopIErrorCError(iTrialCat);
        
        % Trial probabilities
        pStopICorrPrd                   = prd.pStopICorr(iTrialCat);
        pStopIErrorCCorrPrd             = prd.pStopIErrorCCorr(iTrialCat);
        pStopIErrorCErrorPrd            = prd.pStopIErrorCError(iTrialCat);
        
        pStopICorrObs                   = obs.pStopICorr(iTrialCat);
        pStopIErrorCCorrObs             = obs.pStopIErrorCCorr(iTrialCat);
        pStopIErrorCErrorObs            = obs.pStopIErrorCError(iTrialCat);
        
        
        % Reaction times
        switch lower(plotType)
            case 'normal'
                rtStopICorr                                 = prd.rtStopICorr{iTrialCat};
                rtStopIErrorCCorr                           = prd.rtStopIErrorCCorr{iTrialCat};
                rtStopIErrorCError                          = prd.rtStopIErrorCError{iTrialCat};
            case 'defective'
                rtStopICorr                                 = nan(nTotalPrd,1);
                rtStopICorr(1:nStopICorr)                   = prd.rtStopICorr{iTrialCat};
                rtStopIErrorCCorr                           = nan(nTotalPrd,1);
                rtStopIErrorCCorr(1:nStopIErrorCCorr)       = prd.rtStopIErrorCCorr{iTrialCat};
                rtStopIErrorCError                          = nan(nTotalPrd,1);
                rtStopIErrorCError(1:rtStopIErrorCError)    = prd.rtStopIErrorCError{iTrialCat};
        end
        
        rtQStopIErrorCCorr                   = obs.rtQStopIErrorCCorr{iTrialCat};
        rtQStopIErrorCError                  = obs.rtQStopIErrorCError{iTrialCat};
        
        % Probabilities
        switch lower(plotType)
            case 'normal'
                cumProbStopIErrorCCorr          = obs.cumProbStopIErrorCCorr{iTrialCat};
                cumProbStopIErrorCError        = obs.cumProbStopIErrorCError{iTrialCat};
            case 'defective'
                cumProbStopIErrorCCorr          = obs.cumProbDefectiveStopIErrorCCorr{iTrialCat};
                cumProbStopIErrorCError        = obs.cumProbDefectiveStopIErrorCError{iTrialCat};
        end
        
        % Plot
        
        [iColumn,iRow] = ind2sub([nHorPanel,ceil(nTrialCat/nHorPanel)],iTrialCat);
        p(iRow,iColumn).select();
        p(iRow,iColumn).hold('on');
        
        % Predictions as lines
        if nStopICorr > 0
            plot(rtStopICorr,cmtb_edf(rtStopICorr(:),rtStopICorr(:)),'Color','k','LineStyle','-.');
        end
        
        if nStopIErrorCCorr > 0
            plot(rtStopIErrorCCorr,cmtb_edf(rtStopIErrorCCorr(:),rtStopIErrorCCorr(:)),'Color','k','LineStyle','-');
        end
        
        if nStopIErrorCError > 0
            plot(rtStopIErrorCError,cmtb_edf(rtStopIErrorCError(:),rtStopIErrorCError(:)),'Color','k','LineStyle','--');
        end
        
        % Observations as circles
        if nStopIErrorCCorr > 0
            plot(rtQStopIErrorCCorr,cumProbStopIErrorCCorr,'ko');
        end
        
        if nStopIErrorCError > 0
            plot(rtQStopIErrorCError,cumProbStopIErrorCError,'kd');
        end
        
        
        % Print trial probabilities
        fprintf(1,'StopICorrObs = %.2f, StopICorrPrd = %.2f \n',pStopICorrPrd,pStopICorrObs);
        fprintf(1,'StopIErrorCCorr = %.2f, StopIErrorCCorr = %.2f \n',pStopIErrorCCorrObs,pStopIErrorCCorrPrd);
        fprintf(1,'StopIErrorCError = %.2f, StopIErrorCError = %.2f \n',pStopIErrorCErrorObs,pStopIErrorCErrorPrd);
        
    end
            

  
%   rtPrdCorr               = nan(nTotalPrd,1);
%   rtPrdCorr(1:nPrdCorr)   = prd.rtCorr{iTrialCat};
%   rtPrdError              = nan(nTotalPrd,1);
%   rtPrdError(1:nPrdError) = prd.rtError{iTrialCat};
%   
%   nObsCorr                = obs.nCorr(iTrialCat);
%   nObsError               = obs.nError(iTrialCat);
%   
%   rtQObsCorr              = obs.rtQCorr{iTrialCat};
%   rtQObsError             = obs.rtQError{iTrialCat};
%   pDefectiveObsCorr       = obs.pDefectiveCorr{iTrialCat};
%   pDefectiveObsError      = obs.pDefectiveError{iTrialCat};
%   
%   % Plot
%   [iColumn,iRow] = ind2sub([nHorPanel,ceil(nTrialCat/nHorPanel)],iTrialCat);
%   p(iRow,iColumn).select();
%   p(iRow,iColumn).hold('on');
%   
%   % Predictions as lines
%   plot(rtPrdCorr,cmtb_edf(rtPrdCorr,rtPrdCorr),'Color','k','LineStyle','-');
%   plot(rtPrdError,cmtb_edf(rtPrdError,rtPrdError),'Color','k','LineStyle','--');
%   
%   % Observations as circles
%   plot(rtQObsCorr,pDefectiveObsCorr,'ko');
%   plot(rtQObsError,pDefectiveObsError,'kd');
%   
  % Set title
  title(obs.trialCat{iTrialCat});
  set(gca,'PlotBoxAspectRatio',[1.61,1,1],'XLim',[0 2000],'YLim',[0 1]);
    % Legend
%   legend(sprintf('Corr(N_O=%d,N_P=%d)',nObsCorr,nPrdCorr),sprintf('Error(N_O=%d,N_P=%d)',nObsError,nPrdError));
  
end