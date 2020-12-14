function [outputSection] = getImportantSection(inputDocument)
    % split input doc line by line
    lineArray = strsplit(inputDocument,'\n');
    
    % words and phrases that indicate the start of target sections
    % target words are very sensitive, undesirable results may occur if
    % changed
    startTargetWords = ["recommendation" "lessons learned" "advice to planning authorities"];
    
    % words and phrases that indicate the end of target sections
    endTargetWords = ["reference" "appendix" "annex" "list of" "conclusion" ...
        "bibliography" "works cited" "introduction" "board member statements" ...
        "executive summary" "abbreviations and acronyms"];
    
    % words that less likely to indicate the end of target sections
    lesserEndTargetWords = ["accordingly" "section" "chapter" "attachment" "concluding" "figure"];
    
    % calls sub-method to get possible section starts and respective confidence values
    % see near bottom of file for definition
    [startLineNumsAndConfidence] = searchForLineNumsAndConfidence(lineArray,startTargetWords,[]);
    
    % calls sub-method to get possible section ends and confidence values
    [endLineNumsAndConfidence] = searchForLineNumsAndConfidence(lineArray,endTargetWords,lesserEndTargetWords);
    
    % get rows of the same highest confidence values
    startRows = getMaxRows(startLineNumsAndConfidence,2);
    
    % for each possible start rows, find best end row
    for i = 1:size(startRows,1)
        endsForCurrentStart = [];
        if ~isempty(endLineNumsAndConfidence)
            % only consider end rows after the current start row
            possibleEndIndices = endLineNumsAndConfidence(:,1) > startRows(i,1);
            possibleEnds = endLineNumsAndConfidence(possibleEndIndices,:);
            
            % get indices of end rows with confidence > 4
            endsForCurrentStartIndices = possibleEnds(:,2) > 4;
            if ~isempty(endsForCurrentStartIndices)
                % if exists conf > 4, get them
                endsForCurrentStart = possibleEnds(endsForCurrentStartIndices,:);
            else
                % if none, find conf > 2
                endsForCurrentStartIndices = possibleEnds(:,2) > 2;
                endsForCurrentStart = possibleEnds(endsForCurrentStartIndices,:);
            end
        end
        
        if isempty(endsForCurrentStart)
            % if still none, get end of document
            startRows(i,4) = size(lineArray,2);
        else
            % if likely end exists, get closest one
            startRows(i,4) = endsForCurrentStart(1,1) - 1;
        end
        
        % calculate # of characters between start and end rows
        startRows(i,5) = 0;
        for j = startRows(i,1):startRows(i,4)
            startRows(i,5) = startRows(i,5) + strlength(lineArray(j));
        end
    end
    
    % search for likely "table of contents" lines and confidence values
    [tableOfContentsNumsAndConfidence] = searchForLineNumsAndConfidence(lineArray,["table of content"],["content"]);
    
    % remove considerations of start rows close to likely table of content rows
    if ~isempty(tableOfContentsNumsAndConfidence)
        % get ToC rows with conf > 2
        likelyToC_indices = tableOfContentsNumsAndConfidence(:,2) > 2;
        likelyToC = tableOfContentsNumsAndConfidence(likelyToC_indices,:);
        
        % store in array start rows within 20 lines of likely ToC lines
        startRowsToRemove = [];
        for i = 1:size(startRows,1)
            for j = 1:size(likelyToC,1)
                if likelyToC(j,1) < startRows(i,1) && likelyToC(j,1) + 20 > startRows(i,1)
                    startRowsToRemove = [startRowsToRemove i];
                end
            end
        end
        % remove appropriate lines
        startRows(startRowsToRemove,:) = [];
    end
    
    % get longest likely section's start, end line #s
    longestPossibleSectionsInfo = getMaxRows(startRows,5);
    finalStartLineNum = longestPossibleSectionsInfo(end,1);
    finalEndLineNum = longestPossibleSectionsInfo(end,4);
    
    % output section
    outputSection = lineArray(finalStartLineNum:finalEndLineNum);
end

