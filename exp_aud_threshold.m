function exp_aud_threshold(subid)

%% basic settings

seed = sum(100*clock);
rand('seed', seed);
ListenChar(2);
warning('off', 'all');

%% paths

% define paths ***********
paths.main = fullfile('/Users', 'wpark78', 'Documents', 'code');
paths.tool = fullfile(paths.main, 'tools');
paths.audstim = fullfile(paths.tool, 'aud-stim-generator');
paths.VCC = fullfile(paths.tool, 'VCCToolbox');
paths.project = fullfile(paths.main,'PURA');
paths.result = fullfile(paths.project, 'results_threshold');

% create path if needed
if ~exist(paths.result, 'dir')
    mkdir(paths.result);
    fprintf('Created new folder: %s\n', paths.result);
else
    fprintf('Folder already exists: %s\n', paths.result);
end

% addpath
addpath(paths.audstim);
addpath(paths.VCC);

%% audio

nrchannels = 2;
Fs = 44100;

InitializePsychSound; % Perform basic initialization of the sound driver
pahandle = PsychPortAudio('Open', [], [], 0, Fs, nrchannels);

%% stimulus 

paud.Fs = Fs;
paud.Fc = 400; % Hz
paud.phi = 0; % phase
paud.dur = .07; % sec
paud.RiseFallDur = .005; % sec
paud.orbital = 1;
paud.silence = .03; 
paud.itd = 1;
paud.ild = 1;
paud.doppler = 0;
paud.inverseSquareLaw = 1;

%% conditions

stim.depth = 0.57; % meter *********** distance b/w participant and monitor
stim.eccentricity = 10; % deg ***********

% staircase settings
nsc = 2; % number of staircases
n_trials_per_sc = [48 48]; % ***********
updown = [1 2; 1 2];
stepsize1 = 1; 
stepsize2 = 0.5;
beginvalue = [10 11];

% labels
labels.soundOrders = {'LR','RL'};     % first burst location -> second
labels.hemifields = {'left','right'};

% conditions
hemifields  = 1:length(labels.hemifields);

% staircases
for hemi = hemifields
    for s = 1:nsc
        % sc = staircase('create', [up down], [min max], nTrials, nReversals, linStep);
        sc(hemi,s) = staircase('create', updown(s,:), [0.001 20], n_trials_per_sc(s), [], stepsize1);
        sc(hemi,s).stimVal = beginvalue(s);
        sc(hemi,s).step = [stepsize1 stepsize1];
    end
end

% emat
condMat = expmat(hemifields, 1:nsc);
condMat = repmat(condMat, [n_trials_per_sc(1), 1]);
[eseq, condMat] = randseq(condMat);
total_trials = length(eseq);

feedback = 1; % beep if correct
trialsperblock = n_trials_per_sc(1) * 2; % for break
breakdur = 30; % sec

%% keyboard settings

keyboardnum = -3;
ApplyKbFilter; 

%% experiment

disp('press any key to begin');
KbWait(keyboardnum,3);
WaitSecs(0.5);

% results columns:
% 1 Trial, 2 Hemifield, 3 SC, 4 SoundOrder, 5 DegOffset, 6 Response, 7 RT(s), 8 Correct
results = cell(total_trials, 7);

