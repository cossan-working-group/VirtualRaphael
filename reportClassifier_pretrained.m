load 'SavedModel.mat'

uploads =  uigetfile('*.pdf','Select Report for Classification');
temp = uploads;
temp = extractFileText(temp);

size_tmp = size(temp);
N_rows_file = size_tmp(2);

str=strjoin(temp);
documentsNew = preprocess(str);

for j = 1:size(mdlArray,1)
    XNew = encode(bags{1,1},documentsNew);
    labelsNew = predict(mdlArray{j},XNew);
    result1(j,:) = labelsNew;
end

[Out, Tdat] = print_string(result1);
OutString = string(Out(2:end,1));
OutString = strrep(OutString,'_',' ');

[Accuracy,Precision,Recall,F1Score]=accmetrics(YPreds,YTest);
AccuracyString={};
AccuracyString = {'Accuracy';Accuracy;'Precision';Precision;'Recall';Recall;'F1Score';F1Score}
AccuracyString=string(AccuracyString);

[parentdir,~,~]=fileparts(pwd);
 savepath = pwd;
addpath(savepath);

fid = fopen([savepath +  "/"+'factors.txt'],'wt');
fprintf(fid, '%s\n', OutString);
fclose(fid);

fid2 = fopen([savepath + "/"+'accuracies.txt'],'wt');
fprintf(fid2, '%s\n', AccuracyString);
fclose(fid2);