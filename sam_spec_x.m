function XSpec = sam_spec_x(SAM,features)
% SAM_SPEC_X <Synopsis of what this function does> 
%  
% DESCRIPTION 
% <Describe more extensively what this function does> 
%  
% SYNTAX 
% SAM_SPEC_X; 
%  
% EXAMPLES 
%  
%  
% REFERENCES 
%  
% ......................................................................... 
% Bram Zandbelt, bramzandbelt@gmail.com 
% $Created : Wed 29 Jan 2014 13:12:39 CST by bram 
% $Modified: Wed 29 Jan 2014 13:12:39 CST by bram 
 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 1. PROCESS INPUTS
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
 
% % Static variables
% ========================================================================= 

nStruct     = struct('n',[], ...
                     'nCat',[], ...
                     'nCatClass',[]);
freeStruct  = struct('free',[], ...
                     'freeCat',[], ...
                     'freeCatClass',[]);
iStruct     = struct('iCat',[], ...
                     'iCatClass',[]);
nameStruct  = struct('name',[], ...
                     'nameCat',[], ...
                     'nameCatClass',[]);               
XSpec       = struct('nCombi',[], ...
                     'n',nStruct, ...
                     'free',freeStruct, ...
                     'i',iStruct, ...
                     'name',nameStruct);

% % Dynamic variables
% ========================================================================= 

nClass        = size(features,3);

nStm          = SAM.expt.nStm;
nRsp          = SAM.expt.nRsp;
nCnd          = SAM.expt.nCnd;

taskFactors   = [nStm;nRsp;nCnd,nCnd];

included      = SAM.model.XCat.included;

classSpecific = SAM.model.XCat.classSpecific;

nXCat         = SAM.model.XCat.n;

XCatName      = SAM.model.XCat.name;

className     = SAM.model.general.classNames;

iVe           = SAM.model.XCat.i.iVe;

iScale        = SAM.model.XCat.scale.iX;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 2. DETERMINE ALL FACTORIAL COMBINATIONS OF TASK FACTORS
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

nCombi = cell(1,nClass);

for iClass = 1:nClass
  nCombi{iClass} = diag(taskFactors(:,iClass)) * any(features(:,:,iClass),2);
  nCombi{iClass}(nCombi{iClass} == 0) = 1;
  nCombi{iClass} = prod(nCombi{iClass});
end

% Put variables in output structure
XSpec.nCombi  = nCombi;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 3. DETERMINE THE NUMBER OF PARAMETERS
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% Number per task factor, per parameter category, per accumulator class
nCat = zeros(size(features(:,:,1:nClass)));
for iClass = 1:nClass
  nCat(:,:,iClass) = diag(taskFactors(:,iClass)) * features(:,:,iClass);
end
nCat(nCat == 0) = 1;

% Per parameter category, per accumulator class
nCatClass = prod(nCat,1);

% Per parameter category
nCat = sum(nCatClass,3);

% Correct for excluded parameters
nCat(~included) = 1;

% Correct for parameters that are not class-specific
nCat(all(nCatClass == 1,3) & ~classSpecific) = 1;

% Correct Ve for classes that have only one accumulator
nCatClass(:,iVe,nRsp(1:nClass) <= 1) = 0;
nCat(iVe) = sum(nCatClass(:,iVe,:),3);

% Squeeze out redundant dimensions, if any
nCatClass = reshape(nCatClass,nXCat,nClass)';

% Put variables in output structure
XSpec.n.n                = sum(nCat);
XSpec.n.nCat             = nCat;
XSpec.n.nCatClass        = nCatClass;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 4. DETERMINE THE STATE OF PARAMETERS
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% Identify free parameters, per category
freeCat = arrayfun(@(a,b) repmat(a,1,b),included,nCat,'Uni',0);

% Correct for the scaling parameter
freeCat{iScale} = false;

freeCatClass = cell(nClass,nXCat);

for iXCat = 1:nXCat
  if sum(nCatClass(:,iXCat)) == nCat(iXCat)
    freeCatClass(:,iXCat) = mat2cell(true(nCat(iXCat),1),nCatClass(:,iXCat),1);
  elseif XSpec.n.nCat(iXCat) == 1
    freeCatClass(:,iXCat) = repmat(freeCat(iXCat),nClass,1);
  end
end