try
    for seq = eseq
    
        % trial info
        which_trial = condMat(seq,1);
        which_hemi = condMat(seq,2);
        which_sc = condMat(seq,3);
    
        % choose direction 
        which_dir = round(rand(1)) + 1;
    
        % labels
        hemiLab = labels.hemifields{which_hemi};
        orderLab = labels.soundOrders{which_dir};
    
        % get sc suggestion
        degOffset = sc(which_hemi, which_sc).stimVal;

        % display
        fprintf('Trial %d: Hemi=%s, SC=%d, DegOffset=%d / ',  ...
            which_trial, hemiLab, which_sc, degOffset);
    
        % coordinates 
        if strcmpi(hemiLab, 'left')
            metEccent = -stim.depth * tand(stim.eccentricity); 
        else
            metEccent = stim.depth * tand(stim.eccentricity); 
        end
        
        metOffset = stim.depth * tand(degOffset); 
        
        paudL = paud;
        paudL.startxy = [metEccent - metOffset, stim.depth];
        paudL.endxy = [metEccent - metOffset, stim.depth];
        paudR = paud;
        paudR.startxy = [metEccent + metOffset, stim.depth];
        paudR.endxy = [metEccent + metOffset, stim.depth];
        
        [xx_audL, yy_audL] = MakeTrajectory(paudL);
        [xx_audR, yy_audR] = MakeTrajectory(paudR);
    
        % make sound
        audL = MakePureTone(paudL);
        audL = auditoryCueIntegrator(paudL, audL, xx_audL, yy_audL);
        audL = RiseFall(paudL, audL);
        audR = MakePureTone(paudR);
        audR = auditoryCueIntegrator(paudR, audR, xx_audR, yy_audR);
        audR = RiseFall(paudR, audR);
        silence = zeros(round(paud.silence*paud.Fs), 2);
        
        % sound order
        if strcmpi(orderLab, 'LR')
            burst1 = audL;
            burst2 = audR;
        else
            burst1 = audR;
            burst2 = audL;
        end
        
        % combine
        playthis = [burst1; silence; burst2];
        PsychPortAudio('FillBuffer', pahandle, playthis');
    
        % play 
        PsychPortAudio('FillBuffer', pahandle, playthis');
        PsychPortAudio('Start', pahandle, 1, 0, 1);
        WaitSecs(paud.dur + paud.silence + paud.dur);
        soundStartSec = GetSecs;
    
        % response
        resp.response = 'none'; 
        resp.RT = NaN;
        KbName('UnifyKeyNames');
        leftKeys  = [KbName('LeftArrow'),  KbName('l')]; 
        rightKeys = [KbName('RightArrow'), KbName('r')];
    
        while true
            if checkForEscape()
                error('ESC pressed');
            end
            [down, ts, kc] = KbCheck(-3);
            if down
                if any(kc(leftKeys))
                    resp.response = 'left';
                    resp.RT = ts - soundStartSec;
                    break;
                elseif any(kc(rightKeys))
                    resp.response = 'right';
                    resp.RT = ts - soundStartSec;
                    break;
                end
            end
        end
        if orderLab(2) == 'R'
            correctAns = 'right';
        else
            correctAns = 'left';
        end
        resp.correct = strcmp(resp.response, correctAns); 
        if feedback
            if resp.correct == 1
                Beeper(880, 0.2, 0.08);
                disp('correct');
            else
                disp('incorrect');
            end
        end
        WaitSecs(0.4); 
    
        % record
        results{which_trial, 1} = which_trial; 
        results{which_trial, 2} = hemiLab;
        results{which_trial, 3} = which_sc;
        results{which_trial, 4} = orderLab;
        results{which_trial, 5} = degOffset;
        results{which_trial, 6} = resp.response; 
        results{which_trial, 7} = resp.RT;
        results{which_trial, 8} = resp.correct;
    
        % update staircase
        sc(which_hemi, which_sc) = staircase('update', sc(which_hemi, which_sc), resp.correct);
        if sum(~isnan(sc(which_hemi, which_sc).reversal)) > 2
            sc(which_hemi, which_sc).step = [stepsize2 stepsize2];
        else
            sc(which_hemi, which_sc).step = [stepsize1 stepsize1];
        end
    
        % break
        if rem(which_trial,trialsperblock)==0 && which_trial ~=total_trials 
    
            % break begin signal
            Snd('Play',sin((1:1000)/20));
            WaitSecs(.5)
            Snd('Play',sin((1:1000)/20));
            WaitSecs(.5)
            Snd('Play',sin((1:1000)/20));
            
            % break countdown
            disp('break');
            WaitSecs(breakdur);
            
            % break end signal
            Snd('Play',sin((1:1000)/4));
            WaitSecs(.5)
            Snd('Play',sin((1:1000)/4));
            WaitSecs(.5)
            Snd('Play',sin((1:1000)/4));
            
            disp('press any key to begin');
            KbWait(keyboardnum,3);
            WaitSecs(0.5);
    
        end
    
    end
catch ME
    saveResultsCSV_threshold(results, subid);
    PsychPortAudio('Close', pahandle);
    ListenChar(1);
    ShowCursor;
    rethrow(ME);
end

% plot and get thresholds 
nDiscard = 2;
temp_thresh = [];
figid = 1;
for which_hemi = hemifields
    for which_sc = 1:nsc
        figure(figid);
        sc(which_hemi, which_sc) = staircase('plot', sc(which_hemi, which_sc));
        sc(which_hemi, which_sc) = staircase('compute', sc(which_hemi, which_sc), nDiscard);
        disp(sc(which_hemi, which_sc).result);
        temp_thresh = [temp_thresh; sc(which_hemi, which_sc).threshold(1)];
        figid = figid+1;
    end
end
avg_thresh = mean(temp_thresh);
disp(['average threshold = ', num2str(avg_thresh)]);

% save filename and path
fname = sprintf([subid, '_threshold_results_%s'], datestr(now,'yyyymmdd_HHMMSS'));
savename = fullfile(paths.result, fname);

% save variables
save([savename, '.mat'], 'condMat', 'paud', 'sc', 'labels', 'stim', 'seed', 'paths', 'avg_thresh');

% save csv
saveResultsCSV_threshold(results, [savename, '.csv']);

% close
PsychPortAudio('Close', pahandle);
ListenChar(1);
ShowCursor;


end






