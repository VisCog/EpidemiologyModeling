function id = hitWalls(p,x,y,walls)

      xx = ceil((x+p.margin(1))/p.dx+.5);
      yy = ceil((y+p.margin(2))/p.dx+.5);
      tmp = xx<1 | yy<1 | xx>size(walls,2) | yy>size(walls,1);
      xx(tmp) = 1;
      yy(tmp) = 1;
      id = find(walls(sub2ind(size(walls),yy,xx)));
      id = [id;find(tmp)];
end