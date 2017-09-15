const AA=40,BB=20;
var a,b,t;
procedure hello;
	const world=233;
	write(world);
procedure f;
	procedure s;
		begin
			a:=AA+BB;
			write(a)
		end;
	begin
		if AA >= 80 then
			call s
		else
			begin
				b:=AA-BB;
				write(b)
			end
	end;
repeat
	begin
		begin
			call f
		end;
		call hello
	end
until BB > 50.