% Ensure row vectors
freeCatClass = cellfun(@(in1) in1(:)',freeCatClass,'Uni',0);

% Put variables in output structure
XSpec.free.free         = [freeCat{:}];
XSpec.free.freeCat      = freeCat;
XSpec.free.freeCatClass = freeCatClass;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 5. DETERMINE THE INDICES OF PARAMETERS
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% First and last index per parameter category
i1    = [1,cumsum(nCat(1:end-1))+1];
iend  = cumsum(nCat);

% Indices per parameter category
iCat = arrayfun(@(a,b) a:b,i1,iend,'Uni',0);

iCatClass = cell(nClass,nXCat);

for iXCat = 1:nXCat
  if sum(nCatClass(:,iXCat)) == nCat(iXCat)
    iCatClass(:,iXCat) = mat2cell(iCat{iXCat},1,nCatClass(:,iXCat))';
  elseif XSpec.n.nCat(iXCat) == 1
    iCatClass(:,iXCat) = repmat(iCat(iXCat),nClass,1);
  end
end

% Ensure row vectors
iCatClass = cellfun(@(in1) in1(:)',iCatClass,'Uni',0);

% Put variables in output structure
XSpec.i.iCat = iCat;
XSpec.i.iCatClass = iCatClass;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 6. DETERMINE THE NAMES OF PARAMETERS
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

nameCatClass = cell(nClass,nXCat);

for iXCat = 1:nXCat

  if nCat(iXCat) == 1 && all(nCatClass(:,iXCat))
    nameCatClass(:,iXCat) = repmat({sprintf('%s',XCatName{iXCat})},nClass,1);
  elseif nCat(iXCat) == 1 && ~all(nCatClass(:,iXCat))
    nameCatClass(:,iXCat) = repmat({sprintf('%s',XCatName{iXCat})},nClass,1);
    nameCatClass(~nCatClass(:,iXCat),iXCat) = {''};
  elseif nCat(iXCat) == nClass
    fun = @(a) sprintf('%s_{%s}',XCatName{iXCat},a);
    nameCatClass(:,iXCat) = cellfun(fun,className,'Uni',0);
  elseif nCat(iXCat) > nClass
    for iClass = 1:nClass
      % Identify how parameter category varies across task factors
      signature = logical(features(:,iXCat,iClass)); 

      % Temporary variables to keep fun readable
      thisCatName = XCatName{iXCat};  % Parameter category name
      thisClassName = className{iClass};   % Class name

      if isequal(signature,[0 0 0]')
        if nCatClass(iClass,iXCat) == 0
          nameCatClass{iClass,iXCat} = '';
        else
          fun = @(a) sprintf('%s_{%s}',thisCatName,a);
          nameCatClass{iClass,iXCat} = cellfun(fun,className(iClass),'Uni',0);
        end
      else

        combi     = fullfact(taskFactors(signature,iClass))';
        nRow      = size(combi,1);
        nCol      = size(combi,2);
        combiCell = mat2cell(combi,nRow,ones(nCol,1));

        if isequal(signature,[1 0 0]')
          fun = @(a) sprintf('%s_{%s,s%d}',thisCatName,thisClassName,a);
        elseif isequal(signature,[0 1 0]')
          fun = @(a) sprintf('%s_{%s,r%d}',thisCatName,thisClassName,a);
        elseif isequal(signature,[0 0 1]')
          fun = @(a) sprintf('%s_{%s,c%d}',thisCatName,thisClassName,a);
        elseif isequal(signature,[1 1 0]')
          fun = @(a) sprintf('%s_{%s,s%d,r%d}',thisCatName,thisClassName,a);
        elseif isequal(signature,[1 0 1]')
          fun = @(a) sprintf('%s_{%s,s%d,c%d}',thisCatName,thisClassName,a);
        elseif isequal(signature,[0 1 1]')
          fun = @(a) sprintf('%s_{%s,r%d,c%d}',thisCatName,thisClassName,a);
        elseif isequal(signature,[1 1 1]')
          fun = @(a) sprintf('%s_{%s,s%d,r%d,c%d}',thisCatName,thisClassName,a);
        end
        nameCatClass{iClass,iXCat} = cellfun(fun,combiCell,'Uni',0);
      end
    end
  end
end

% Correct for inexisting variables (e.g. ve, in classes without
% response alternatives)
if any(nCatClass == 0)
  nameCatClass{nCatClass == 0} = [];
end

nameCat = cell(1,nXCat);

for iXCat = 1:nXCat
  if sum(nCatClass(:,iXCat)) == nCat(iXCat)
    nameCat{iXCat} = getit(nameCatClass(:,iXCat));
    nameCat{iXCat}(cellfun(@isempty,nameCat{iXCat})) = [];
  elseif XSpec.n.nCat(iXCat) == 1
    nameCat{iXCat} = getit(nameCatClass(1,iXCat));
  end
end

% Put variables in output structure
XSpec.name.name         = [nameCat{:}];
XSpec.name.nameCat      = nameCat;
XSpec.name.nameCatClass = nameCatClass;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 7. SUBFUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [c, sz] = getit(c)
% Extract data from cell arrays containing cell arrays

 if iscell(c)
     d = size(c,2);
     [c, sz] = cellfun(@getit, c, 'UniformOutput', 0);
     c = cat(2,c{:});
     sz = [sz{1} d];
 else
     c = {c};
     sz = [];
 end