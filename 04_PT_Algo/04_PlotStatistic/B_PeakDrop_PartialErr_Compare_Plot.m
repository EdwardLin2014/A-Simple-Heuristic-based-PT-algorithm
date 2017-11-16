clear all; close all; clc

% All
Data = [0.336725273000000,0.212902982000000,0.349917580000000;0.388127448000000,0.236942410000000,0.433876529000000;0.179920388000000,0.0717846170000000,0.128522215000000;0.223704807000000,0.262202714000000,0.212786790000000;0.173510979000000,0.216857304000000,0.161780431000000;0.277666898000000,0.316708612000000,0.269911176000000];
x = [5,10,15,20,25,30,35,40,45,50];

FontSize = 26;

figure('Color', 'w', 'units','normalized','outerposition',[0 0 1 1]);
% Average number of deleted peaks (%)
subplot(2,1,1);
bar(Data(1:3,:)*100);
colormap('gray');
title('(a) Average Number of Deleted Peaks (%)','FontWeight','bold','FontSize', FontSize);
ylim(gca,[0,50]);
set(gca, 'XTickLabel',{'Overall','Singing Voice','Music Accompaniment'}, 'YMinorTick','on','YGrid','on','FontWeight','bold','FontSize', FontSize);
h = legend('FM','SMS-PT','MQ','Location','northeast');
set(h,'FontWeight','bold','FontSize', FontSize);

% Average Number of Error Partials 
subplot(2,1,2);
bar(Data(4:6,:)*100);
colormap('gray');
title('(b) Average Number of Error Partials (%)','FontWeight','bold','FontSize', FontSize);
ylim(gca,[0,50]);
set(gca, 'XTickLabel',{'Overall','Singing Voice','Music Accompaniment'}, 'YMinorTick','on','YGrid','on','FontWeight','bold','FontSize', FontSize);
h = legend('FM','SMS-PT','MQ','Location','north');
set(h,'FontWeight','bold','FontSize', FontSize);

