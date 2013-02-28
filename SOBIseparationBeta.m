function [A_hat,s_hat_all,s_hat_blood] = ...
    SOBIseparationBeta(x,A_n,A_m,T,sample_rate,tau_s,tau_n,tau_space,fig)

Tend = T/sample_rate;
sample_num = T; % -max_delay_slot
% t = (1:T)*Tend/T;
s_hat_all = zeros(A_n,T);
s_hat_max = zeros(1,A_n) ;

% aperiodic signal
%s(1,1:4000)=0;s(1,8001:12000)=0; % pulse
%s(1,:) = s(1,:) + 0.1*sin(2*pi*10*t);
%s(2,:) = s(2,:) + 0.3*sin(2*pi*10*t);

R_hat_tau = x*x';
[H,D] = eig(R_hat_tau); % each column of H is an eigenvector
[dummy, sortID] = sort(ones(1,A_m)*D);
h_lambda = ones(1,A_m)*D; %disp(h_lambda);%%
tempID = 1:A_m;
temp = mean(h_lambda(tempID(sortID<=A_m-A_n)));
if isnan(temp); temp = 0; end;
h_lambda = (h_lambda(tempID(sortID>A_m-A_n)) - temp).^(-0.5);
W_hat = (H(:,sortID(sortID>A_m-A_n)) * diag(h_lambda))';
z = W_hat*x; %disp(z);%%

tau_count=0;
r_all = zeros(A_n,A_n*tau_n);

for tau = tau_s:tau_space:tau_s+(tau_n-1)*tau_space;
    shift = floor(tau / Tend * sample_num);
    R_hat_under = z(:,shift+1:sample_num-shift)*z(:,2*shift+1:sample_num)'; % size = #sensor
    tau_count = tau_count+1;
    r_all(:,A_n*(tau_count-1)+1:A_n*tau_count) = R_hat_under;
end

[hh,D]= rjd(r_all(:,1:A_n*tau_n/2),0.001);
s_hat = hh'*W_hat*x;
A_hat = inv(W_hat'*W_hat)*W_hat'*hh;
normalize = ones(1,A_m)/20;
%s_hat = real(s_hat(:,:))/normalize(1);
for aa=1:A_n
    s_hat_all(aa,:) = s_hat(aa,:);
    s_hat_fft(aa,:) = fft(s_hat_all(aa,:));
    %s_hat_max(aa) = s_hat_fft(aa,T/sample_rate);
    s_hat_max(aa) = abs(s_hat_fft(aa,ceil(T/sample_rate)));
    % s_hat_all(sensor_set_count,:,rand_delay(1,1):rand_delay(1,1)+sample_num-1) = real(s_hat(:,:))/normalize(1);
end
[dummy s_hat_blood] = max(s_hat_max);

if fig
    figure;
    for aa=1:A_n
        subplot(A_n,1,aa);
        plot(s_hat_all(aa,:));
        xlim([0 50]);
    end
end
end