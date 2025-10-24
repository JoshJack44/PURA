function ppd = angle2pix(display, ang)
if ~isfield(display,'width') || ~isfield(display,'dist') || ~isfield(display,'resolution')
    error('display struct missing fields for angle2pix.');
end
pixWidth = display.resolution(1);
cmPerDeg = 2 * display.dist * tand(ang/2);
ppd = pixWidth / (display.width / cmPerDeg);
end