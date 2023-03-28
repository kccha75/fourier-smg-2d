
u(1)=u1;
u(2)=DJL.u;

[mini,maxi,minindex_x,maxindex_x,index_z]=locatemaxmin(v1,[],[]);
y(1)=maxi-mini;
[mini,maxi,minindex_x,maxindex_x,index_z]=locatemaxmin(v2,[],[]);
y(2)=maxi-mini;
i=3;
while y(i-1)>1e-10

    u(i)=u(i-1)-y(i-1)*(u(i-1)-u(i-2))/(y(i-1)-y(i-2));

    DJL.u=u(i);
    v1=v2;
    v2=NewtonSolve(v1,DJL,pde,domain,option);
    [mini,maxi,minindex_x,maxindex_x,index_z]=locatemaxmin(v2,[],[]);
    y(i)=maxi-mini;
    i=i+1;

end