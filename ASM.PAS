(*

Magic Assembler v1.15

BSD 3-Clause License

Copyright 1994-2021 Bert Greevenbosch
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*)

program assemblerprogram(input,output);

uses
   crt,
   dos;

type
   grouptype = (aam, add, call, callf, es, i, ic, int, jbe, labl, lds, nothing, nt, push, ret, rol, xchg);
   labeltype = (bte, equ, lbl, strng, wrd);
   labelptr = ^labelrec;
   labelrec = record
      name: ^string;
      equal: ^string;
      address: word;
      link: labelptr;
      lbltype: labeltype;
   end;
   vartype = (registerbyte, registerword, addressbyte, addressword, constante, segmentreg);

const
   addgroup: array [0..10] of string[4] = ('ADD','OR','ADC','SBB','AND','SUB','XOR','CMP','TEST','MOV', 'LEA');
   addbase: array [0..10] of byte = ($00, $08, $10, $18, $20, $28, $30, $38, $84, $88, $8a);
   addressregisters: array [0..11] of string [2] = ('AX','CX','DX','BX','SP','BP','SI','DI','ES','CS','SS','DS');
   byteregisters: array [0..7] of string[2] = ('AL','CL','DL','BL','AH','CH','DH','BH');
   esgroup: array [0..40] of string[5] = ('ES:','DAA','CS:','DAS','SS:','AAA','DS:','AAS','NOP','CBW','CWD','WAIT','PUSHF',
                                          'POPF','SAHF','LAHF','MOVSB','MOVSW','CMPSB','CMPSW','STOSB','STOSW','LODSB',
                                          'LODSW','SCASB','SCASW','INTO','IRET','XLAT','LOCK','REP','REPNZ','REPZ','HLT',
                                          'CMC','CLC','STC','CLI','STI','CLD','STD');
   esbase: array [0..40] of byte = ($26,$27,$2e,$2f,$36,$37,$3e,$3f,$90,$98,$99,$9b,$9c,$9d,$9e,$9f,$a4,$a5,$a6,$a7,$aa,$ab,
                                    $ac,$ad,$ae,$af,$ce,$cf,$d7,$f0,$f3, $f2,$f3,$f4,$f5,$f8,$f9,$fa,$fb,$fc,$fd);
   h: array [0..15] of string[1] = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
   jbegroup: array [0..37] of string[6]=('JBE','JNA','JB','JC','JNAE','JO','JNO','JNB','JAE','JNC','JZ','JE','JNZ','JNE',
                                         'JA','JNBE','JS','JNS','JPE','JP','JPO','JNP','JNO','JL','JNGE','JGE','JNL','JLE',
                                         'JNG','JG','JNLE', 'LOOPE', 'LOOPNE', 'LOOPNZ','LOOPZ','LOOP','JCXZ','JMPS');
   jbebase: array [0..37] of byte = ($76,$76,$72,$72,$72,$70,$71,$73,$73,$73,$74,$74,$75,$75,$77,$77,$78,$79,$7a,$7a,$7b,$7b,
                                     $7b,$7c,$7c,$7d,$7d,$7e,$7e,$7f,$7f,$e1, $e0,$e0,$e1,$e2,$e3,$eb);
   lablgroup: array [0..6] of string[3] = ('DB','DBE','DD','DDE','DS','DW','DWE');
   notgroup: array [0..5] of string[4] = ('NOT','NEG','MUL','IMUL','DIV','IDIV');
   notbase: array [0..5] of byte = ($10,$18,$20,$28,$30,$38);
   segmentregisters: array [0..3] of string[2] = ('ES','CS','SS','DS');
   reserved: array [0..132] of string[5] = ('AAA','AAD','AAM','AAS','ADC','ADD','AND','CALL','CBW','CLC','CLD','CLI','CMC',
         'CMP','CMP','CMPSB','CMPSW','CWD','DAA','DAS','DEC','DIV','ESC','HLT','IDIV','IMUL','IN','INC','INT','INTO',
         'IRET','JA','JAE','JB','JBE','JC','JCXZ','JE','JG','JGE','JL','JLE','JMP','JNA','JNAE','JNB','JNBE','JNC','JNE',
         'JNG','JNGE','JNL','JNLE','JNO','JNP','JNS','JNZ','JO','JP','JPE','JPO','JS','JZ','LAHF','LDS','LEA','LES',
         'LOCK','LODSB','LODSW','LOOP','LOOPE','LOOPNE','LOOPNZ','LOOPZ','MOV','MOVSB','MOVSW','MUL','NEG','NOP','NOT',
         'OR','OUT','POP','POPF','PUSH','PUSHF','RCL','RCR','REP','REPE','REPNE','REPNZ','REPZ','RET','ROL','ROR','SAHF',
         'SAL','SAR','SBB','SCASB','SCASW','SHL','SHR','STC','STD','STI','STOSB','STOSW','SUB','TEST','WAIT','XCHG',
         'XLAT','XOR','JMPS','JMPF','CALLF','DB','DD', 'DW','DBE','DDE', 'DWE','DS','ES:','CS:','SS:','DS:', 'LEA', 'ROFS');
   rolgroup: array [0..6] of string[3] = ('ROL','ROR','RCL','RCR','SHL','SHR','SAR');
   rolbase: array [0..6] of byte = ($00,$08,$10,$18,$20,$28,$38);
   wordregisters: array [0..7] of string[2] = ('AX','CX','DX','BX','SP','BP','SI','DI');

var
   base: word;
   boot: array [0..511] of byte;
   bt: boolean;
   codes: word;
   command: string;
   current: labelptr;
   datas: word;
   day: word;
   dow: word;
   dr: byte;
   dst: string;
   dsttype: vartype;
   equdone: boolean;
   f: file;
   fi: file;
   first: labelptr;
   firstlbl: boolean;
   group: grouptype;
   incompatible: boolean;
   infile: boolean;
   labeldone: boolean;
   lbel: string;
   lbld: boolean;
   lbls: boolean;
   line: string;
   maxofs: word;
   month: word;
   name: string;
   nb: word;
   next: labelptr;
   no: longint;
   nnum: boolean;
   o: word;
   ofset: word;
   ok: byte;
   printer: text;
   prog: text;
   prt: boolean;
   prtnum: boolean;
   regel: string;
   s: word;
   skipped: word;
   src: string;
   srcp: boolean;
   srcprinter: text;
   srctype: vartype;
   useword: word;
   work: byte;
   work2: byte;
   wp: byte;
   year: word;

procedure mul(var i: longint; n: longint);
begin
   i:=i*n;
end;

procedure dve(var i: longint; n: longint);
begin
   i:=trunc(i/n);
end;

procedure error(message: string);
begin
   if wherex<>1 then
      writeln;
   writeln(^g+message);
   if prtnum then
   begin
      writeln('Error in line ',no,':');
      writeln(regel);
   end;
   writeln('Assembling NOT completed succesfully.');
   if (infile) and not (bt) then
   begin
      close(fi);
      erase(fi);
   end;
   halt(1);
end;

