function y = gfilt(len,sgm)
    if isempty(len), y=1; return; end
    if len<1, len=1; end
    t = 1:len;
    t = t-mean(t);
    y = exp(-t.^2/(2*sgm^2))/(sqrt(2*pi)*sgm);
