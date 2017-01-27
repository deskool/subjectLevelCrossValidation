function [ folds ] = subject_level_cross_validation(data_table, SID_field, outcome_field, time_field, splits_across_time, num_folds, visuals)
%%  WHO WROTE THIS:
% MOHAMMAD M. GHASSEMI,PHD CANDIDATE
% MASSACHUSETTS INSTITUTE OF TECHNOLOGY
% <ghassemi@mit.edu>

%% WHAT DOES IT DO: 
% This function takes a matlab table, and produces subject-level 
% validation folds that are outcome, and time balanced.

%% WHAT DOES IT NEED:
%%%%%%%%%%%%% USER INPUTS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%SID_field,          eg: 'SID'          name of the field with the subject identifier
%outcome_field,      eg: 'bin_outcome'  name of the field with the outcome.
%time_field,         eg: 'TIME'         name of the field with the timestamp.
%splits_across_time, eg: 4              number of temporal quartiles you want to balance data across.
%num_folds,          eg: 10             number of cross validation folds
%visuals,            eg: 1              display stuff (1=Yes, 0=No)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% EXAMPLE:
%Example on how to run it:
%folds  = subject_level_cross_validation(data_table(:,[1:10,15,16,18]),...
%          'SID',...
%          'bin_outcome',...
%          'TIME',...
%          4,...
%          10,...
%          1)

%% CODE STARTS HERE...
%remove rows iwth missing data.
missing_data = ismissing(data_table);
has_data = sum(missing_data,2) == 0;
data_table = data_table(has_data,:);

%%  Get the unique subjects, and their outcomes from the specified fields.

eval(['[subjects, index_of_subjects] = unique(data_table.' SID_field ')']);
eval(['outcomes = data_table.' outcome_field '(index_of_subjects);'])
for i = 1:length(subjects)
    this_subject = subjects(i);
    eval(['data_length(i,1) = max(data_table.' time_field '(data_table.' SID_field '== this_subject));'])
end

if(visuals == 1) % display a histogram of the data.
    figure;histogram(data_length,max(data_length));
    xlabel('The length of the data')
    ylabel('The number of unique subjects')
    title(['Your ' num2str(length(data_length)) ' Unique Subjects'])
end

%% WE ARE GOING TO PARITION THE DATA BY OUTCOME, BY DATA LENGTH...
sinfo.subjects = subjects;
sinfo.outcomes = outcomes;
sinfo.data_length = data_length;

%how many unique outcomes?
outcome_type = unique(sinfo.outcomes);

%get the time bins in quartiles
[time_bins] = prctile(sinfo.data_length,[0:100/splits_across_time:100]);
time_bins(end) = time_bins(end) + 1;

%outcome x time range ...
for i = 1:length(time_bins) - 1
    
    %get the time index ...
    this_time = sinfo.data_length >= time_bins(i) &...
        sinfo.data_length  < time_bins(i+1);
    
    for j = 1:length(outcome_type)
        this_outcome = sinfo.outcomes == outcome_type(j);
        out_time_slots{i,j} = unique(sinfo.subjects(this_time & this_outcome,:));
        nsubs(i,j) = length(out_time_slots{i,j});
    end
    
    
end

if(visuals == 1) % display a histogram of the data.
    figure;
    imagesc(nsubs)
    title(['The distribution of ' num2str(sum(sum(nsubs))) ' subjects data by class and time']);
    xlabel('outcome class');
    ylabel('time slot n-tile');
    colorbar;
end

%% NOW... LET'S GENERATE THE TEN FOLDS...

%compute perc_data to the neraest %.
perc_data = floor(1/num_folds*100)/100;
perc_folds = [0:perc_data:1]*100;

folds = []
for k = 1:length(perc_folds)-1
    %now take n% of the data.
    this_fold = [];
    for i = 1:length(time_bins) - 1
        for j = 1:length(outcome_type)
            take_these = floor(prctile(1:nsubs(i,j),perc_folds(k))): floor(prctile(1:nsubs(i,j),perc_folds(k+1)));
            take_these = take_these(2:end);
            this_fold = [this_fold; out_time_slots{i,j}(take_these)];
        end
    end
    folds(k).test_subjects = this_fold;
    folds(k).train_subjects = setdiff(sinfo.subjects,this_fold);
end


% TEST TO MAKE SURE THAT EVERYTHING WAS RIGHT
if(visuals == 1)
    cumtest = 0; overlap = 0;
    for i = 1:num_folds
        overlap = overlap + length(intersect(folds(1).test_subjects,folds(2).test_subjects));
        cumtest= cumtest + length(folds(i).test_subjects);
    end
    disp(['The total number of unique subjects tested across your ' num2str(num_folds) ' folds is ' num2str(cumtest)]); 
    disp(['The amount of overlap between test fold subjects is ' num2str(overlap) '%']);
end


end