procedure unspace(var i: string);
begin
   if i[length(i)]=#32 then
      repeat
         i:=copy(i, 1, length(i)-1);
      until (i='') or (i[length(i)]<>#32);
end;

function deext(i: string): string;
var
   work: byte;
   o: string;
begin
   work:=1;
   while (i[work]<>'.') and (work<=length(i)) do
      inc(work);
   if i[work]<>'.' then
      o:=i
   else
      o:=copy(i,1,work-1);
   deext:=o;
end;

procedure extragettype;
begin
     if (copy(src,1,1)='[') and (dsttype=registerbyte) then
        srctype:=addressbyte;
     if (copy(src,1,1)='[') and (dsttype=registerword) then
        srctype:=addressword;
     if (copy(dst,1,1)='[') and (srctype=registerbyte) then
        dsttype:=addressbyte;
     if (copy(dst,1,1)='[') and (srctype=registerword) then
        dsttype:=addressword;
     if (copy(dst,1,1)='[') and (srctype=segmentreg) then
        dsttype:=addressword;
     if (copy(src,1,1)='[') and (dsttype=segmentreg) then
        srctype:=addressword;
     if copy(dst,1,5)='BYTE ' then
        dsttype:=addressbyte;
     if copy(dst,1,5)='WORD ' then
        dsttype:=addressword;
end;

function dec2hex(inp: byte): string;
begin
   dec2hex:=h[inp and $f0 shr 4]+h[inp and $0f];
end;

function hex(inp: word): string;
var
   outp: string[6];
begin
   outp:=h[inp and $f000 shr 12]+
      h[inp and $0f00 shr 8]+
      h[inp and $00f0 shr 4]+
      h[inp and $000f];
   if nnum then
      outp:=outp+'H';
   hex:=outp;
end;

function h2d(input: string; w: byte; totl: byte): longint;
var
   work, work2: byte;
   output: longint;
begin
   output:=0;
   for work:=w to totl do
   begin
      output:=output shl 4;
      work2:=0;
      while (h[work2]<>input[work]) and (work2<17) do
         inc(work2);
      if work2=17 then
         error('Undefined label: '+input);
      inc(output, work2);
   end;
   h2d:=output;
end;

function d2d(input: string; w: byte; totl: byte): longint;
var
   work: byte;
   output: longint;
begin
   output:=0;
   for work:=w to totl do
   begin
      output:=output*10;
      if (input[work]>'9') or (input[work]<'0') then
         error('Undefined label: '+input);
      inc(output, ord(input[work])-48);
   end;
   d2d:=output;
end;

function b2d(input: string; w: byte; totl: byte): longint;
var
   work: byte;
   output: longint;
begin
   output:=0;
   for work:=w to totl do
   begin
      output:=output shl 1;
      if (input[work]<>'0') and (input[work]<>'1') then
         error('Undefined label: '+input);
      if (input[work]='1') then
         inc(output);
   end;
   b2d:=output;
end;

function value(input: string): longint;
var
   done: boolean;
   output: longint;
begin
   done:=false;
   if not nnum then
   begin
      if(input[1]<>'%') then
      begin
         output:=h2d(input, 1, length(input));
         done:=true;
      end
      else
      begin
         done:=false;
         if input[2]='D' then
         begin
            output:=d2d(input, 3, length(input));
            done:=true;
         end;
         if input[2]='B' then
         begin
            output:=b2d(input, 3, length(input));
            done:=true;
         end;
      end;
   end
   else
   begin
      done:=true;
      if input[length(input)]='H' then
         output:=h2d(input, 1, length(input)-1)
      else
         if input[length(input)]='B' then
            output:=b2d(input, 1, length(input)-1)
         else
            output:=d2d(input, 1, length(input));
   end;
   if not done then
      error('Undefined label: '+input);
   value:=output;
end;

function hex2dec(input: string): longint;
var
   output: longint;
   w: byte;
   work: byte;
   work2: byte;
   work3: byte;
begin
   output:=0;
   if input[1]<>'+' then
      input:='+'+input;
   work:=1;
   repeat
      w:=work;
      repeat
         inc(w);
         if input[w]='(' then
         begin
            work2:=w;
            work3:=1;
            repeat
               inc(work2);
               case input[work2] of
                    '(':
                        inc(work3);
                    ')':
                        dec(work3);
               end;
            until (work3=0) or (work2>length(input));
            if work2>length(input) then
               error('Missing )');
            input:=copy(input, 1, w-1)+hex(hex2dec(copy(input, w+1, work2-w-1)))+copy(input, work2+1, length(input)-work2);
         end;
      until (w>length(input)) or (input[w]='+') or (input[w]='-') or (input[w]='*') or (input[w]='/');
      if input[w]<>'(' then
      begin
         case input[work] of
            '+':
               inc(output, value(copy(input, work+1, w-work-1)));
            '-':
               dec(output, value(copy(input, work+1, w-work-1)));
            '*':
               mul(output, value(copy(input, work+1, w-work-1)));
            '/':
               dve(output, value(copy(input, work+1, w-work-1)));
         end;
      end;
      work:=w;
   until work>length(input);
   hex2dec:=output;
end;

function upper(inp: string): string;
var
   strng: boolean;
   work: byte;
   use: string;
begin
     use:=inp;
     work:=0;
     strng:=false;
     repeat
           inc(work);
           if inp[work]='''' then
              strng:=not strng;
           if not strng then
              use[work]:=upcase(inp[work]);
     until work=length(use);
     upper:=use;
end;

procedure delspaces(var command: string);
begin
   while copy(command,length(command),1)=' ' do
      command:=copy(command,1,length(command)-1);
end;

function exist(com, srch: string): boolean;
var
   work: byte;
begin
     exist:=false;
     for work:=1 to length(com)-length(srch) do
         if copy(com,work,length(srch))=srch then
            exist:=true;
end;

procedure uncode;
var
   ok, res: boolean;
   dsr, work, work2, work3: byte;
   a, b: string;
label
   lbl1,
   lbl2,
   lbl3,
   lbl4;
begin
   lbel:='';
   command:='';
   src:='';
   dst:='';
   readln(prog, regel);
   work:=0;
   while(work<length(regel)) do
   begin
      inc(work);
      if(regel[work]=#9) then
      begin
         a:=copy(regel, 1, work-1);
         b:=copy(regel, work+1, length(regel)-work-1);
         regel:=a;
         for work2:=work mod 8 to 8 do
            regel:=regel+' ';
         regel:=regel+b;
         work:=0;
      end;
   end;
   line:=regel;
   work:=length(regel);
   if work=0 then
   begin
      group:=nothing;
      goto lbl1;
   end;
   repeat
      if regel[work]='''' then
      begin
         lbl2:
         repeat
            dec(work);
            if work=0 then
               error('String not closed');
         until (regel[work]='''') or (regel[work]=';');
         if regel[work]=';' then
            for work2:=1 to work do
               if regel[work2]='''' then
               begin
                  repeat
                     inc(work2)
                  until (regel[work2]='''') or (work2=work);
                  if work2=work then
                     goto lbl2;
               end;
      end;
      if regel[work]=';' then
      begin
         if work=1 then
            regel:=''
         else
            regel:=copy(regel,1,work-1);
      end;
      dec(work);
   until work=0;
   unspace(regel);
   line:=regel;
   if upper(regel)='-' then
   begin
      infile:=false;
      regel:='';
   end;
   if regel='' then
   begin
      group:=nothing;
      goto lbl1;
   end;
   regel:=upper(regel);
   work:=1;
   while (regel[work]=#32) or (regel[work]=#9) and (work<=length(regel)) do
      inc(work);
   work2:=work;
   while (regel[work]<>#32) and (regel[work]<>#9) and (work<=length(regel)) do
      inc(work);
   command:=copy(regel,work2,work-work2);
   res:=false;
   for work3:=length(command)-1 downto 1 do
      if command[work3]=':' then
      begin
         lbel:=copy(command,1,work3-1);
         command:=copy(command,work3+1,length(command)-work3);
      end;
   for work3:=0 to 132 do
      if command=reserved[work3] then
         res:=true;
   if not res then
   begin
      lbel:=command;
      if lbel[length(lbel)]=':' then
         lbel:=copy(lbel,1,length(lbel)-1);
      while (regel[work]=#32) or (regel[work]=#9) and (work<=length(regel)) do
         inc(work);
      work2:=work;
      while (regel[work]<>#32) and (regel[work]<>#9) and (work<=length(regel)) do
         inc(work);
      command:=copy(regel,work2,work-work2);
   end;
   if command='' then
   begin
      group:=nothing;
      goto lbl1;
   end;
   while (regel[work]=#32) or (regel[work]=#9) and (work<=length(regel)) do
      inc(work);
   work3:=work;
   if equdone then
   begin
      repeat
         while (regel[work]=',') or (regel[work]=' ') or (regel[work]=#9) and (work<length(regel)) do
         begin
            if (regel[work]='''') then
            begin
               repeat
                  inc(work);
               until (regel[work]='''') or (work>length(regel));
               if work>length(regel) then
                  error('String not closed');
            end;
            inc(work);
         end;
         work2:=work;
         while (regel[work]<>',') and (regel[work]<>' ') and (regel[work]<>#9) and (work<length(regel)) do
            inc(work);
         inc(work);
         current:=first;
         while(current<>nil) do
         begin
            if (copy(regel, work2, work-work2)=current^.name^) and (current^.lbltype=equ) then
            begin
               regel:=copy(regel, 1, work2-1)+current^.equal^+copy(regel, work, length(regel)-work);
               break;
               work:=work2;
            end;
            current:=current^.link;
         end;
      until work>length(regel);
   end;
   work:=work3;
   work2:=work3;
   while (regel[work]<>',') and (work<=length(regel)) do
   begin
      if regel[work]='''' then
      repeat
         inc(work)
      until (regel[work]='''') or (work>ord(regel[0]));
      if work>ord(regel[0]) then
         error('String not closed');
      inc(work);
   end;
   dst:=copy(regel,work2,work-work2);
   while (regel[work+1]=' ') and (work+1<=length(regel)) do
      inc(work);
   if work<length(regel) then
      src:=copy(regel,work+1,length(regel)-work);
   dsr:=work2;
   if (ord(src[0])=3) and (src[1]='''') and (src[3]='''') then
      src:=hex(ord(src[2]));
   if copy(dst,1,5)='BYTE[' then
      dst:='BYTE ['+copy(dst,6,length(dst)-5);
   if copy(src,1,5)='BYTE[' then
      src:='BYTE ['+copy(src,6,length(src)-5);
   if copy(dst,1,5)='WORD[' then
      dst:='WORD ['+copy(dst,6,length(dst)-5);
   if copy(src,1,5)='WORD[' then
      src:='WORD ['+copy(src,6,length(src)-5);
   ok:=false;
   for work:=0 to 10 do
      if command=addgroup[work] then
      begin
         ok:=true;
         group:=add;
      end;
   for work:=0 to 6 do
      if command=lablgroup[work] then
      begin
         ok:=true;
         group:=labl;
      end;
   for work:=0 to 40 do
      if command=esgroup[work] then
      begin
         ok:=true;
         group:=es;
      end;
   if (command='PUSH') or (command='POP') then
   begin
      ok:=true;
      group:=push;
   end;
   if (command='RET') then
   begin
      ok:=true;
      group:=ret;
   end;
   for work:=0 to 37 do
      if command=jbegroup[work] then
      begin
         ok:=true;
         group:=jbe;
      end;
   if command='EQU' then
   begin
      group:=nothing;
      ok:=true;
   end;
   if command='INT' then
   begin
      group:=int;
      ok:=true;
   end;
   if (command='CALL') or (command='JMP') then
   begin
      group:=call;
      ok:=true;
   end;
   if (command='CALLF') or (command='JMPF') then
   begin
      group:=callf;
      ok:=true;
   end;
   for work:=0 to 5 do
      if command=notgroup[work] then
      begin
         group:=nt;
         ok:=true;
      end;
   if (command='INC') or (command='DEC') then
   begin
      group:=ic;
      ok:=true;
   end;
   if (command='IN') or (command='OUT') then
   begin
      group:=i;
      ok:=true;
   end;
   if command='ROFS' then
   begin
      group:=nothing;
      ok:=true;
      ofset:=0;
   end;
   for work:=0 to 6 do
      if command=rolgroup[work] then
      begin
         group:=rol;
         ok:=true;
      end;
   if (command='AAD') or (command='AAM') then
   begin
      group:=aam;
      ok:=true;
   end;
   if (command='LDS') then
   begin
      group:=lds;
      ok:=true;
   end;
   if (command='XCHG') then
   begin
      group:=xchg;
      ok:=true;
   end;
   if group=labl then
   begin
      dst:=copy(regel, dsr, length(regel)-dsr+1);
   end;
   if equdone then
   begin
      current:=first;
      while current<>nil do
      begin
         lbl3:
         if current^.lbltype=equ then
         begin
            if length(src)>=length(current^.name^) then
            begin
               work:=1;
               while work<=length(src)-length(current^.name^)+1 do
               begin
                  if src[work]='''' then
                     repeat
                        inc(work)
                     until (src[work]='''') or (work>=length(src)-length(current^.name^));
                  if copy(src, work, length(current^.name^))=current^.name^ then
                  begin
         src:=copy(src, 1, work-1)+current^.equal^+copy(src, work+length(current^.name^), length(src)-length(current^.name^));
                     current:=first;
                     goto lbl3;
                  end;
                  inc(work);
               end;
            end;
            if length(dst)>=length(current^.name^) then
            begin
               work:=1;
               while work<=length(dst)-length(current^.name^)+1 do
               begin
                  if dst[work]='''' then
                     repeat
                        inc(work)
                     until (dst[work]='''') or (work>=length(dst)-length(current^.name^));
                  if work<length(dst)-length(current^.name^) then
                  begin
                     if copy(dst, work, length(current^.name^))=current^.name^ then
                     begin
         dst:=copy(dst, 1, work-1)+current^.equal^+copy(dst, work+length(current^.name^), length(dst)-length(current^.name^));
                        current:=first;
                        goto lbl3;
                     end;
                  end;
                  inc(work);
               end;
            end;
         end;
         current:=current^.link;
      end;
      if length(src)>8 then
         for work:=1 to length(src)-7 do
         begin
            if src[work]='''' then
            begin
               inc(work);
               repeat
                  inc(work);
               until (src[work-1]='''') or (work=length(src)-7);
            end;

            if copy(src, work, 7)='OFFSET(' then
            begin
               inc(work, 7);
               work2:=work;
               while (src[work2]<>')') and (work2<length(src)) do
                  inc(work2);
               if src[work2]<>')' then
                  error('Missing )');
               if labeldone then
               begin
                  current:=first;
                  while(current<>nil) do
                  begin
                     if current^.name^=copy(src, work, work2-work) then
                        src:=copy(src, 1, work-8)+hex(current^.address)+copy(src, work2+1, length(src)-work2);
                     current:=current^.link;
                  end;
                  if copy(src, work-8, 7)='OFFSET(' then
                     error('Undefined label: '+copy(src, work, work2-work));
               end
               else
                  src:=copy(src, 1, work-8)+hex($8000)+copy(src, work2+1, length(src)-work2);
            end;
         end;
      if length(dst)>8 then
         for work:=1 to length(dst) do
         begin
            if dst[work]='''' then
            begin
               inc(work);
               repeat
                  inc(work);
               until (dst[work-1]='''') or (work=length(dst));
            end;
            if copy(dst, work, 7)='OFFSET(' then
            begin
               inc(work, 7);
               work2:=work;
               while (dst[work2]<>')') and (work2<length(dst)) do
                  inc(work2);
               if dst[work2]<>')' then
               begin
                  write('');
                  error('Missing )');
               end;
               if labeldone then
               begin
                  current:=first;
                  while(current<>nil) do
                  begin
                     if current^.name^=copy(dst, work, work2-work) then
                        dst:=copy(dst, 1, work-8)+hex(current^.address)+copy(dst, work2+1, length(dst)-work2);
                     current:=current^.link;
                  end;
                  if copy(dst, work-8, 7)='OFFSET(' then
                     error('Undefined label: '+copy(dst, work, work2-work));
               end
               else
                  dst:=copy(dst, 1, work-8)+hex($8000)+copy(dst, work2+1, length(dst)-work2);
            end;
         end;
   end;
   if not ok then
      error('Unknown command: '+command);
   lbl1:
end;

procedure chk(var com: string);
var
   work: byte;
begin
   if com='PARSIZE' then
      com:='FFFF';
   if (com=current^.name^) or (com='['+current^.name^+']') then
   begin
      case current^.lbltype of
         bte:
            com:='BYTE [FFFF]';
         wrd:
            com:='WORD [FFFF]';
      end;
      if (current^.lbltype<>bte) and (current^.lbltype<>wrd) and (group<>jbe) and (group<>call) and (group<>callf) then
         error(^g+'Wrong usage of label');
   end;
   if (copy(com, 7, length(com)-7)=current^.name^) then
   begin
      if copy(com, 1, 6)='BYTE [' then
         com:='BYTE [FFFF]';
      if copy(com, 1, 6)='WORD [' then
         com:='WORD [FFFF]';
   end;
end;

procedure gettype(var com: string; var comtype: vartype);
begin
   if copy(com,1,6)=('WORD [') then
      comtype:=addressword;
   if copy(com,1,6)=('BYTE [') then
      comtype:=addressbyte;
   for work:=0 to 7 do
      if com=byteregisters[work] then
         comtype:=registerbyte;
   for work:=0 to 7 do
      if com=wordregisters[work] then
         comtype:=registerword;
   for work:=0 to 3 do
      if com=segmentregisters[work] then
         comtype:=segmentreg;
end;

procedure chkcode(cm: string; var adrescode: byte; var inccod: word);
var
   bp, bx, di, si: boolean;
   no, work, work2: byte;
   handy: integer;
   com, u: string;
begin
   com:=cm;
   for work:=1 to length(com) do
      if copy(com, work, 2)='][' then
         com:=copy(com, 1, work-1)+'+'+copy(com, work+2, length(com)-work-1);
   if (copy(com,1,5)='BYTE ') or (copy(com,1,5)='WORD ') then
      com:=copy(com,6,length(com)-5);
   if com='[BP]' then
      com:='[BP+00]';
   no:=0;
   bp:=exist(com,'BP');
   if bp then
      inc(no);
   bx:=exist(com,'BX');
   if bx then
      inc(no);
   di:=exist(com,'DI');
   if di then
      inc(no);
   si:=exist(com,'SI');
   if si then
      inc(no);
   if no>2 then
      error('To many identifiers in address');
   if not (bp) and (bx) and not (di) and (si) then
      adrescode:=$00;
   if not (bp) and (bx) and (di) and not (si) then
      adrescode:=$01;
   if (bp) and not (bx) and not (di) and (si) then
      adrescode:=$02;
   if (bp) and not (bx) and (di) and not (si) then
      adrescode:=$03;
   if not (bp) and not (bx) and not (di) and (si) then
      adrescode:=$04;
   if not (bp) and not (bx) and (di) and not (si) then
      adrescode:=$05;
   if not (bp) and not (bx) and not (di) and not (si) then
      adrescode:=$06;
   if not (bp) and (bx) and not (di) and not (si) then
      adrescode:=$07;
   if (bp) and not (bx) and not (di) and not (si) then
      adrescode:=$06;
   if (adrescode<4) and (length(com)<>7) then
      inc(adrescode,$40);
   if (adrescode>3) and (adrescode<6) and (length(com)<>4) then
      inc(adrescode,$40);
   if (adrescode=7) and (length(com)<>4) then
      inc(adrescode,$40);
   if (adrescode=6) and (bp) then
      inc(adrescode,$40);
   if adrescode>=$40 then
   begin
      work:=1;
      repeat
         inc(work);
         u:=copy(com,work,2);
      until (u<>'BP') and (u<>'BX') and (u<>'DI') and (u<>'SI') and (u[1]<>'+') and (u[1]<>'[')
      and (u[1]<>'X') and (u[1]<>'P') and (u[1]<>'I');
      work2:=work;
      repeat
         inc(work2);
      until (com[work2]=']') or (com[work2]='+') or (copy(com, work, 2)='][');
      inccod:=hex2dec(copy(com,work,work2-work));
   end;
   if (inccod>=128) and (inccod<65408) and (adrescode>=$40) then
      inc(adrescode,$40);
   if (inccod>=65408) or (inccod<128) and (adrescode>=$40) then
      inccod:=hex2dec(copy(com,work,work2-work)) and $ff;
end;

procedure incad(addresscode: byte; var incwaarde: word);
begin
   if addresscode=$06 then
      inc(incwaarde,2);
   if addresscode>=$40 then
      inc(incwaarde,1);
   if addresscode>=$80 then
      inc(incwaarde,1);
end;

procedure incofs;
var
   addresscode, usebyte: byte;
   incwaarde: word;
begin
   incwaarde:=0;
   if group=aam then
      incwaarde:=2;
   if group=add then
   begin
      if dsttype=registerbyte then
      begin
         if srctype=registerbyte then
            incwaarde:=2;
         if srctype=addressbyte then
         begin
            chkcode(src,addresscode,useword);
            incwaarde:=2;
            incad(addresscode,incwaarde);
         end;
         if srctype=constante then
         begin
            if (command<>'MOV') and (command<>'TEST') then
            begin
               if dst='AL' then
                  incwaarde:=2
               else
                  incwaarde:=3;
            end
            else
            begin
               if command='MOV' then
                  incwaarde:=2
               else
                  incwaarde:=3;
            end;
         end;
      end;
      if dsttype=registerword then
      begin
         if srctype=registerword then
            incwaarde:=2;
         if srctype=addressword then
         begin
            chkcode(src,addresscode,useword);
            incwaarde:=2;
            incad(addresscode,incwaarde);
         end;
         if srctype=constante then
         begin
            if (command<>'MOV') and (command<>'TEST') then
            begin
               if dst='AX' then
                  incwaarde:=3
               else
                  incwaarde:=4;
            end
            else
            begin
               if command='MOV' then
                  incwaarde:=3
               else
                  incwaarde:=4;
            end;
         end;
         if (srctype=segmentreg) and (command='MOV') then
            incwaarde:=2;
      end;
      if dsttype=addressbyte then
      begin
         if srctype=registerbyte then
         begin
            chkcode(dst,addresscode,useword);
            incwaarde:=2;
            incad(addresscode,incwaarde);
         end;
         if srctype=constante then
         begin
            chkcode(dst,addresscode,useword);
            incwaarde:=3;
            incad(addresscode,incwaarde);
         end;
      end;
      if dsttype=addressword then
      begin
         if srctype=registerword then
         begin
            chkcode(dst,addresscode,useword);
            incwaarde:=2;
            incad(addresscode,incwaarde);
         end;
         if srctype=constante then
         begin
            chkcode(dst,addresscode,useword);
            incwaarde:=4;
            incad(addresscode,incwaarde);
         end;
         if (srctype=segmentreg) and (command='MOV') then
         begin
            chkcode(dst,addresscode,useword);
            incwaarde:=2;
            incad(addresscode,incwaarde);
         end;
      end;
      if (dsttype=segmentreg) and (command='MOV') then
      begin
         if srctype=registerword then
            incwaarde:=2
         else
         begin
            chkcode(src,addresscode,useword);
            incwaarde:=2;
            incad(addresscode,incwaarde);
         end;
      end;
   end;
   if group=call then
   begin
      if (dsttype=addressword) or (dsttype=addressbyte) then
         incwaarde:=4
      else
         incwaarde:=3;
   end;
   if group=callf then
   begin
      if (dsttype=addressword) or (dsttype=addressbyte) then
         incwaarde:=4
      else
         incwaarde:=5;
   end;
   if group=es then
      incwaarde:=1;
   if group=int then
      incwaarde:=2;
   if group=ret then
   begin
      if dst<>'' then
         incwaarde:=3
      else
         incwaarde:=1;
   end;
   if group=jbe then
      incwaarde:=2;
   if group=labl then
   begin
      if command='DB' then
      begin
         work:=1;
         repeat
            if dst[work]='''' then
            begin
               repeat
                  inc(incwaarde);
                  inc(work);
               until (dst[work]='''') or (work>length(dst));
               if dst[work]<>'''' then
                  error('Illigal end of line');
               dec(incwaarde);
               inc(work);
            end
            else
            begin
               work2:=work;
               while (dst[work]<>' ') and (dst[work]<>',') and (work<=length(regel)) do
                  inc(work);
               if work2<>work then
                  inc(incwaarde);
               inc(work);
            end;
         until work>length(dst);
      end;
      if command='DBE' then
      begin
         assign(f,dst);
         {$i-}
         reset(f,1);
         {$i+}
         if ioresult<>0 then
            error(dst+' does not exist');
         incwaarde:=filesize(f);
         close(f);
      end;
      if command='DD' then
      begin
         work:=1;
         repeat
            if dst[work]='''' then
            begin
               repeat
                  inc(incwaarde,4);
                  inc(work);
               until (copy(dst,work,1)='''') or (work>length(dst));
               if dst[work]<>'''' then
                  error('Illigal end of line');
               dec(incwaarde,4);
               inc(work);
            end
            else
            begin
               work2:=work;
               while (dst[work]<>' ') and (dst[work]<>',') and (work<=length(regel)) do
                  inc(work);
               if work2<>work then
                  inc(incwaarde,4);
               inc(work);
            end;
         until work>length(dst);
      end;
      if command='DDE' then
      begin
         assign(f,dst);
         {$i-}
         reset(f,1);
         {$i+}
         if ioresult<>0 then
            error(dst+' does not exist');
         incwaarde:=filesize(f);
         close(f);
      end;
      if command='DW' then
      begin
         work:=1;
         repeat
            if dst[work]='''' then
            begin
               repeat
                  inc(incwaarde,2);
                  inc(work);
               until (copy(dst,work,1)='''') or (work>length(dst));
               if dst[work]<>'''' then
                  error('Illigal end of line');
               dec(incwaarde,2);
               inc(work);
            end
            else
            begin
               work2:=work;
               while (dst[work]<>' ') and (dst[work]<>',') and (work<=length(regel)) do
                  inc(work);
               if work2<>work then
                  inc(incwaarde,2);
               inc(work);
            end;
         until work>length(dst);
      end;
      if command='DWE' then
      begin
         assign(f,dst);
         {$i-}
         reset(f,1);
         {$i+}
         if ioresult<>0 then
            error(dst+' does not exist');
         incwaarde:=filesize(f);
         close(f);
      end;
      if command='DS' then
         incwaarde:=hex2dec(dst);
   end;
   if group=lds then
   begin
      chkcode(dst,addresscode,useword);
      incwaarde:=2;
      incad(addresscode,incwaarde);
   end;
   if group=nt then
   begin
      if (dsttype=registerbyte) or (dsttype=registerword) then
         incwaarde:=2;
      if (dsttype=addressbyte) or (dsttype=addressword) then
      begin
         chkcode(dst,addresscode,useword);
         incwaarde:=2;
         incad(addresscode,incwaarde);
      end;
   end;
   if group=i then
   begin
      if (dsttype=constante) or (srctype=constante) then
         incwaarde:=2
      else
         incwaarde:=1;
   end;
   if group=ic then
   begin
      if (dsttype=registerbyte) then
         incwaarde:=2;
      if (dsttype=registerword) then
         incwaarde:=1;
      if (dsttype=addressbyte) or (dsttype=addressword) then
      begin
         chkcode(dst,addresscode,useword);
         incwaarde:=2;
         incad(addresscode,incwaarde);
      end;
   end;
   if group=push then
   begin
      for work:=0 to 11 do
         if dst=addressregisters[work] then
            incwaarde:=1;
      if incwaarde=0 then
      begin
         if (copy(dst,1,1)='[') or (copy(dst,6,1)='[') then
            incwaarde:=4;
      end;
   end;
   if group=rol then
   begin
      if dsttype=registerbyte then
         incwaarde:=2;
      if dsttype=registerword then
         incwaarde:=2;
      if (dsttype=addressbyte) or (dsttype=addressword) then
      begin
         chkcode(dst,addresscode,useword);
         incwaarde:=2;
         incad(addresscode,incwaarde);
      end;
   end;
   if group=xchg then
   begin
      if (dsttype=registerbyte) or (dsttype=registerword) then
      begin
         if (srctype=registerbyte) or (srctype=registerword) then
            incwaarde:=2
         else
         begin
            chkcode(dst, addresscode, useword);
            incwaarde:=2;
            incad(addresscode, incwaarde);
         end;
      end;
   end;
   if (incwaarde=0) and (group<>nothing) then
      error('Illigal combination');
   inc(ofset,incwaarde);
end;

procedure change(var com: string);
type
   bw = (a,b,w,n);
var
   btwd: bw;
   cm: string;
   sstring: string;
   work1: byte;
   work2: byte;
begin
     if not firstlbl then
        begin
             current:=first;
             while (current<>nil) and (current^.name^<>com) and ('['+current^.name^+']'<>com) do
                   current:=current^.link;
             if current<>nil then
                begin
                     case current^.lbltype of
                          wrd: com:='WORD ['+hex(current^.address)+']';
                          bte: com:='BYTE ['+hex(current^.address)+']';
                     end;
                end;
             current:=first;
             while (current<>nil) and ('BYTE ['+current^.name^+']'<>com) and ('WORD ['+current^.name^+']'<>com) do
                current:=current^.link;
             if current<>nil then
             begin
                  if copy(com, 1, 6)='BYTE [' then
                     com:='BYTE ['+hex(current^.address)+']';
                  if copy(com, 1, 6)='WORD [' then
                     com:='WORD ['+hex(current^.address)+']';
             end;
        end;
     btwd:=n;
     if copy(com,1,6)='WORD [' then
        begin
             btwd:=w;
             com:=copy(com,7,length(com)-7);
        end;
     if copy(com,1,6)='BYTE [' then
        begin
             btwd:=b;
             com:=copy(com,7,length(com)-7);
        end;
     if copy(com,1,1)='[' then
        begin
             btwd:=a;
             com:=copy(com,2,length(com)-2);
        end;
     case btwd of
          b: com:='BYTE ['+com+']';
          w: com:='WORD ['+com+']';
          a: com:='['+com+']'
     end;
end;

procedure writefi(data: byte);
begin
   if (bt) and (ofset>=maxofs) and (infile) then
      error('Too many bytes for boot sector');
   if infile then
   begin
      if bt then
         boot[ofset]:=data
      else
         blockwrite(fi,data,1);
      if group<>labl then
      begin
         if prt then
            write(printer, dec2hex(data));
         if srcp then
            write(srcprinter, dec2hex(data));
         inc(wp);
      end;
   end;
   inc(nb);
   inc(ofset);
end;

procedure writewrd(data: word);
begin
   writefi(lo(data));
   writefi(hi(data));
end;

procedure localizeb(com: string; var regcode: byte);
begin
   regcode:=0;
   while (byteregisters[regcode]<>com) and (regcode<8) do
      inc(regcode);
   if regcode=8 then
      error('Unknown register');
end;

procedure localizew(com: string; var regcode: byte);
begin
   regcode:=0;
   while (wordregisters[regcode]<>com) and (regcode<8) do
      inc(regcode);
   if regcode=8 then
      error('Unknown register');
end;

procedure localizeseg(com: string; var regcode: byte);
begin
   regcode:=0;
   while segmentregisters[regcode]<>com do
      inc(regcode);
end;

procedure wrtad(addresscode: byte; com: string; useword: word);
begin
     if (copy(com, 1, 6)='WORD [') or (copy(com, 1, 6)='BYTE [') then
        com:=copy(com, 6, length(com)-5);
     if addresscode=$06 then
        writewrd(hex2dec(copy(com,2,length(com)-2)));
     if (addresscode>=$40) and (addresscode<$80) then
        writefi(useword);
     if (addresscode>=$80) then
        writewrd(useword);
end;

function paramexist(s, ts: string): boolean;
var
   work: byte;
begin
   paramexist:=false;
   for work:=1 to length(s)-length(ts)+1 do
      if upper(copy(s,work,length(ts)))=upper(ts) then
         paramexist:=true;
end;

procedure createcode;
var
   addresscode, rb, rd, usebyte: byte;
   ofst, work: word;
   handy: integer;
begin
     ofst:=ofset;
     if group=aam then
        begin
             if command='AAM' then
                writewrd($0ad4)
             else
                 writewrd($0ad5);
        end;
     if group=add then
        begin
             work:=0;
             while command<>addgroup[work] do
                   inc(work);
             if dsttype=registerbyte then
                begin
{1}                  if srctype=registerbyte then
                        begin
                             writefi(addbase[work]);
                             localizeb(src,rb);
                             localizeb(dst,rd);
                             writefi(rb*8+rd+$c0);
                        end;
{2}                  if srctype=addressbyte then
                        begin
                             if copy(src,1,5)='BYTE ' then
                                src:=copy(src,6,length(src)-5);
                             writefi(addbase[work]+2);
                             localizeb(dst,rd);
                             chkcode(src,addresscode,useword);
                             writefi(rd*8+addresscode);
                             wrtad(addresscode,src,useword);
                        end;
{3}                  if srctype=constante then
                        begin
                             if (command<>'MOV') and (command<>'TEST') then
                                begin
                                     if dst<>'AL' then
                                        begin
                                             writefi($80);
                                             localizeb(dst,rd);
                                             writefi(addbase[work]+$c0+rd);
                                             writefi(hex2dec(src));
                                        end
                                     else
                                         begin
                                              writefi(addbase[work]+4);
                                              writefi(hex2dec(src));
                                         end;
                                end
                             else
                                 begin
                                      if command='MOV' then
                                         begin
                                              localizeb(dst,rd);
                                              writefi($b0+rd);
                                              writefi(hex2dec(src));
                                         end
                                      else
                                          begin
                                               writefi($f6);
                                               localizeb(dst,rd);
                                               writefi($c0+rd);
                                               writefi(hex2dec(src));
                                          end;
                                 end;
                        end;
                end;
             if dsttype=registerword then
                begin
{1}                  if srctype=registerword then
                        begin
                             writefi(addbase[work]+1);
                             localizew(src,rb);
                             localizew(dst,rd);
                             writefi(rb*8+rd+$c0);
                        end;
{2}                  if srctype=addressword then
                        begin
                             writefi(addbase[work]+3);
                             localizew(dst,rd);
                             chkcode(src,addresscode,useword);
                             writefi(rd*8+addresscode);
                             if copy(src,1,5)=('WORD ') then
                                src:=copy(src,6,length(src)-5);
                             wrtad(addresscode,src,useword);
                        end;
{3}                  if srctype=constante then
                        begin
                             if (command<>'MOV') and (command<>'TEST') then
                                begin
                                     if dst<>'AX' then
                                        begin
                                             writefi($81);
                                             localizew(dst,rd);
                                             writefi(addbase[work]+$c0+rd);
                                             writewrd(hex2dec(src));
                                        end
                                     else
                                         begin
                                              writefi(addbase[work]+5);
                                              writewrd(hex2dec(src));
                                         end;
                                end
                             else
                                 begin
                                      if command='MOV' then
                                         begin
                                              localizew(dst,rd);
                                              writefi($b8+rd);
                                              writewrd(hex2dec(src));
                                         end
                                      else
                                          begin
                                               writefi($f7);
                                               localizew(dst,rd);
                                               writefi($c0+rd);
                                               writewrd(hex2dec(src));
                                          end;
                                 end;
                        end;
                     if (srctype=segmentreg) and (command='MOV') then
                        begin
                             writefi($8c);
                             localizeseg(src,rb);
                             localizew(dst,rd);
                             writefi($c0+rb*8+rd);
                        end;
                end;
             if dsttype=addressbyte then
                begin
                     if copy(dst,1,5)='BYTE ' then
                        dst:=copy(dst,6,length(dst)-5);
{4}                  if srctype=registerbyte then
                        begin
                             writefi(addbase[work]);
                             localizeb(src,rb);
                             chkcode(dst,addresscode,useword);
                             writefi(rb*8+addresscode);
                             wrtad(addresscode,dst,useword);
                        end;
{5}                  if srctype=constante then
                        begin
                             if (command<>'MOV') and (command<>'TEST') then
                                begin
                                     writefi($80);
                                     chkcode(dst,addresscode,useword);
                                     writefi(addbase[work]+addresscode);
                                     wrtad(addresscode,dst,useword);
                                     writefi(hex2dec(src));
                                end
                             else
                                 begin
                                      if command='MOV' then
                                         writefi($c6)
                                      else
                                          writefi($f6);
                                      chkcode(dst,addresscode,useword);
                                      writefi(addresscode);
                                      wrtad(addresscode,dst,useword);
                                      writefi(hex2dec(src));
                                 end;
                        end;
                end;
             if dsttype=addressword then
                begin
                     if copy(dst,1,5)='WORD ' then
                        dst:=copy(dst,6,length(dst)-5);
{4}                  if srctype=registerword then
                        begin
                             writefi(addbase[work]+1);
                             localizew(src,rb);
                             chkcode(dst,addresscode,useword);
                             writefi(rb*8+addresscode);
                             wrtad(addresscode,dst,useword);
                        end;
{5}                  if srctype=constante then
                        begin
                             if (command<>'MOV') and (command<>'TEST') then
                                begin
                                     writefi($81);
                                     chkcode(dst,addresscode,useword);
                                     writefi(addbase[work]+addresscode);
                                     wrtad(addresscode,dst,useword);
                                     writewrd(hex2dec(src));
                                end
                             else
                                 begin
                                      if command='MOV' then
                                         writefi($c7)
                                      else
                                          writefi($f7);
                                      chkcode(dst,addresscode,useword);
                                      writefi(addresscode);
                                      wrtad(addresscode,dst,useword);
                                      writewrd(hex2dec(src));
                                 end;
                        end;
                     if (srctype=segmentreg) and (command='MOV') then
                        begin
                             writefi($8c);
                             localizeseg(src,rb);
                             chkcode(dst,addresscode,useword);
                             writefi(rb*8+addresscode);
                             wrtad(addresscode,dst,useword);
                        end;
                end;
             if (dsttype=segmentreg) and (command='MOV') then
                begin
                     writefi($8e);
                     localizeseg(dst,rd);
                     if srctype=registerword then
                     begin
                        localizew(src,rb);
                        writefi($c0+rb+rd*8);
                     end
                     else
                        if srctype=addressword then
                        begin
                           chkcode(src,addresscode,useword);
                           writefi(rd*8+addresscode);
                           wrtad(addresscode,src,useword);
                        end
                        else
                           error('Illigal combination');
                end;
        end;
     if group=call then
        begin
             current:=first;
             repeat
                   if current^.name^=dst then
                      begin
                           if current^.lbltype=lbl then
                              dst:=hex(current^.address)
                           else
                               dst:='['+hex(current^.address)+']';
                      end;
                   current:=current^.link;
             until current=nil;
             if (dsttype<>addressbyte) and (dsttype<>addressword) then
             begin
                  if command='CALL' then
                     writefi($e8)
                  else
                      writefi($e9);
                  writewrd(hex2dec(dst)-ofset-2);
             end
             else
             begin
                  if command='CALL' then
                     writewrd($16ff)
                  else
                      writewrd($26ff);
                  if (copy(dst,1,5)='WORD ') or (copy(dst,1,5)='BYTE ') then
                     dst:=copy(dst,6,length(dst)-5);
                  writewrd(hex2dec(copy(dst,2,length(dst)-2)));
             end;
        end;
     if group=callf then
        begin
             current:=first;
             repeat
                   if current^.name^=dst then
                      begin
                           if current^.lbltype=lbl then
                              dst:=hex(current^.address)
                           else
                               dst:='['+hex(current^.address)+']';
                      end;
                   current:=current^.link;
             until current=nil;
             if (dsttype<>addressbyte) and (dsttype<>addressword) then
                begin
                     if command='CALLF' then
                        writefi($9a)
                     else
                         writefi($ea);
                     work:=1;
                     repeat
                           inc(work);
                     until dst[work]=':';
                     writewrd(hex2dec(copy(dst,work+1,length(dst)-work)));
                     writewrd(hex2dec(copy(dst,1,work-1)));
                end
             else
                 begin
                      if command='CALLF' then
                         writewrd($1eff)
                      else
                          writewrd($2eff);
                      if (copy(dst,1,5)='WORD ') or (copy(dst,1,5)='BYTE ') then
                         dst:=copy(dst,6,length(dst)-5);
                      writewrd(hex2dec(copy(dst,2,length(dst)-2)));
                 end;
        end;
     if group=es then
        begin
             for work:=0 to 40 do
                 if command=esgroup[work] then
                    writefi(esbase[work]);
        end;
     if group=i then
        begin
             if command='IN' then
                begin
                     if (dst<>'AL') and (dst<>'AX') then
                        error('Illigal combination');
                     if (dst='AL') and (src='DX') then
                        writefi($ec);
                     if (dst='AX') and (src='DX') then
                        writefi($ed);
                     if (dst='AL') and (srctype=constante) then
                     begin
                        writefi($e4);
                        writefi(hex2dec(src));
                     end;
                     if (dst='AX') and (srctype=constante) then
                     begin
                          writefi($e5);
                          writefi(hex2dec(src));
                     end;
                end
             else
                 begin
                      if (src<>'AL') and (src<>'AX') then
                         error('Illigal combination');
                      if (dst='DX') and (src=('AL')) then
                         writefi($ee);
                      if (dst='DX') and (src='AX') then
                         writefi($ef);
                      if (dsttype=constante) and (src=('AL')) then
                         begin
                              writefi($e6);
                              writefi(hex2dec(dst));
                         end;
                      if (dsttype=constante) and (src=('AX')) then
                         begin
                              writefi($e7);
                              writefi(hex2dec(dst));
                         end;
                 end;
        end;
     if group=labl then
        begin
             if command='DB' then
                begin
                     work:=1;
                     repeat
                           if (dst[work]='''')  then
                              begin
                                   inc(work);
                                   repeat
                                         writefi(ord(dst[work]));
                                         inc(work);
                                   until (dst[work]='''') or (work>length(dst));
                                   if copy(dst,work,1)<>'''' then
                                      error('Illigal end of line');
                                   inc(work);
                              end
                           else
                               begin
                                    work2:=work;
                                    while (dst[work]<>' ') and (dst[work]<>',') and (work<=length(regel)) do
                                          inc(work);
                                    if work2<>work then
                                       begin
                                            if copy(dst,work2,work-work2)='?' then
                                               writefi(0)
                                            else
                                                writefi(hex2dec(copy(dst,work2,work-work2)));
                                       end;
                                    inc(work);
                               end;
                     until work>length(dst);
                end;
             if command='DBE' then
                begin
                     assign(f,dst);
                     reset(f,1);
                     repeat
                           blockread(f,usebyte,1);
                           writefi(usebyte);
                     until eof(f);
                     close(f);
                end;
             if command='DD' then
                begin
                     work:=1;
                     repeat
                           if copy(dst,work,1)='''' then
                              begin
                                   inc(work);
                                   repeat
                                         writewrd(ord(dst[work]));
                                         writewrd(0);
                                         inc(work);
                                   until (copy(dst,work,1)='''') or (work>length(dst));
                                   if copy(dst,work,1)<>'''' then
                                      error('Illigal end of line');
                                   inc(work);
                              end
                           else
                               begin
                                    work2:=work;
                                    while (dst[work]<>' ') and (dst[work]<>',') and (work<=length(regel)) do
                                          inc(work);
                                    if work2<>work then
                                       begin
                                            if copy(dst,work2,work-work2)='?' then
                                            begin
                                               writewrd(0);
                                               writewrd(0);
                                            end
                                            else
                                            begin
                                                writewrd((hex2dec(copy(dst,work2,work-work2))) and $0000ffff);
                                                writewrd(((hex2dec(copy(dst,work2,work-work2))) and $ffff0000) shr 16);
                                            end;
                                       end;
                                    inc(work);
                               end;
                     until work>length(dst);
                end;
             if command='DDE' then
                begin
                     assign(f,dst);
                     reset(f,1);
                     repeat
                           blockread(f,usebyte,1);
                           writefi(usebyte);
                     until eof(f);
                     close(f);
                end;
             if command='DW' then
                begin
                     work:=1;
                     repeat
                           if copy(dst,work,1)='''' then
                              begin
                                   inc(work);
                                   repeat
                                         writewrd(ord(dst[work]));
                                         inc(work);
                                   until (copy(dst,work,1)='''') or (work>length(dst));
                                   if copy(dst,work,1)<>'''' then
                                      error('Illigal end of line');
                                   inc(work);
                              end
                           else
                               begin
                                    work2:=work;
                                    while (dst[work]<>' ') and (dst[work]<>',') and (work<=length(regel)) do
                                          inc(work);
                                    if work2<>work then
                                       begin
                                            if copy(dst,work2,work-work2)='?' then
                                               writewrd(0)
                                            else
                                                writewrd(hex2dec(copy(dst,work2,work-work2)));
                                       end;
                                    inc(work);
                               end;
                     until work>length(dst);
                end;
             if command='DWE' then
                begin
                     assign(f,dst);
                     reset(f,1);
                     repeat
                           blockread(f,usebyte,1);
                           writefi(usebyte);
                     until eof(f);
                     close(f);
                end;

             if command='DS' then
                begin
                     for work:=1 to hex2dec(dst) do
                         writefi(0);
                end;
        end;
     if group=lds then
        begin
             if dsttype<>registerword then
                error('Destination should be a registerword');
             writefi($c5);
             localizew(dst,rd);
             chkcode(src,addresscode,useword);
             writefi(rd*8+addresscode);
             wrtad(addresscode,src,useword);
        end;
     if group=nt then
        begin
             work:=65535;
             repeat
                   inc(work);
             until command=notgroup[work];
             if dsttype=registerbyte then
                begin
                     writefi($f6);
                     localizeb(dst,rd);
                     writefi(notbase[work]+$c0+rd);
                end;
             if dsttype=registerword then
                begin
                     writefi($f7);
                     localizew(dst,rd);
                     writefi(notbase[work]+$c0+rd);
                end;
             if dsttype=addressbyte then
                begin
                     dst:=copy(dst,6,length(dst)-5);
                     writefi($f6);
                     chkcode(dst,addresscode,useword);
                     writefi(notbase[work]+addresscode);
                     wrtad(addresscode,dst,useword);
                end;
             if dsttype=addressword then
                begin
                     dst:=copy(dst,6,length(dst)-5);
                     writefi($f7);
                     chkcode(dst,addresscode,useword);
                     writefi(notbase[work]+addresscode);
                     wrtad(addresscode,dst,useword);
                end;
        end;
     if group=ic then
        begin
             work:=65535;
             if dsttype=registerbyte then
                begin
                     writefi($fe);
                     localizeb(dst,rd);
                     if command='INC' then
                        writefi($c0+rd)
                     else
                         writefi($c8+rd);
                end;
             if dsttype=registerword then
                begin
                     localizew(dst,rd);
                     if command='INC' then
                        writefi($40+rd)
                     else
                         writefi($48+rd);
                end;
             if dsttype=addressbyte then
                begin
                     dst:=copy(dst,6,length(dst)-5);
                     writefi($fe);
                     chkcode(dst,addresscode,useword);
                     if command='INC' then
                        writefi(addresscode)
                     else
                         writefi(addresscode+8);
                     wrtad(addresscode,dst,useword);
                end;
             if dsttype=addressword then
                begin
                     dst:=copy(dst,6,length(dst)-5);
                     writefi($ff);
                     chkcode(dst,addresscode,useword);
                     if command='INC' then
                        writefi(addresscode)
                     else
                         writefi(addresscode+8);
                     wrtad(addresscode,dst,useword);
                end;
        end;
     if group=push then
        begin
             if (dsttype=registerbyte) then
                error('Cannot push registerbytes');
             change(dst);
             if copy(dst,1,5)='BYTE ' then
                dst:=copy(dst,6,length(dst)-5);
             if copy(dst,1,5)='WORD ' then
                dst:=copy(dst,6,length(dst)-5);
             if copy(dst,1,1)='[' then
                dst:=copy(dst,2,length(dst)-2);
             for work:=0 to 11 do
                 if dst=addressregisters[work] then
                    begin
                         if command='PUSH' then
                            begin
                                 if work<8 then
                                    writefi($50+work)
                                 else
                                     case work of
                                          8: writefi($06);
                                          9: writefi($0e);
                                          10: writefi($16);
                                          11: writefi($1e);
                                     end;
                            end
                         else
                             begin
                                  if work<8 then
                                     writefi($58+work)
                                  else
                                      case work of
                                           8: writefi($07);
                                           9: writefi($0f);
                                           10: writefi($17);
                                           11: writefi($1f);
                                      end;
                             end;
                    end;
             if ofst=ofset then
                begin
                     if command='PUSH' then
                       begin
                            writefi($ff);
                            chkcode(dst,addresscode,useword);
                            writefi($30+addresscode);
                            wrtad(addresscode,dst,useword);
                        end
                     else
                         begin
                              writefi($8f);
                              chkcode(dst,addresscode,useword);
                              writefi($30+addresscode);
                              wrtad(addresscode,dst,useword);
                         end;
                end;
        end;
     if group=ret then
          begin
               if dst='' then
                 writefi($c3)
             else
                 begin
                      writefi($c2);
                      writewrd(hex2dec(dst));
                 end;
        end;
     if group=int then
        begin
             writefi($cd);
             writefi(hex2dec(dst));
        end;
     if group=jbe then
        begin
             current:=first;
             repeat
                   if current^.name^=dst then
                      begin
                           if current^.lbltype=lbl then
                              dst:=hex(current^.address)
                           else
                               error('Wrong usage of label');
                      end;
                   current:=current^.link;
             until current=nil;
             for work:=0 to 37 do
                 if command=jbegroup[work] then
                    writefi(jbebase[work]);
             handy:=hex2dec(dst)-(ofset+1);
             if (handy<-128) or (handy>127) then
                 error('JUMP to far');
             writefi(hex2dec(dst)-(ofset+1));
        end;
     if group=rol then
        begin
             work:=65535;
             repeat
                   inc(work);
             until rolgroup[work]=command;
             if dsttype=registerbyte then
                begin
                     if srctype=constante then
                        begin
                             if hex2dec(src)<>1 then
                                error('Source should be one');
                             writefi($d0);
                        end
                     else
                         writefi($d2);
                     localizeb(dst,rd);
                     writefi(rolbase[work]+$c0+rd);
                end;
             if dsttype=registerword then
                begin
                     if srctype=constante then
                        begin
                             if hex2dec(src)<>1 then
                                error('Source should be one');
                             writefi($d1);
                        end
                     else
                         writefi($d3);
                     localizew(dst,rd);
                     writefi(rolbase[work]+$c0+rd);
                end;
             if (dsttype=addressbyte) or (dsttype=addressword) then
                begin
                     if dsttype=addressbyte then
                        begin
                             if srctype=constante then
                                begin
                                     if hex2dec(src)<>1 then
                                        error('Source should be one');
                                     writefi($d0);
                                end
                             else
                                 writefi($d2);
                        end
                     else
                         begin
                              if srctype=constante then
                                 begin
                                      if hex2dec(src)<>1 then
                                         error('Source should be one');
                                      writefi($d1);
                                 end
                              else
                                  writefi($d3);
                         end;
                     chkcode(dst,addresscode,useword);
                     writefi(rolbase[work]+addresscode);
                     if copy(dst,1,5)='BYTE ' then
                         dst:=copy(dst,6,length(dst)-5);
                     if copy(dst,1,5)='WORD ' then
                        dst:=copy(dst,6,length(dst)-5);
                     wrtad(addresscode,dst,useword);
                end;
        end;
   if group=xchg then
   begin
      if dsttype=registerword then
      begin
         localizew(dst, rd);
         writefi($87)
      end
      else
      begin
         localizeb(dst, rd);
         writefi($86);
      end;
      case srctype of
         registerword:
         begin
            localizew(src, rb);
            writefi(rd*8+rb+$c0);
         end;
         registerbyte:
         begin
            localizeb(src, rb);
            writefi(rd*8+rb+$c0);
         end;
         addressword, addressbyte:
         begin
            if copy(src,1,5)='BYTE ' then
               src:=copy(src,6,length(src)-5);
            chkcode(src,addresscode,useword);
            writefi(rd*8+addresscode);
            wrtad(addresscode,src,useword);
         end;
      end;
      {rb, rd}
   end;
   if not ofst=ofset then
      error('Can''t create code');
end;

begin
   writeln('Magic Assembler v1.15');
   writeln('BSD-3-Clause licenced version');
   writeln('Copyright 1994-2021 Bert Greevenbosch');
   writeln('All rights reserved');
   writeln;
   
   base:=$100;
   prtnum:=false;
   firstlbl:=true;
   
   if (paramcount=0) or (paramcount>2) then
   begin  
      writeln('Syntax: ASM [FILENAME.ASM] [B:A/B][I][N][P][S]');
      writeln;
      writeln('B: place program into boot sector on drive A: or B:');
      writeln('I: uses incompatible mode for boot sector programs');
      writeln('N: use normal numbers');
      writeln('P: print source with addresses');
      writeln('S: create source with addresses (FILENAME.SRC)');
      writeln;
      writeln('For licensing information:');
      writeln('ASM --license');      
      halt(1);
   end;
   
   if upper(paramstr(1)) = '--LICENSE' then
   begin
      writeln('Redistribution and use in source and binary forms, with or without');
      writeln('modification, are permitted provided that the following conditions are met:');
      writeln;
      writeln('1. Redistributions of source code must retain the above copyright notice, this');
      writeln('list of conditions and the following disclaimer.');
      writeln('2. Redistributions in binary form must reproduce the above copyright notice,');
      writeln('this list of conditions and the following disclaimer in the documentation');
      writeln('and/or other materials provided with the distribution.');
      writeln('3. Neither the name of the copyright holder nor the names of its contributors');
      writeln('may be used to endorse or promote products derived from this software without');
      writeln('specific prior written permission.');
      writeln;
      writeln('THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"');
      writeln('AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE');
      writeln('IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE');
      writeln('DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE');
      writeln('FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL');
      writeln('DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR');
      writeln('SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER');
      writeln('CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,');
      writeln('OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE');
      writeln('OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.');
      halt(0);
   end;
   
   writeln('For licensing information:');
   writeln('ASM --license');
   writeln;

   prt:=paramexist(paramstr(2), 'P');
   srcp:=paramexist(paramstr(2), 'S');
   bt:=false;
   if paramexist(paramstr(2),'B:A') or paramexist(paramstr(2),'B:B') then
   begin
      s:=seg(boot);
      o:=ofs(boot);
      if paramexist(paramstr(2),'B:A') then
         dr:=0
      else
         dr:=1;
      asm
         mov cx,$0004
      @1:push cx
         mov ax,$0201
         mov cx,$0001
         mov dh,$00
         mov dl,dr
         mov es,s
         mov bx,o
         int $13
         jnc @2
         pop cx
         loop @1
         mov ok,0
         jmp @3
      @2:pop cx
         mov ok,1
      @3:
      end;
      if ok=0 then
         error('Cannot read boot sector');
      if not paramexist(paramstr(2), 'I') then
      begin
         base:=boot[1]+2;
         maxofs:=510;
      end
      else
      begin
         base:=0;
         maxofs:=512;
      end;
      bt:=true;
   end
   else
      if paramexist(paramstr(2), 'I') then
         error('Cannot use incompatibily mode without boot sector assembling');
   nnum:=paramexist(paramstr(2),'N');
   name:=paramstr(1);
   assign(prog,name);
   {$i-}
   reset(prog);
   {$i+}
   if ioresult<>0 then
   begin
      name:=name+'.ASM';
      assign(prog,name);
      {$i-}
      reset(prog);
      {$i+}
      if ioresult<>0 then
         error('File not found');
   end;
   prtnum:=true;
   write('Searching for labels: ');
   no:=0;
   equdone:=false;
   labeldone:=false;
   repeat
      inc(no);
      gotoxy(23,wherey);
      write(no);
      uncode;
      if lbel<>'' then
      begin
         if firstlbl then
         begin
            new(first);
            if first=nil then
               error('Out of memory');
            current:=first;
            current^.link:=nil;
            firstlbl:=false;
         end
         else
         begin
            current:=first;
            while current<>nil do
            begin
               if current^.name^=lbel then
                  error('Duplicate label');
               next:=current;
               current:=current^.link;
            end;
            current:=next;
            new(next);
            if next=nil then
               error('Out of memory');
            current^.link:=next;
            current:=next;
            current^.link:=nil;
         end;
         getmem(current^.name, length(lbel)+1);
         if current^.name=nil then
            error('Out of memory');
         current^.name^:=lbel;
         current^.lbltype:=lbl;
         if copy(command,1,2)='DB' then
            current^.lbltype:=bte;
         if copy(command,1,2)='DW' then
            current^.lbltype:=wrd;
         if command='DS' then
            current^.lbltype:=bte;
         if command='EQU' then
         begin
            current^.lbltype:=equ;
            getmem(current^.equal, length(dst)+1);
            if current^.equal=nil then
               error('Out of memory');
            current^.equal^:=dst;
         end;
      end;
   until eof(prog);
   close(prog);
   equdone:=true;
   reset(prog);
   writeln;
   write('Locating labels: ');
   no:=0;
   ofset:=base;
   repeat
      inc(no);
      gotoxy(18,wherey);
      write(no);
      uncode;
      if lbel<>'' then
      begin
         current:=first;
         while current^.name^<>lbel do
            current:=current^.link;
         if current^.lbltype<>equ then
            current^.address:=ofset;
      end;
      lbld:=true;
      if not firstlbl then
      begin
         current:=first;
         repeat
            chk(src);
            chk(dst);
            current:=current^.link;
         until current=nil;
      end;
      srctype:=constante;
      dsttype:=constante;
      gettype(src,srctype);
      gettype(dst,dsttype);
      extragettype;
      incofs;
   until eof(prog);
   close(prog);
   labeldone:=true;
   writeln;
   write('Assembling: ');
   no:=0;
   name:=deext(name);
   if not bt then
   begin
      assign(fi,name+'.COM');
      rewrite(fi,1);
   end;
   reset(prog);
   ofset:=base;
   infile:=true;
   if prt then
   begin
      assign(printer,'prn');
      rewrite(printer);
   end;
   if srcp then
   begin
      assign(srcprinter, name+'.SRC');
      rewrite(srcprinter);
   end;
   datas:=0;
   codes:=0;
   skipped:=0;
   repeat
      nb:=0;
      inc(no);
      gotoxy(13,wherey);
      write(no);
      uncode;
      if (command='EQU') or (command='') then
      begin
         if prt then
            write(printer,'     ');
         if srcp then
            write(srcprinter,'     ');
      end
      else
      begin
         if prt then
            write(printer,hex(ofset),' ');
         if srcp then
            write(srcprinter,hex(ofset),' ');
      end;
      change(src);
      change(dst);
      srctype:=constante;
      dsttype:=constante;
      gettype(src,srctype);
      gettype(dst,dsttype);
      extragettype;
      if group=push then
         change(dst);
      wp:=0;
      createcode;
      if (prt) or (srcp) then
      begin
         for work:=wp to 6 do
         begin
            if prt then
               write(printer, '  ');
            if srcp then
               write(srcprinter, '  ');
         end;
         if prt then
            writeln(printer, line);
         if srcp then
            writeln(srcprinter, line);
      end;
      if group=labl then
         inc(datas, nb)
      else
         inc(codes, nb);
      if not infile then
         inc(skipped, nb);
   until eof(prog);
   close(prog);
   if prt then
      close(printer);
   if srcp then
      close(srcprinter);
   if not bt then
      close(fi)
   else
   begin
      boot[510]:=$55;
      boot[511]:=$aa;
      asm
         mov cx,$0004
      @1:push cx
         mov ax,$0301
         mov cx,$0001
         mov dh,$00
         mov dl,dr
         mov es,s
         mov bx,o
         int $13
         jnc @2
         pop cx
         loop @1
         mov ok,0
         jmp @3
      @2:pop cx
         mov ok,1
      @3:
      end;
      if ok=0 then
         error('Cannot write boot sector');
   end;
   writeln;
   writeln;
   write('--------------------------------------------------------------------------------');
   writeln(codes+datas-skipped, ' bytes in file');
   writeln(codes, ' bytes code');
   writeln(datas, ' bytes data');
   writeln(skipped, ' bytes excluded from writing');
   write('--------------------------------------------------------------------------------');
end.
