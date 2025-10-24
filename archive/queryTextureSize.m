function [w, h] = queryTextureSize(tex)
r = Screen('Rect', tex);  % [0 0 w h]
w = r(3); h = r(4);
end