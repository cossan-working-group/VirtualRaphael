function [Accuracy,Precision,Recall,F1Score] = accmetrics(x,y)

% calculate various acc metrics
TrueP=0;
TrueN=0;
FalseP=0;
FalseN=0;
for i = 1:size(x,1)
for j= 1:size(x,2)
if x(i,j)==1
    if y(i,j)==1
        TrueP=TrueP+1;
        else
        FalseP=FalseP+1;
    end
elseif x(i,j)==0
    if y(i,j)==0
TrueN=TrueN+1;
else
FalseN=FalseN+1;
end
end 
end
end

Accuracy = (TrueP+TrueN)/(TrueP+TrueN+FalseP+FalseN);
Precision =TrueP/(TrueP+FalseP);
Recall= TrueP/(TrueP+FalseN);
F1Score=2*(Precision*Recall)/(Precision+Recall);
end