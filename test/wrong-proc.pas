var b;
procedure father;
	var f;
	procedure son1;
		const s1=1;
		b:=(b+s1)/f;
	procedure son2;
		const s2=2;
		b:=(b-s2)*f;
begin
f:=b+5;
call son1;
write(s1);
call son2;
write(s)
end;

{Main Entry}
call father.
