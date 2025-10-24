function DrawFixation(win, leftXY, rightXY, centerXY, dotSize, rgb)
if ~isempty(centerXY)
    Screen('DrawDots', win, centerXY, dotSize, rgb, [], 2);
end
if ~isempty(leftXY)
    Screen('DrawDots', win, leftXY, dotSize, [255 255 255], [], 2);
end
if ~isempty(rightXY)
    Screen('DrawDots', win, rightXY, dotSize, [255 255 255], [], 2);
end
end