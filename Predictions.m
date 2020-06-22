disparity = 24/1600;
angle = pi/180*[0:10:180];
x =1600*disparity*(cos(angle)*0.063-disparity)./(0.063-cos(angle)*disparity);
x = x';

y = 1600*disparity*cos(angle);
y = y';