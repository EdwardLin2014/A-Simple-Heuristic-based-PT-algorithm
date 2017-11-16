clear all; close all; clc

% All
Data = [4.42470000000000,6.92050000000000,4.72560000000000,6.77940000000000,4.96660000000000,2.69580000000000;6.03000000000000,7.43060000000000,5.72960000000000,6.71370000000000,3.13940000000000,6.99980000000000;6.51070000000000,7.82890000000000,5.35220000000000,6.73080000000000,4.89840000000000,7.64240000000000;6.64170000000000,8.07490000000000,4.75100000000000,6.66060000000000,4.98090000000000,7.46430000000000;6.68270000000000,8.25950000000000,4.46600000000000,6.62890000000000,4.58400000000000,7.00190000000000;6.68380000000000,8.33890000000000,4.31010000000000,6.52370000000000,4.33480000000000,6.66640000000000;6.67750000000000,8.35340000000000,4.19150000000000,6.43880000000000,4.26440000000000,6.58160000000000;6.67890000000000,8.37420000000000,4.14930000000000,6.42560000000000,4.13700000000000,6.44480000000000;6.68190000000000,8.39630000000000,4.00510000000000,6.32950000000000,4.06540000000000,6.39980000000000;6.67500000000000,8.38920000000000,3.94100000000000,6.28570000000000,3.94460000000000,6.31740000000000];
x = [5,10,15,20,25,30,35,40,45,50];

FontSize = 30;

figure('Color', 'w', 'units','normalized','outerposition',[0 0 1 1]);
% voice
subplot(1,2,1);
plot(x,Data(:,1),'-*b', x,Data(:,3),'-xg',x,Data(:,5),'-dr','LineWidth', 2, 'MarkerSize',20);
title('(a) The GNSDR of the Singing Voice','FontWeight','bold','FontSize', FontSize);
ylim(gca,[0,10]);
xlim(gca,[5,50]);
set(gca,'XTick',5:5:50,'XMinorTick','on','XGrid','on','YTick',0:1:10,'YMinorTick','on','YGrid','on','FontWeight','bold','FontSize', FontSize);
ylabel('GNSDR','FontWeight','bold','FontSize', FontSize);
xlabel('\textbf{Frequency Threshold (Hz) $\theta_f$ or $f$}','Interpreter','LaTex','FontWeight','bold','FontSize', FontSize);

h = legend('FM','SMS-PT','MQ','Location','southeast');
set(h,'FontWeight','bold','FontSize', FontSize);

% Song
subplot(1,2,2);
plot(x,Data(:,2),'-*b', x,Data(:,4),'-xg',x,Data(:,6),'-dr','LineWidth', 2, 'MarkerSize',20);
title('(b) The GNSDR of the Music Accompaniment','FontWeight','bold','FontSize', FontSize);

ylim(gca,[0,10]);
xlim(gca,[5,50]);
set(gca,'XTick',5:5:50,'XMinorTick','on','XGrid','on','YTick',0:1:10,'YMinorTick','on','YGrid','on','FontWeight','bold','FontSize', FontSize);
ylabel('GNSDR','FontWeight','bold','FontSize', FontSize);
xlabel('\textbf{Frequency Threshold (Hz) $\theta_f$ or $f$}','Interpreter','LaTex','FontWeight','bold','FontSize', FontSize);

h = legend('FM','SMS-PT','MQ','Location','southeast');
set(h,'FontWeight','bold','FontSize', FontSize);
