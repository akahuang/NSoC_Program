function y = em_guess(x,wind,mode)
% em_guess(x,wind,mode) predict the low-freq part
% x is one-dim signal
% wind is the window size for average
% mode: 0 middle, 1 peak/inverse dip, -1 dip/inverse peak
%       2 peak, -2 dip
if nargin == 1
	wind = 1;
    mode = 0;
elseif nargin == 2
    mode = 0;
elseif nargin == 3
    if abs(mode)>1
        T = length(x);
        pp = findpeakpos(x*sign(mode));
        take = zeros(1,T);
        take(pp) = x(pp);
        y = take;
        return; 
    end
end
if mod(wind,2)~=1, wind=wind+1; end
T = length(x);
pp = sort([findpeakpos(x) findpeakpos(-x)]);
take = zeros(1,T);
if isempty(pp)
    y = x; return;
elseif length(pp)<3
    y = x; return;
end
if mode==0
    lpp = length(pp);
    xtake = [pp(ones(1,(wind-1)/2)) pp pp(lpp)*ones(1,(wind+1)/2)];
    means = conv(x(xtake),ones(1,wind+1)/(wind+1));
    means = means(1+wind+(wind-1)/2:wind+(wind-1)/2+lpp-1);
    for bb=1:length(pp)-1
        temp = mean([x(pp(bb)) x(pp(bb+1))]);
        temp = abs(x(pp(bb):pp(bb+1)-1)-temp);
        temp = (temp==min(temp)).*exp(-(1:pp(bb+1)-pp(bb))/100);
        take(pp(bb):pp(bb+1)-1) = (temp==max(temp))*means(bb);
    end
else
    wind = max(2,wind-1);
    if mode==1
        if x(pp(1))<x(pp(2))
            take(pp(1)) = x(pp(2));
            pp = pp(2:length(pp));
        end
        if x(pp(length(pp)-1))>x(pp(length(pp)))
            take(pp(length(pp))) = x(pp(length(pp)-1));
            pp = pp(1:length(pp)-1);
        end
    elseif mode==-1
        if x(pp(1))>x(pp(2))
            take(pp(1)) = x(pp(2));
            pp = pp(2:length(pp));
        end
        if x(pp(length(pp)-1))<x(pp(length(pp)))
            take(pp(length(pp))) = x(pp(length(pp)-1));
            pp = pp(1:length(pp)-1);
        end
    end
    lpp = length(pp);
    fil = floor(wind/2)-1;
    take(pp(1:2:lpp)) = x(pp(1:2:lpp));
    inter = conv(x(pp([ones(1,fil) 1:2:lpp ones(1,fil)*(lpp-1)])),...
        ones(1,wind)/wind);
    take(pp(2:2:lpp)) = inter(wind:length(inter)-1-fil*2);
end
y = take;