function [output] = dataCompiler(folderDir,getImpSection)
    % clear console
    clc;
    % Read Classification Table
    [numTable,stringTable,~] = xlsread("MATA-D.xlsx","CREAM Categories");
    % data clean up
    %takes industry and location
    stringTable = stringTable(5:end,2:3);
    splitLocNames = {};
    %remove above columns 2 and 3  
    % leaving # year and CREAM data
    numTable = numTable(:,[1 4:end]);
    %change nan to 0
    numTable(isnan(numTable)) = 0;
    
    % create splitLocNames by removing punctuations and multiple spaces
    for i = 1:size(stringTable,1)
        currentLoc = regexprep(regexprep(stringTable(i,2),'[^0-9a-zA-Z]',' '),' +',' ');
        splitLocNames{i} = strsplit(string(currentLoc{1}),' ');
    end
    
    % read PDFs in Reports folder and ignoreWords.csv
    reports = dir(fullfile(folderDir,"*.pdf"));
    ignoreWordsStruct = readtable("ignoreWords.csv");
    ignoreWords = ignoreWordsStruct.Properties.VariableNames;
    
    % try to match PDFs with Classification Table rows
    docDirectory = {};
    for i = 1:length(reports)
        currentName = reports(i).name;
        splitName = strsplit(currentName,'.');
        currentNameWithoutFormat = char(splitName(1:end-1));
        splitName = strsplit(currentNameWithoutFormat,' ');
        % if ref # is in name beginning
        if(min(isstrprop(splitName{1},'digit')) == 1)
            docDirectory = [docDirectory {splitName{1};string(currentName)}];
            continue;
        % if there is no ref #
        else
            currentNameWithoutFormatAndSpecials = regexprep(currentNameWithoutFormat,'[^0-9a-zA-Z]',' ');
            splitName = strsplit(currentNameWithoutFormatAndSpecials,{' ','-'});

            for j = 1:size(numTable,1)
            matchConfidence = 0;
            wrongYearConfidence = false;

            if contains(lower(currentName),lower(stringTable(j,2)))
                matchConfidence = matchConfidence + 1;
            end

                for k = 1:size(splitName,2)

                    % if there is 4 digits # >1900 <2100, must match
                    if length(regexp(splitName{1,k},'[0-9]')) == 4 == length(splitName(1,k))
                        if 1900 < str2double(splitName(1,k)) && str2double(splitName(1,k)) < 2100
                            if numTable(j,2) == str2double(strtrim(splitName(1,k)))
                                matchConfidence = matchConfidence + 1;
                            else
                                wrongYearConfidence = true;
                            end
                        end
                    end

                    % if words match and not in ignoreWords
                    currentSplitLoc = splitLocNames{1,j};
                    for L = 1:size(currentSplitLoc,2)
                        if strcmpi(currentSplitLoc(L),splitName(k))
                            appearsInIgnoreWords = false;
                            for m = 1:size(ignoreWords,2)
                                if strcmpi(ignoreWords{m},splitName(k))
                                    appearsInIgnoreWords = true;
                                end
                            end
                            if appearsInIgnoreWords == false
                                matchConfidence = matchConfidence + 1;
                            end
                        else
                        end
                    end

                    % majority of PDF name matches bonus
                    if matchConfidence >= size(splitName,2) / 2
                        matchConfidence = matchConfidence + 1;
                    end

                end
                % if match confidence >= threshold, add to output
                if matchConfidence >= 3 && wrongYearConfidence == false
                    docDirectory = [docDirectory {numTable(j,1);string(currentName);matchConfidence}];
                    matchConfidence = 0;
                    continue;
                end
            end
        end
    end

    % Combine doc # and file name with classification info from excel file
    classTable = [];
    docDirectoryInverted = docDirectory';
    validIDs = docDirectoryInverted(:,1);
    for i = 1:size(validIDs,1)
        for j = 1:size(numTable,1)
            if numTable(j,1) == validIDs{i,1}
                classTable = [classTable;numTable(j,3:end)];
            end
        end
    end

    classTable = [docDirectoryInverted(:,1:2) num2cell(zeros(size(classTable,1),1)) num2cell(classTable)];

    % Get text from PDFs using getImportantSection
    debugInfo = {};

    for i = 1:size(classTable,1)
        % for debug
        loadedDoc = "";
        docLength = -1;
        successCheck = true;
        
        % try extractFileText, if there is error, display message
        try
            currentDoc = extractFileText(folderDir + classTable(i,2),'password','');
            loadedDoc = currentDoc;
            docLength = strlength(currentDoc);

            if isempty(currentDoc)
                throw(MException("empty doc"));
            end
        catch
            disp(i + ": " + classTable(i,2) + ": extractFileText failed");

            successCheck = false;
            debugInfo = [debugInfo;{classTable{i,2} loadedDoc docLength successCheck}];

            continue;
        end
        
        % try getImportantSection if getImpSection is true (if false, get entire doc), if there is error, display message
        try
            if getImpSection == true
                imp = getImportantSection(currentDoc);
                classTable{i,3} = strjoin(imp);
            else
                classTable{i,3} = currentDoc;
            end
        catch
            disp(i + ": " + classTable(i,2) + ": getImportantSection failed");

            successCheck = false;
            debugInfo = [debugInfo;{classTable{i,2} loadedDoc docLength successCheck}];

            continue;
        end

        debugInfo = [debugInfo;{classTable{i,2} loadedDoc docLength successCheck}];
    end
    output = classTable;
end