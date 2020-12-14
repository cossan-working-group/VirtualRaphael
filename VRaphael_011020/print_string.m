
function [output, Tdat] =print_string(X)

%   path = 'M:\01-Year 1\11-journals\03-text_mining_machine-learning\Incident Report Classifier_v1\';
    %%%path = 'C:\Users\cmorais\Desktop\IncidentReportClassifier_v1\';%insert path name
    %%%%path = '/Users/KarlJohnson/Documents/MATLAB/IncidentReportClassifier_v1_4Sep20\';
    %%%string = [path,'Copy_ClassTable.xlsx'];
    
    [N,T] = xlsread('Copy_ClassTable.xlsx','CREAM Categories');
    
    [inds_r,inds_c] = find(contains(T,'Wrong Time'));
    [inde_r,inde_c] = find(contains(T,'Irregular working hours'));
    
    Labels = T(inds_r:inde_r,inds_c:inde_c);
    
    output{1,1} = 'Array of model predicted factors:';
    for i = 1:length(X)
        Labels{i} = regexprep(Labels{i}, ' ', '_');
        if X(i)>0
            output{end+1,1} = Labels{i};
       end 
    end

    Tdat = array2table(X','VariableNames',Labels);

    fprintf(1, '%s \n ',output{:})
 return