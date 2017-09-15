{*Simple Test All*}
CoNsT PI=3;
VAR r,A;
VaR flag;
procedure getArea;
BEGIN
  READ(r);
  A:=PI*r*r;
  WRITE(A);
  if A>75 then
    flag:=1
  else
    flag:=0
END;{proc}

{Main Entry}
begin
	flag:=0;
	while flag=0 do
	begin
		call getArea;
		write(flag);
	end;
end.
