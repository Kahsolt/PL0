const AA=40,BB=20;
var a,b,t;
procedure f;
	procedure s;
		begin
			a:=AA+BB;
			write(a)
		end;
	procedure ss;
		t:=b+a;
if AA >= 80 then
	if BB <10 then
		call s
	else
		t:=t+2
else
	begin
		b:=AA-BB;
		write(b)
end;
procedure hello;
	const world=233;
	while t<10 do
		call f;

t:=t+1;
		repeat
			begin
				begin
					call f
				end;
				call hello
			end
		until t > 50;
call hello.