function [lineNumsAndConfidence] = searchForLineNumsAndConfidence(lineArray,targetWords,lesserTargetWords)
lineNumsAndConfidence = [];

    for i = 1:size(lineArray,2)
        % get current line, only consider letters, numbers, "-", ",", "."
        currentLineArray = regexp(lower(lineArray(i)),'[a-zA-Z0-9-,.]+','match');
        currentLine = strjoin(currentLineArray);
        currentLineLength = strlength(currentLine);
        
        targetWordsConfidence = 0;
        lesserTargetWordsConfidence = 0;
        numTargetWordsOccur = 0;
        numLesserTargetWordsOccur = 0;
        
        for j = 1:size(targetWords,2)
            targetWordLength = strlength(targetWords(1,j));
            % if current line contains current target, confidence = 2
            if contains(currentLine,targetWords(1,j))
                numTargetWordsOccur = numTargetWordsOccur + 1;
                targetWordsConfidence = targetWordsConfidence + 2;
                
                % 0 if target word accounts <25% of line length
                if targetWordLength/currentLineLength < 0.25
                    targetWordsConfidence = 0;
                end
                
                % +1 if target word accounts >50% of line length
                if targetWordLength/currentLineLength > 0.5
                    targetWordsConfidence = targetWordsConfidence + 1;
                    
                    % +1 if target word is "appendix" and a letter follows
                    if strcmp(targetWords(1,j),"appendix") && length(currentLineArray) >= 2 && strlength(currentLineArray(2)) == 1
                        targetWordsConfidence = targetWordsConfidence + 1;
                    end
                end
                
                % another +1 if target word accounts >70% of line length
                if targetWordLength/currentLineLength > 0.7
                    targetWordsConfidence = targetWordsConfidence + 1;
                end
                
                % +1 if there is a possible section # in front
                if isempty(regexp(currentLineArray(1),'[^0-9.]', 'once')) && ~isempty(regexp(currentLineArray(1),'[0-9]+[.]+', 'once')) && contains(currentLineArray(2),targetWords(1,j))
                    targetWordsConfidence = targetWordsConfidence + 1;
                end
            end
        end
        
        % 0 conf if more than 1 target words
        if numTargetWordsOccur > 1
            targetWordsConfidence = 0;
        end
        
        for j = 1:size(lesserTargetWords,2)
            targetWordLength = strlength(lesserTargetWords(1,j));

            if contains(currentLine,lesserTargetWords(1,j))
                numLesserTargetWordsOccur  = numLesserTargetWordsOccur + 1;
                lesserTargetWordsConfidence = lesserTargetWordsConfidence + 1;
                
                % 0 if target word accounts <25% of line length
                if targetWordLength/currentLineLength < 0.25
                    lesserTargetWordsConfidence = 0;
                end
                
                % +1 if target word accounts >50% of line length
                if targetWordLength/currentLineLength > 0.5
                    lesserTargetWordsConfidence = lesserTargetWordsConfidence + 1;
                    
                    % +1 if target word is "appendix" and a letter follows
                    if strcmp(targetWords(1,j),"appendix") && length(currentLineArray) >= 2 && strlength(currentLineArray(2)) == 1
                        targetWordsConfidence = targetWordsConfidence + 1;
                    end
                end

                % another +1 if target word accounts >75% of line length
                if targetWordLength/currentLineLength > 0.75
                    lesserTargetWordsConfidence = lesserTargetWordsConfidence + 1;
                end
                
                % +1 if there is a section #
                if isempty(regexp(currentLineArray(1),'[^0-9.]', 'once')) && ~isempty(regexp(currentLineArray(1),'[0-9]+[.]+', 'once')) && contains(currentLineArray(2),targetWords(1,j))
                    targetWordsConfidence = targetWordsConfidence + 1;
                end
            end
        end
        
        % conf = 0 if more than 1 target words
        if numLesserTargetWordsOccur > 1
            lesserTargetWordsConfidence = 0;
        end
        
        confidence = targetWordsConfidence + lesserTargetWordsConfidence;
        
        if confidence > 0
            % +1 if previous line has no letters
            if i ~= 1 && isempty(regexp(lineArray(i - 1),'[a-zA-z]','match'))
                confidence = confidence + 1;
            end

            % +1 if next line has no letters
            if i ~= size(lineArray,2) && isempty(regexp(lineArray(i + 1),'[a-zA-z]','match'))
                confidence = confidence + 1;
            end

            % 0 confidence if line contains anything besides letters, numbers,
            % ",", ".", "-"," ","_"
            if ~isempty(regexp(currentLine,'[^a-zA-Z0-9,.- _]','match'))
                confidence = 0;
            end
            
            % add to array if conf > 0
            if confidence > 0
                lineNumsAndConfidence = [lineNumsAndConfidence;[i confidence]];
            end
        end
    end
end

% simple method to get all rows of the highest value in a certain column
function [maxRows] = getMaxRows(array,columnToJudge)
    if size(array,1) <= 1
        maxRows = array;
    else
        maxValues = max(array);
        maxValue = maxValues(1,columnToJudge);
        maxIndices = array(:,columnToJudge) == maxValue;
        maxRows = array(maxIndices,:);
    end
end