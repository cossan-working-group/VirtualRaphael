function [output] = preprocess(input)
    %Preprocess/prepare string array for analysis
    output = erasePunctuation(input);
    output = lower(output);
    
    output = tokenizedDocument(output);
    output = removeWords(output,stopWords);
    output = removeShortWords(output,2);
    output = removeLongWords(output,15);
    output = normalizeWords(output);
end

%removes punc/caps/long/short/'stop words'/normalizes and into 'tokens'