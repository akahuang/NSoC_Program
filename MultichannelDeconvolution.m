function [W_hat,s_hat_all,s_hat_blood] = ...
    MultichannelDeconvolution(x,A_n,A_m,T,eta,L,sample_rate,fig,fil)
% eta is the step size
% L is the length of filter

Tend = T/sample_rate;
sample_num = T; % -max_delay_slot
% t = (1:T)*Tend/T;
s_hat_all = zeros(A_n,T);
s_hat_fft = zeros(A_n,sample_num);
s_hat_max = zeros(1,A_n) ;
s_hat_blood = zeros(1);
delay_s_hat = zeros(1);

W_hat = rand(A_n,A_m,L+1);
y = zeros(A_n,sample_num);
u = zeros(A_m,sample_num);
for aa=1:sample_num
    % --- y
    y(:,aa) = W_hat(:,:,L+1)*x(:,aa);
    for bb=1:min(L,aa-1)
        y(:,aa) = y(:,aa)+W_hat(:,:,bb)*x(:,aa-bb);
    end
    % --- u
    if aa-L>0
        u(:,aa) = W_hat(:,:,L+1)'*y(:,aa-L);
    end
    for bb=0:min(L-1,aa-1)
        u(:,aa) = u(:,aa)+W_hat(:,:,L-bb)'*y(:,aa-bb);
    end
    if aa>L
        W_hat(:,:,L+1) = W_hat(:,:,L+1)+eta*(W_hat(:,:,L+1)-tanh(10*y(:,aa-L))*u(:,aa)');
        for bb=1:L
            W_hat(:,:,bb) = W_hat(:,:,bb)+eta*(W_hat(:,:,bb)-tanh(10*y(:,aa-L))*u(:,aa-bb)');
        end
        %W_hat(:,:,L+1) = W_hat(:,:,L+1)+eta*(W_hat(:,:,L+1)-sign(y(:,aa-L)).*(y(:,aa-L)).^3*u(:,aa)');
    end
%     for bb=1:L+1
%         %if det(W_hat(:,:,bb)) < 0.000001; break; end
%     end
    %disp(W_hat(:,:,51));
    temp = abs(max(max(max(W_hat))));
    if temp>10000
        W_hat = W_hat*1000/(temp);
        eta = eta*1000/(temp);
    end
    %if abs(u(1,aa))>10000; u=u*1000/abs(u(1,aa)); end
end

s_hat = W_hat(:,:,L+1)*x;
for aa=1:L
    temp = W_hat(:,:,aa)*x;
    s_hat = s_hat+[zeros(A_n,aa) temp(:,1:sample_num-aa)];
end

% normalize = ones(1,A_m)/L;
%%%%%%%
% s_hat = eye(2)*x;
%%%%%%%
% fir = LPF_15_25(sample_rate,10,15);% fir.Numerator
% hd = load('notch60.mat','hd');
for aa=1:A_n
    s_hat_all(aa,1:sample_num) = (s_hat(aa,:));
    s_hat_fft(aa,:) = fft(s_hat(aa,:));
    s_hat_max(aa) = s_hat_fft(aa,floor(T/sample_rate));
    % s_hat_all(sensor_set_count,:,rand_delay(1,1):rand_delay(1,1)+sample_num-1) = real(s_hat(:,:))/normalize(1);
end
[dummy s_hat_blood] = max(abs(s_hat_max));
% figure;plot(s_hat_all);title('Recovered signal');
% xlabel('time (s)');ylabel('V');xlim([25000 35000]);

if fig
    figure;
    for aa=1:A_n
        subplot(1,A_n,aa);
        plot(s_hat_all(aa,:));
    end
end
end
