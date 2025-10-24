
function resp = SingleTrial(display, pahandle, stim, paud, fractalLab, hemiLab, orderLab, gazeLab)


% match frames to cues 
flashFrames = 1:round(stim.dur.fractalFlash * stim.rate);
expansionFrames = flashFrames(end)+1:flashFrames(end)+stim.expansionframes;
waitFrames = expansionFrames(end)+1:expansionFrames(end)+round(stim.dur.wait*stim.rate);
totalFrames = waitFrames(end);

% create texture
fractalTexturesFlash = cell(1, totalFrames);
for i = 1:totalFrames
    pink = GeneratePinkNoise(stim.baseSize);               
    fractalTexturesFlash{i} = Screen('MakeTexture', display.windowPtr, pink);
end

% take care of expansion
pink = GeneratePinkNoise(stim.baseSize);
baseTex = Screen('MakeTexture', display.windowPtr, pink);
fractalTexturesRepeat = repmat({baseTex}, 1, stim.expansionframes);
if strcmpi(fractalLab, 'expand')
    zoomLevels = linspace(1, stim.expansionfactor, stim.expansionframes);
else
    zoomLevels = linspace(stim.expansionfactor, 1, stim.expansionframes);
end

% sound probe 

% coordinates (meters)
depth = display.dist/100; % meter
if strcmpi(hemiLab, 'left')
    metEccent = -depth * tand(stim.eccentricity); 
else
    metEccent = depth * tand(stim.eccentricity); 
end

metOffset = depth * tand(stim.degOffset); 

paudL = paud;
paudL.startxy = [metEccent - metOffset, depth];
paudL.endxy = [metEccent - metOffset, depth];
paudR = paud;
paudR.startxy = [metEccent + metOffset, depth];
paudR.endxy = [metEccent + metOffset, depth];

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

% fixation location 
if strcmpi(gazeLab, 'at')
    if strcmpi(hemiLab, 'left')
        gazeXY = [display.center(1) - stim.eccentricity * display.pixPerDeg, display.center(2)];
    else
        gazeXY = [display.center(1) + stim.eccentricity * display.pixPerDeg, display.center(2)];
    end
else
    if strcmpi(hemiLab, 'left')
        gazeXY = [display.center(1) + stim.eccentricity * display.pixPerDeg, display.center(2)];
    else
        gazeXY = [display.center(1) - stim.eccentricity * display.pixPerDeg, display.center(2)];
    end
end

% fixation 
Screen('DrawDots', display.windowPtr, gazeXY, angle2pix(display,display.fixation.size), display.fixation.color{1}, [], 2); 
Screen('Flip', display.windowPtr);
WaitSecs(stim.dur.fixation);

% texture loop
flipWhen = Screen('Flip', display.windowPtr);
for frame = 1:totalFrames
    
    if checkForEscape()
        error('ESC pressed');
    end

    % select texture
    tex = fractalTexturesFlash{frame};
    srcRect = [];
    dstRect = stim.baseRect;

    % zoom & play sound
    if ismember(frame, expansionFrames)
        idx = frame - expansionFrames(1) + 1;
        if ~strcmpi(fractalLab, 'neutral')
            tex = fractalTexturesRepeat{idx};
            texRect = Screen('Rect', tex);
            [texW, texH] = RectSize(texRect);
            zoom = zoomLevels(idx);   
            cropW = texW / zoom;
            cropH = texH / zoom;
            srcRect = CenterRectOnPoint([0 0 cropW cropH], texW/2, texH/2);
        end
    end
    
    % draw texture, fixation, and flip
    Screen('DrawTexture', display.windowPtr, tex, srcRect, dstRect); 
    Screen('DrawDots', display.windowPtr, gazeXY, angle2pix(display,display.fixation.size), display.fixation.color{1}, [], 2); 
    flipWhen = Screen('Flip', display.windowPtr, flipWhen + 0.5/stim.rate);

    % play sound
    if frame == expansionFrames(end)+1
        PsychPortAudio('Start', pahandle, 1, 0, 1);
        soundStartSec = GetSecs;
    end

end

% flip
Screen('Flip', display.windowPtr, flipWhen + 0.5/stim.rate);

% response
resp.response = 'none'; resp.RT = NaN;

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
WaitSecs(0.3);